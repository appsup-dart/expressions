
library expressions.parser;

import 'expressions.dart';
import 'package:typedparser/typedparser.dart';

class ExpressionParser {

  ExpressionParser() {
    expression.set(binaryExpression
        .seq(conditionArguments.optional(), (a,b)=>b==null ? a : new ConditionalExpression(a, b[0], b[1])));
    token.set(literal.cast<Expression>()|unaryExpression|variable);
  }

  // Gobbles only identifiers
  // e.g.: `foo`, `_value`, `$x1`
  Parser<Identifier> get identifier =>
      (word()|char(r"$")).plus().precededBy(digit().not()).flatten()
          .map((v)=>new Identifier(v));

  // Parse simple numeric literals: `12`, `3.4`, `.5`.
  Parser<Literal> get numericLiteral =>
      ((digit()|char(".")).and()&(digit().star()&(
          (char(".")&digit().plus())|
          (char("x")&digit().plus())|
          (anyOf("Ee")&anyOf("+-").optional()&digit().plus())
      ).optional()))
          .mapParser((v) {
        try {
          return epsilon(new Literal(num.parse(v), v));
        } on FormatException {
          return failure();
        }
      });

  Parser<String> get escapedChar => anyOf("nrtbfv\"'").precededBy(char(r"\"));

  String unescape(String v) => v.replaceAllMapped(new RegExp("\\\\[nrtbf\"']"),
          (v)=>const {"n":"\n","r":"\r","t":"\t","b":"\b","f":"\f","v":"\v",
        '"': '"', "'": "'"}[v.group(0).substring(1)]);

  Parser<Literal> get sqStringLiteral =>
      (anyOf(r"'\").neg()|escapedChar).star().flatten().surroundedBy(char("'"))
          .map((v)=>new Literal(unescape(v), "'$v'"));
  Parser<Literal> get dqStringLiteral =>
      (anyOf(r'"\').neg()|escapedChar).star().flatten().surroundedBy(char('"'))
          .map((v)=>new Literal(unescape(v), '"$v"'));

  // Parses a string literal, staring with single or double quotes with basic
  // support for escape codes e.g. `"hello world"`, `'this is\nJSEP'`
  Parser<Literal> get stringLiteral => sqStringLiteral.or(dqStringLiteral);

  // Parses a boolean literal
  Parser<Literal> get boolLiteral => (string("true")|string("false"))
      .map((v)=>new Literal(v=="true", v));

  // Parses the null literal
  Parser<Literal> get nullLiteral => string("null").map((v)=>new Literal(null, v));

  // Parses the this literal
  Parser<ThisExpression> get thisExpression => string("this").map((v)=>new ThisExpression());


  // Responsible for parsing Array literals `[1, 2, 3]`
  // This function assumes that it needs to gobble the opening bracket
  // and then tries to gobble the expressions as arguments.
  Parser<Literal> get arrayLiteral =>
      arguments.surroundedBy(char("[").trim(),char("]").trim())
          .map((l)=>new Literal(l, "$l"));

  Parser<Literal> get literal => numericLiteral|stringLiteral|boolLiteral|nullLiteral|arrayLiteral;

  // An individual part of a binary expression:
  // e.g. `foo.bar(baz)`, `1`, `"abc"`, `(a % 2)` (because it's in parenthesis)
  final SettableParser<Expression> token = undefined<Expression>();

  // Also use a map for the binary operations but set their values to their
  // binary precedence for quick reference:
  // see [Order of operations](http://en.wikipedia.org/wiki/Order_of_operations#Programming_language)
  static const Map<String,int> binaryOperations = const {
    '||': 1, '&&': 2, '|': 3,  '^': 4,  '&': 5,
    '==': 6, '!=': 6,
    '<=': 7,  '>=': 7, '<': 7,  '>': 7,
    '<<':8,  '>>': 8,
    '+': 9, '-': 9,
    '*': 10, '/': 10, '%': 10
  };


  // This function is responsible for gobbling an individual expression,
  // e.g. `1`, `1+2`, `a+(b*2)-Math.sqrt(2)`
  Parser<String> get binaryOperation => binaryOperations.keys
      .map<Parser<String>>((v)=>string(v)).reduce((a,b)=>a|b).trim();

  Parser<Expression> get binaryExpression =>
      token.seq(binaryOperation.seq(token, (a,b)=>[a,b]).star(), (first,extras) {
        var stack = <dynamic>[first];
        for (var v in extras) {
          var op = v[0];
          var prec = BinaryExpression.precedenceForOperator(op);

          // Reduce: make a binary expression from the three topmost entries.
          while ((stack.length > 2) &&
              (prec <= BinaryExpression.precedenceForOperator(stack[stack.length - 2]))) {
            var right = stack.removeLast();
            var op = stack.removeLast();
            var left = stack.removeLast();
            var node = new BinaryExpression(op, left, right);
            stack.add(node);
          }

          var node = v[1];
          stack.addAll([op, node]);
        }

        var i = stack.length - 1;
        var node = stack[i];
        while(i > 1) {
          node = new BinaryExpression(stack[i - 1], stack[i - 2], node);
          i -= 2;
        }
        return node;
      });

  // Use a quickly-accessible map to store all of the unary operators
  // Values are set to `true` (it really doesn't matter)
  static const _unaryOperations = const ['-', '!', '~', '+'];

  Parser<UnaryExpression> get unaryExpression =>
      enumIndex(_unaryOperations)
          .map((i)=>_unaryOperations[i]).trim()
          .seq(token, (a,b)=>new UnaryExpression(a,b));

  // Gobbles a list of arguments within the context of a function call
  // or array literal. This function also assumes that the opening character
  // `(` or `[` has already been gobbled, and gobbles expressions and commas
  // until the terminator character `)` or `]` is encountered.
  // e.g. `foo(bar, baz)`, `my_func()`, or `[bar, baz]`
  Parser<List<Expression>> get arguments =>
      expression.separatedBy(char(",").trim());

  // Gobble a non-literal variable name. This variable name may include properties
  // e.g. `foo`, `bar.baz`, `foo['bar'].baz`
  // It also gobbles function calls:
  // e.g. `Math.acos(obj.angle)`
  Parser<Expression> get variable => groupOrIdentifier.seq(
      (memberArgument.cast()|indexArgument|callArgument).star(),
          (a,List b) {
        return b.fold(a, (Expression object, argument) {
          if (argument is Identifier) return new MemberExpression(object, argument);
          if (argument is Expression) return new IndexExpression(object, argument);
          if (argument is List<Expression>) return new CallExpression(object, argument);
          throw new ArgumentError("Invalid type ${argument.runtimeType}");
        });
      }
  );

  // Responsible for parsing a group of things within parentheses `()`
  // This function assumes that it needs to gobble the opening parenthesis
  // and then tries to gobble everything within that parenthesis, assuming
  // that the next thing it should see is the close parenthesis. If not,
  // then the expression probably doesn't have a `)`
  Parser<Expression> get group => expression.trim().surroundedBy(char("("),char(")"));

  Parser<Expression> get groupOrIdentifier => group|thisExpression|identifier.map((v)=>new Variable(v));

  Parser<Identifier> get memberArgument => identifier.precededBy(char("."));
  Parser<Expression> get indexArgument => expression.trim().surroundedBy(char("["),char("]"));
  Parser<List<Expression>> get callArgument => arguments.surroundedBy(char("("),char(")"));

  // Ternary expression: test ? consequent : alternate
  Parser<List<Expression>> get conditionArguments =>
      expression.surroundedBy(char("?").trim(), char(":").trim())
          .seq(expression, (a,b)=>[a,b]);

  final SettableParser<Expression> expression = undefined();



}
