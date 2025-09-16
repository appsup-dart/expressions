[![Ceasefire Now](https://badge.techforpalestine.org/default)](https://techforpalestine.org/learn-more)

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



Example 2: evaluate expression with custom evaluator

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



## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/appsup-dart/expressions/issues

## Sponsor

Creating and maintaining this package takes a lot of time. If you like the result, please consider to [:heart: sponsor](https://github.com/sponsors/rbellens). 
With your support, I will be able to further improve and support this project.
Also, check out my other dart packages at [pub.dev](https://pub.dev/packages?q=publisher%3Aappsup.be).

