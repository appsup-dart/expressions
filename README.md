[:heart: sponsor](https://github.com/sponsors/rbellens)


# expressions

[![Build Status](https://travis-ci.org/appsup-dart/expressions.svg?branch=master)](https://travis-ci.org/appsup-dart/expressions)


A library to parse and evaluate simple expressions.

This library can handle simple expressions, but no operations, blocks of code, control flow statements and so on.
It supports a syntax that is common to most programming languages (so no special things like string interpolation, 
cascade notation, named parameters).

It is partly inspired by [jsep](http://jsep.from.so/).

## Usage

Example 1: evaluate expression with default evaluator

```dart
// Parse expression:
Expression expression = Expression.parse("cos(x)*cos(x)+sin(x)*sin(x)==1");

// Create context containing all the variables and functions used in the expression
var context = {
  "x": pi / 5,
  "cos": cos,
  "sin": sin
};

// Evaluate expression
final evaluator = const ExpressionEvaluator();
var r = evaluator.eval(expression, context);


print(r); // = true
```


Example 2: evaluate expression with custom evaluator

```dart
// Parse expression:
Expression expression = Expression.parse("'Hello '+person.name");

// Create context containing all the variables and functions used in the expression
var context = {
  "person": new Person("Jane")
};

// The default evaluator can not handle member expressions like `person.name`.
// When you want to use these kind of expressions, you'll need to create a
// custom evaluator that implements the `evalMemberExpression` to get property
// values of an object (e.g. with `dart:mirrors` or some other strategy).
final evaluator = const MyEvaluator();
var r = evaluator.eval(expression, context);


print(r); // = 'Hello Jane'
```


Example 3: evaluate expression with lambdas

```dart
// Expressions can also include lambdas. These are handled by creating a
// `MemberAccessor` that returns a `Callable` object.

class WhereCallable extends Callable {
  final List<dynamic> list;
  WhereCallable(this.list);

  @override
  dynamic call(ExpressionEvaluator evaluator, List<dynamic> args) {
    var predicate = args[0] as Callable;
    return list.where((e) => predicate.call(evaluator, [e]) as bool).toList();
  }
}

// Parse expression with a lambda:
var expression = Expression.parse('[1,9,2,5,3,2].where((e) => e > 2)');

// Create an evaluator with a member accessor for `List.where`.
// The accessor for 'where' returns our custom `WhereCallable` object.
final evaluator = ExpressionEvaluator(memberAccessors: [
  MemberAccessor<List>({
    'where': (list) => WhereCallable(list as List),
  }),
]);

// Evaluate expression:
var r = evaluator.eval(expression, {});

print(r); // = [9, 5, 3]
```


## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/appsup-dart/expressions/issues

## Sponsor

Creating and maintaining this package takes a lot of time. If you like the result, please consider to [:heart: sponsor](https://github.com/sponsors/rbellens). 
With your support, I will be able to further improve and support this project.
Also, check out my other dart packages at [pub.dev](https://pub.dev/packages?q=publisher%3Aappsup.be).

