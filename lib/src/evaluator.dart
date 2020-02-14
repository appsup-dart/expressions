library expressions.evaluator;

import 'expressions.dart';

class ExpressionEvaluator {
  const ExpressionEvaluator();

  dynamic eval(Expression expression, Map<String, dynamic> context) {
    if (expression == null) throw new ArgumentError.notNull('expression');
    if (expression is Literal) return evalLiteral(expression, context);
    if (expression is Variable) return evalVariable(expression, context);
    if (expression is ThisExpression) return evalThis(expression, context);
    if (expression is MemberExpression) {
      return evalMemberExpression(expression, context);
    }
    if (expression is IndexExpression) {
      return evalIndexExpression(expression, context);
    }
    if (expression is CallExpression) {
      return evalCallExpression(expression, context);
    }
    if (expression is UnaryExpression) {
      return evalUnaryExpression(expression, context);
    }
    if (expression is BinaryExpression) {
      return evalBinaryExpression(expression, context);
    }
    if (expression is ConditionalExpression) {
      return evalConditionalExpression(expression, context);
    }
    throw new ArgumentError(
        "Unknown expression type '${expression.runtimeType}'");
  }

  dynamic evalLiteral(Literal literal, Map<String, dynamic> context) {
    var value = literal.value;
    if (value is List) return value.map((e) => eval(e, context)).toList();
    return value;
  }

  dynamic evalVariable(Variable variable, Map<String, dynamic> context) {
    return context[variable.identifier.name];
  }

  dynamic evalThis(ThisExpression expression, Map<String, dynamic> context) {
    return context['this'];
  }

  dynamic evalMemberExpression(
      MemberExpression expression, Map<String, dynamic> context) {
    throw new UnsupportedError('Member expressions not supported');
  }

  dynamic evalIndexExpression(
      IndexExpression expression, Map<String, dynamic> context) {
    return eval(expression.object, context)[eval(expression.index, context)];
  }

  dynamic evalCallExpression(
      CallExpression expression, Map<String, dynamic> context) {
    var callee = eval(expression.callee, context);
    var arguments = expression.arguments.map((e) => eval(e, context)).toList();
    return Function.apply(callee, arguments);
  }

  dynamic evalUnaryExpression(
      UnaryExpression expression, Map<String, dynamic> context) {
    var argument = eval(expression.argument, context);
    switch (expression.operator) {
      case '-':
        return -argument;
      case '+':
        return argument;
      case '!':
        return !argument;
      case '~':
        return ~argument;
    }
    throw new ArgumentError('Unknown unary operator ${expression.operator}');
  }

  dynamic evalBinaryExpression(
      BinaryExpression expression, Map<String, dynamic> context) {
    var left = eval(expression.left, context);
    var right = () => eval(expression.right, context);
    switch (expression.operator) {
      case '||':
        return left || right();
      case '&&':
        return left && right();
      case '|':
        return left | right();
      case '^':
        return left ^ right();
      case '&':
        return left & right();
      case '==':
        return left == right();
      case '!=':
        return left != right();
      case '<=':
        return left <= right();
      case '>=':
        return left >= right();
      case '<':
        return left < right();
      case '>':
        return left > right();
      case '<<':
        return left << right();
      case '>>':
        return left >> right();
      case '+':
        return left + right();
      case '-':
        return left - right();
      case '*':
        return left * right();
      case '/':
        return left / right();
      case '%':
        return left % right();
    }
    throw new ArgumentError(
        'Unknown operator ${expression.operator} in expression');
  }

  dynamic evalConditionalExpression(
      ConditionalExpression expression, Map<String, dynamic> context) {
    var test = eval(expression.test, context);
    return test
        ? eval(expression.consequent, context)
        : eval(expression.alternate, context);
  }
}
