import 'package:expressions/expressions.dart';
import 'dart:math';

void main() {
  example_1();
  example_2();
}

// Example 1: evaluate expression with default evaluator
void example_1() {
  // Parse expression:
  var expression = Expression.parse('cos(x)*cos(x)+sin(x)*sin(x)==1');

  // Create context containing all the variables and functions used in the expression
  var context = {'x': pi / 5, 'cos': cos, 'sin': sin};

  // Evaluate expression
  final evaluator = const ExpressionEvaluator();
  var r = evaluator.eval(expression, context);

  print(r); // = true
}

// Example 2: evaluate expression with custom evaluator
void example_2() {
  // Parse expression:
  var expression = Expression.parse("'Hello '+person.name");

  // Create context containing all the variables and functions used in the expression
  var context = {'person': Person('Jane')};

  // The default evaluator can not handle member expressions like `person.name`.
  // When you want to use these kind of expressions, you'll need to create a
  // custom evaluator that implements the `evalMemberExpression` to get property
  // values of an object (e.g. with `dart:mirrors` or some other strategy).
  final evaluator = const MyEvaluator();
  var r = evaluator.eval(expression, context);

  print(r); // = 'Hello Jane'
}

class Person {
  final String name;

  Person(this.name);

  Map<String, dynamic> toJson() => {'name': name};
}

class MyEvaluator extends ExpressionEvaluator {
  const MyEvaluator();

  @override
  dynamic evalMemberExpression(
      MemberExpression expression, Map<String, dynamic> context) {
    var object = eval(expression.object, context).toJson();
    return object[expression.property.name];
  }
}
