import 'dart:async';

import 'package:expressions/expressions.dart';
import 'package:rxdart/rxdart.dart';

Stream _asStream(dynamic v) => v is Stream
    ? v
    : v is Future
        ? Stream.fromFuture(v)
        : Stream.value(v);
Literal _asLiteral(dynamic v) {
  if (v is Map) {
    return Literal(v.map((k, v) => MapEntry(_asLiteral(k), _asLiteral(v))));
  }
  if (v is List) {
    return Literal(v.map((v) => _asLiteral(v)).toList());
  }
  return Literal(v);
}

class AsyncExpressionEvaluator extends ExpressionEvaluator {
  final ExpressionEvaluator baseEvaluator = const ExpressionEvaluator();

  const AsyncExpressionEvaluator(
      {List<MemberAccessor> memberAccessors = const []})
      : super(memberAccessors: memberAccessors);

  @override
  Stream eval(Expression expression, Map<String, dynamic> context) {
    return _asStream(super.eval(expression, context));
  }

  @override
  Stream evalBinaryExpression(
      BinaryExpression expression, Map<String, dynamic> context) {
    var left = eval(expression.left, context);
    var right = eval(expression.right, context);

    return CombineLatestStream.combine2(left, right, (a, b) {
      return baseEvaluator.evalBinaryExpression(
          BinaryExpression(expression.operator, _asLiteral(a), _asLiteral(b)),
          context);
    });
  }

  @override
  Stream evalUnaryExpression(
      UnaryExpression expression, Map<String, dynamic> context) {
    var argument = eval(expression.argument, context);

    return argument.map((v) {
      return baseEvaluator.evalUnaryExpression(
          UnaryExpression(expression.operator, _asLiteral(v),
              prefix: expression.prefix),
          context);
    });
  }

  @override
  dynamic evalCallExpression(
      CallExpression expression, Map<String, dynamic> context) {
    var callee = eval(expression.callee, context);
    var arguments = expression.arguments.map((e) => eval(e, context)).toList();
    return CombineLatestStream([callee, ...arguments], (l) {
      return baseEvaluator.evalCallExpression(
          CallExpression(
              _asLiteral(l.first), [for (var v in l.skip(1)) _asLiteral(v)]),
          context);
    }).switchMap((v) => _asStream(v));
  }

  @override
  Stream evalConditionalExpression(
      ConditionalExpression expression, Map<String, dynamic> context) {
    var test = eval(expression.test, context);
    var cons = eval(expression.consequent, context);
    var alt = eval(expression.alternate, context);

    return CombineLatestStream.combine3(test, cons, alt, (test, cons, alt) {
      return baseEvaluator.evalConditionalExpression(
          ConditionalExpression(
              _asLiteral(test), _asLiteral(cons), _asLiteral(alt)),
          context);
    });
  }

  @override
  Stream evalIndexExpression(
      IndexExpression expression, Map<String, dynamic> context) {
    var obj = eval(expression.object, context);
    var index = eval(expression.index, context);
    return CombineLatestStream.combine2(obj, index, (obj, index) {
      return baseEvaluator.evalIndexExpression(
          IndexExpression(_asLiteral(obj), _asLiteral(index)), context);
    });
  }

  @override
  Stream evalLiteral(Literal literal, Map<String, dynamic> context) {
    return Stream.value(literal.value);
  }

  @override
  Stream evalThis(ThisExpression expression, Map<String, dynamic> context) {
    return _asStream(baseEvaluator.evalThis(expression, context));
  }

  @override
  Stream evalVariable(Variable variable, Map<String, dynamic> context) {
    return _asStream(baseEvaluator.evalVariable(variable, context));
  }

  @override
  Stream evalMemberExpression(
      MemberExpression expression, Map<String, dynamic> context) {
    var v = eval(expression.object, context);

    return v.switchMap((v) {
      return _asStream(getMember(v, expression.property.name));
    });
  }
}
