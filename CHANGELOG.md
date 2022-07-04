# Changelog

# 0.2.4

- upgrade petitparser dependency to 5.0.0

## 0.2.3

- upgrade rxdart dependency to 0.27.0

## 0.2.2

- `ExpressionEvaluator.async` now also handles futures 
- Support petitparser 4.1.0

## 0.2.1

- add `memberAccessors` argument to `ExpressionEvaluator` that defines how to handle member expressions
- add `ExpressionEvaluator.async` constructor to create an async expression evaluator that applies expressions to the values of streams 

## 0.2.0

- null-safety

## 0.1.5

- add `Expression.tryParse` method

## 0.1.4

- fix parsing empty array or argument list
- parse map expressions

## 0.1.3

- petitparser 3 compatibility

## 0.1.2

- Support Dart 2 in pubspec.yaml
- Use the petitparser version 2 package with fully typed parsers instead of the typedparser package 

## 0.1.1

- Dart 2 strong mode fixes
- Evaluate right expression in a binary expression only when necessary

## 0.1.0

- Initial version
