# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

## 2025-09-16

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`expressions` - `v0.2.5+3`](#expressions---v0253)

---

#### `expressions` - `v0.2.5+3`

 - **REFACTOR**: set min sdk to 3.0.0. ([44e8bbdf](https://github.com/appsup-dart/expressions/commit/44e8bbdf9922397cb0d001c30b00fd8f6de67241))
 - **REFACTOR**: support for petitparser ^7.0.0. ([be9a7f90](https://github.com/appsup-dart/expressions/commit/be9a7f90c5d4f4c335ddf86b25c3b215c9c377eb))

## 0.2.5+3

 - **REFACTOR**: set min sdk to 3.0.0. ([44e8bbdf](https://github.com/appsup-dart/expressions/commit/44e8bbdf9922397cb0d001c30b00fd8f6de67241))
 - **REFACTOR**: support for petitparser ^7.0.0. ([be9a7f90](https://github.com/appsup-dart/expressions/commit/be9a7f90c5d4f4c335ddf86b25c3b215c9c377eb))

## 0.2.5+2

 - **REFACTOR**: support for rxdart ^0.28.0. ([fc936d03](https://github.com/appsup-dart/expressions/commit/fc936d03350cf301f1d7c3edb8fb95d5c8f71c14))

## 0.2.5+1

 - **REFACTOR**: upgrade `petitparser` dependency. ([3c773ccc](https://github.com/appsup-dart/expressions/commit/3c773ccc9a2e64d8264de32d042df4bc3b6a1fee))

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
