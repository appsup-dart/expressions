import 'package:expressions/expressions.dart';
import 'package:expressions/src/parser.dart';
import 'package:test/test.dart';
import 'dart:math';
import 'package:petitparser/petitparser.dart';

void main() {
  group('parse', () {
    var parser = ExpressionParser();

    test('identifier', () {
      for (var v in ['foo', '_value', r'$x1']) {
        expect(parser.identifier.end().parse(v).value.name, v);
      }

      for (var v in ['1', '-qdf', '.sfd']) {
        expect(parser.identifier.end().parse(v).isSuccess, isFalse);
      }
    });

    test('numeric literal', () {
      for (var v in ['134', '.5', '43.2', '1e3', '1E-3', '1e+0', '0x01']) {
        var w = parser.numericLiteral.end().parse(v);
        expect(w.isSuccess, isTrue, reason: 'Failed parsing `$v`');
        expect(w.value.value, num.parse(v));
        expect(w.value.raw, v);
      }

      for (var v in [
        '-134',
        '.5.4',
        '1e5E3',
      ]) {
        expect(parser.numericLiteral.end().parse(v).isSuccess, isFalse);
      }
    });

    test('string literal', () {
      for (var v in <String>[
        "'qf sf q'",
        "'qfqsd\"qsfd'",
        "'qsd\\nfqs\\'qsdf'",
        '"qf sf q"',
        '"qfqsd\'qsfd"',
        '"qsdf\\tqs\\"qsdf"',
        r'"\\"',
      ]) {
        var w = parser.stringLiteral.end().parse(v);
        expect(w.isSuccess, isTrue, reason: 'Failed parsing `$v`');
        expect(w.value.value, parser.unescape(v.substring(1, v.length - 1)));
        expect(w.value.raw, v);
      }

      for (var v in [
        "sd'<sdf'",
        "'df'sdf'",
      ]) {
        expect(parser.stringLiteral.end().parse(v).isSuccess, isFalse);
      }
    });
    test('bool literal', () {
      for (var v in <String>['true', 'false']) {
        var w = parser.boolLiteral.end().parse(v);
        expect(w.isSuccess, isTrue, reason: 'Failed parsing `$v`');
        expect(w.value.value, v == 'true');
        expect(w.value.raw, v);
      }

      for (var v in ['True', 'False']) {
        expect(parser.boolLiteral.end().parse(v).isSuccess, isFalse);
      }
    });

    test('null literal', () {
      for (var v in <String>['null']) {
        var w = parser.nullLiteral.end().parse(v);
        expect(w.isSuccess, isTrue, reason: 'Failed parsing `$v`');
        expect(w.value.value, isNull);
        expect(w.value.raw, v);
      }

      for (var v in ['NULL']) {
        expect(parser.nullLiteral.end().parse(v).isSuccess, isFalse);
      }
    });

    test('this literal', () {
      for (var v in <String>['this']) {
        var w = parser.thisExpression.end().parse(v);
        expect(w.isSuccess, isTrue, reason: 'Failed parsing `$v`');
        expect(w.value, isA<ThisExpression>());
      }
    });

    test('map literal', () {
      for (var e in {
        '{"hello": 1, "world": 2}': {
          Literal('hello'): Literal(1),
          Literal('world'): Literal(2),
        },
        '{}': {}
      }.entries) {
        var v = e.key;
        var w = parser.mapLiteral.end().parse(v);
        expect(w.isSuccess, isTrue, reason: 'Failed parsing `$v`');
        expect(w.value.value, e.value);
        expect(w.value.raw, v);
      }
    });

    test('array literal', () {
      for (var e in {
        '[1, 2, 3]': [Literal(1), Literal(2), Literal(3)],
        '[]': []
      }.entries) {
        var v = e.key;
        var w = parser.arrayLiteral.end().parse(v);
        expect(w.isSuccess, isTrue, reason: 'Failed parsing `$v`');
        expect(w.value.value, e.value);
        expect(w.value.raw, v);
      }

      for (var v in ['[1,2[']) {
        expect(parser.arrayLiteral.end().parse(v).isSuccess, isFalse);
      }
    });

    test('token', () {
      for (var v in <String>[
        'x',
        '_qsdf',
        'x.y',
        'a[1]',
        'a.b[c]',
        'f(1, 2)',
        '(a+B).x',
        'foo.bar(baz)',
        '1',
        '"abc"',
        '(a%2)'
      ]) {
        var w = parser.token.end().parse(v);
        expect(w.isSuccess, isTrue, reason: 'Failed parsing `$v`');
        expect(w.value.toTokenString(), v);
      }
    });

    test('binary expression', () {
      for (var v in <String>[
        '1',
        '1+2',
        'a+b*2-Math.sqrt(2)',
        '-1+2',
        '1+4-5%2*5<4==(2+1)*1<=2&&2||2'
      ]) {
        var w = parser.binaryExpression.end().parse(v);
        expect(w.isSuccess, isTrue, reason: 'Failed parsing `$v`');
        expect(w.value.toString(), v);
      }
    });

    test('unary expression', () {
      for (var v in <String>['+1', '-a', '!true', '~0x01']) {
        var w = parser.unaryExpression.end().parse(v);
        expect(w.isSuccess, isTrue, reason: 'Failed parsing `$v`');
        expect(w.value.toString(), v);
      }
    });

    test('conditional expression', () {
      for (var v in <String>["1<2 ? 'always' : 'never'"]) {
        var w = parser.expression.end().parse(v);
        expect(w.isSuccess, isTrue, reason: 'Failed parsing `$v`');
        expect(w.value.toString(), v);
      }
    });
  });

  group('evaluation', () {
    var evaluator = const ExpressionEvaluator();

    test('math and logical expressions', () {
      var context = {'x': 3, 'y': 4, 'z': 5};
      var expressions = {
        '1+2': 3,
        '-1+2': 1,
        '1+4-5%2*3': 2,
        'x*x+y*y==z*z': true,
        'n ?? 1': 1,
        '5~/2': 2,
      };

      expressions.forEach((e, r) {
        expect(evaluator.eval(Expression.parse(e), context), r);
      });
    });
    test('index expressions', () {
      var context = {
        'l': [1, 2, 3],
        'm': {
          'x': 3,
          'y': 4,
          'z': 5,
          's': [null]
        }
      };
      var expressions = {'l[1]': 2, "m['z']": 5, "m['s'][0]": null};

      expressions.forEach((e, r) {
        expect(evaluator.eval(Expression.parse(e), context), r);
      });
    });
    test('call expressions', () {
      var context = {
        'x': 3,
        'y': 4,
        'z': 5,
        'sqrt': sqrt,
        'sayHi': () => 'hi',
      };
      var expressions = {'sqrt(x*x+y*y)': 5, 'sayHi()': 'hi'};

      expressions.forEach((e, r) {
        expect(evaluator.eval(Expression.parse(e), context), r);
      });
    });
    test('conditional expressions', () {
      var context = {'this': [], 'other': {}};
      var expressions = {"this==other ? 'same' : 'different'": 'different'};

      expressions.forEach((e, r) {
        expect(evaluator.eval(Expression.parse(e), context), r);
      });
    });
    test('array expression', () {
      var context = <String, dynamic>{};
      var expressions = {
        '[1,2,3]': [1, 2, 3]
      };

      expressions.forEach((e, r) {
        expect(evaluator.eval(Expression.parse(e), context), r);
      });
    });
    test('map expression', () {
      var context = <String, dynamic>{};
      var expressions = {
        '{"hello": "world"}': {'hello': 'world'}
      };

      expressions.forEach((e, r) {
        expect(evaluator.eval(Expression.parse(e), context), r);
      });
    });

    group('member expressions', () {
      test('toString member', () {
        var evaluator = ExpressionEvaluator(memberAccessors: [
          MemberAccessor<Object?>({'toString': (v) => v.toString})
        ]);

        var expression = Expression.parse('x.toString()');

        expect(evaluator.eval(expression, {'x': null}), 'null');
        expect(evaluator.eval(expression, {'x': 1}), '1');
        expect(evaluator.eval(expression, {'x': true}), 'true');
        expect(evaluator.eval(expression, {'x': DateTime(2020, 1, 1)}),
            '2020-01-01 00:00:00.000');
      });

      test('Uri members', () {
        var evaluator = ExpressionEvaluator(memberAccessors: [
          MemberAccessor<Uri>({
            'host': (v) => v.host,
            'path': (v) => v.path,
            'scheme': (v) => v.scheme,
            'queryParameters': (v) => v.queryParameters,
          })
        ]);

        var context = {'x': Uri.parse('http://localhost/index.html?lang=nl')};

        expect(
            evaluator.eval(Expression.parse('x.host'), context), 'localhost');
        expect(
            evaluator.eval(Expression.parse('x.path'), context), '/index.html');
        expect(evaluator.eval(Expression.parse('x.scheme'), context), 'http');
        expect(evaluator.eval(Expression.parse('x.queryParameters'), context),
            {'lang': 'nl'});
      });

      test('Map members', () {
        var evaluator =
            ExpressionEvaluator(memberAccessors: [MemberAccessor.mapAccessor]);

        var context = {
          'x': {'y': 1, 'z': 2}
        };

        expect(evaluator.eval(Expression.parse('x.y'), context), 1);
        expect(evaluator.eval(Expression.parse('x.z'), context), 2);
      });

      test('leading and trailing whitespace around expression', () {
        var evaluator = ExpressionEvaluator();

        expect(evaluator.eval(Expression.parse(' 42'), {}), 42);
        expect(evaluator.eval(Expression.parse('42 '), {}), 42);
        expect(evaluator.eval(Expression.parse(' 42 '), {}), 42);
      });

      test('function with whitespace in arguments', () {
        var evaluator = ExpressionEvaluator();

        final context = {
          'func': () => 42,
          'func1': (a) => 42,
          'func2': (a, b) => 42,
        };

        expect(evaluator.eval(Expression.parse('func()'), context), 42);
        expect(evaluator.eval(Expression.parse('func( )'), context), 42);
        expect(evaluator.eval(Expression.parse('func1( 1 )'), context), 42);
        expect(evaluator.eval(Expression.parse('func2( 1, 2 )'), context), 42);
      });
    });
  });

  group('failure handling', () {
    test('Expression.parse() throws on an invalid expression', () {
      expect(() => Expression.parse('5 1 6'), throwsA(isA<ParserException>()));
    });

    test('Expression.tryParse() returns null on an invalid expression', () {
      expect(Expression.tryParse('5 1 6'), null);
    });
  });
}
