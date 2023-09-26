## 0.3.0

- Migrated to `petitparser: ^6.0.1`.
- Fixed lints.

- Added GitHub Workflow `Dart CI`, with test jobs for `vm` and `chrome`. 

- Updated Dart SDK constraint due to dependencies that require it.:
  - sdk: '>=3.0.0 <4.0.0'

- Updated dependencies:
  - quiver: ^3.2.1
  - petitparser: ^6.0.1
  - rxdart: ^0.27.7
  - fake_async: ^1.3.1 (only used in tests: moved to `dev_dependencies`)
  - meta: ^1.10.0
  - test: ^1.24.6
  - lints: ^2.1.1
    - `pedantic` was discontinued and replaced by `lints`.
  - dependency_validator: ^3.2.2

## 0.2.5

 - **FIX**: parsing string with \\. ([7ec99cbd](https://github.com/appsup-dart/expressions/commit/7ec99cbd1ac005cd0150d224ca13fd4ea9fafd8a))
 - **FEAT**: support for the truncating division operator ~/. ([69566483](https://github.com/appsup-dart/expressions/commit/695664837460bc3f0bf9eeebdb5e68a2fb1cc976))


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
