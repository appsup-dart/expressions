library expressions.evaluator;

import 'expressions.dart';
import 'async_evaluator.dart';
import 'package:meta/meta.dart';

/// Handles evaluation of expressions
///
/// The default [ExpressionEvaluator] handles all expressions except member
/// expressions. To create an [ExpressionEvaluator] that handles member
/// expressions, set a list of [MemberAccessor] instances to the
/// [memberAccessors] argument of the constructor.
///
/// For example:
///
///   var evaluator = ExpressionEvaluator(memberAccessors: [
///     MemberAccessor&lt;Person&gt;({
///       'firstname': (v)=>v.firstname,
///       'lastname': (v)=>v.lastname,
///       'address': (v)=>v.address
///     }),
///     MemberAccessor&lt;Address&gt;({
///       'street': (v)=>v.street,
///       'locality': (v)=>v.locality,
///     }),
///   ]);
///
/// The [MemberAccessor.mapAccessor] can be used to access [Map] items with
/// member access syntax.
///
/// An async [ExpressionEvaluator] can be created with the
/// [ExpressionEvaluator.async] constructor. An async expression evaluator can
/// handle operands and arguments that are streams or futures and will apply the
/// expression on each value of those streams or futures. The result is always a
/// stream.
///
/// For example:
///
///   var evaluator = ExpressionEvaluator.async();
///
///   var expression = Expression.parse('x > 70');
///
///   var r = evaluator.eval(expression, {'x': Stream.fromIterable([50, 80])});
///
///   r.forEach(print); // prints false and true
///
class ExpressionEvaluator {
  final List<MemberAccessor> memberAccessors;

  const ExpressionEvaluator({this.memberAccessors = const []});

  const factory ExpressionEvaluator.async(
      {List<MemberAccessor> memberAccessors}) = AsyncExpressionEvaluator;

  dynamic eval(Expression expression, Map<String, dynamic> context) {
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
    throw ArgumentError("Unknown expression type '${expression.runtimeType}'");
  }

  @protected
  dynamic evalLiteral(Literal literal, Map<String, dynamic> context) {
    var value = literal.value;
    if (value is List) return value.map((e) => eval(e, context)).toList();
    if (value is Map) {
      return value.map(
          (key, value) => MapEntry(eval(key, context), eval(value, context)));
    }
    return value;
  }

  @protected
  dynamic evalVariable(Variable variable, Map<String, dynamic> context) {
    return context[variable.identifier.name];
  }

  @protected
  dynamic evalThis(ThisExpression expression, Map<String, dynamic> context) {
    return context['this'];
  }

  @protected
  dynamic evalMemberExpression(
      MemberExpression expression, Map<String, dynamic> context) {
    var obj = eval(expression.object, context);

    return getMember(obj, expression.property.name);
  }

  @protected
  dynamic evalIndexExpression(
      IndexExpression expression, Map<String, dynamic> context) {
    return eval(expression.object, context)[eval(expression.index, context)];
  }

  @protected
  dynamic evalCallExpression(
      CallExpression expression, Map<String, dynamic> context) {
    var callee = eval(expression.callee, context);
    var arguments = expression.arguments.map((e) => eval(e, context)).toList();
    return Function.apply(callee, arguments);
  }

  @protected
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
    throw ArgumentError('Unknown unary operator ${expression.operator}');
  }

  @protected
  dynamic evalBinaryExpression(
      BinaryExpression expression, Map<String, dynamic> context) {
    var left = eval(expression.left, context);
    right() => eval(expression.right, context);
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
      case '~/':
        return left ~/ right();
      case '??':
        return left ?? right();
    }
    throw ArgumentError(
        'Unknown operator ${expression.operator} in expression');
  }

  @protected
  dynamic evalConditionalExpression(
      ConditionalExpression expression, Map<String, dynamic> context) {
    var test = eval(expression.test, context);
    return test
        ? eval(expression.consequent, context)
        : eval(expression.alternate, context);
  }

  @protected
  dynamic getMember(dynamic obj, String member) {
    for (var a in memberAccessors) {
      if (a.canHandle(obj, member)) {
        return a.getMember(obj, member);
      }
    }
    throw ExpressionEvaluatorException.memberAccessNotSupported(
        obj.runtimeType, member);
  }
}

class ExpressionEvaluatorException implements Exception {
  final String message;

  ExpressionEvaluatorException(this.message);

  ExpressionEvaluatorException.memberAccessNotSupported(
      Type type, String member)
      : this(
            'Access of member `$member` not supported for objects of type `$type`: have you defined a member accessor in the ExpressionEvaluator?');

  @override
  String toString() {
    return 'ExpressionEvaluatorException: $message';
  }
}

typedef SingleMemberAccessor<T> = dynamic Function(T);
typedef AnyMemberAccessor<T> = dynamic Function(T, String member);

abstract class MemberAccessor<T> {
  static const MemberAccessor<Map> mapAccessor =
      MemberAccessor<Map>.fallback(_getMapItem);

  static dynamic _getMapItem(Map map, String key) => map[key];

  const factory MemberAccessor(Map<String, SingleMemberAccessor<T>> accessors) =
      _MemberAccessor;

  const factory MemberAccessor.fallback(AnyMemberAccessor<T> accessor) =
      _MemberAccessorFallback;

  dynamic getMember(T object, String member);

  bool canHandle(dynamic object, String member);
}

class _MemberAccessorFallback<T> implements MemberAccessor<T> {
  final AnyMemberAccessor<T> accessor;

  const _MemberAccessorFallback(this.accessor);
  @override
  bool canHandle(object, String member) {
    if (object is! T) return false;
    return true;
  }

  @override
  dynamic getMember(T object, String member) {
    return accessor(object, member);
  }
}

class _MemberAccessor<T> implements MemberAccessor<T> {
  final Map<String, SingleMemberAccessor<T>> accessors;

  const _MemberAccessor(this.accessors);

  @override
  bool canHandle(object, String member) {
    if (object is! T) return false;
    if (accessors.containsKey(member)) return true;
    return false;
  }

  @override
  dynamic getMember(T object, String member) {
    return accessors[member]!(object);
  }
}
