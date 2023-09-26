import 'dart:async';

import 'package:expressions/expressions.dart';
import 'package:expressions/src/async_evaluator.dart';
import 'package:fake_async/fake_async.dart' as fake_async;
import 'package:test/test.dart';

void main() {
  group('AsyncExpressionEvaluator', () {
    test('Binary expression with single stream', () async {
      var expression = Expression.parse('x > 70');

      var evaluator = AsyncExpressionEvaluator();

      var f = evaluator.eval(expression, {
        'x': Stream.fromIterable([50, 80])
      });

      expect(await f.toList(), [false, true]);
    });

    test('Binary expression with future', () async {
      var expression = Expression.parse('x > 70');

      var evaluator = AsyncExpressionEvaluator();

      var f = evaluator.eval(expression, {'x': Future.value(50)});

      expect(await f.toList(), [false]);
    });

    test('Binary expression with two streams', () async {
      return fakeAsync((async) async {
        var expression = Expression.parse('x > y');

        var evaluator = AsyncExpressionEvaluator();

        var controllerX = StreamController();
        var controllerY = StreamController();

        var stream = evaluator.eval(expression, {
          'x': controllerX.stream,
          'y': controllerY.stream,
        });

        bool? current;
        var done = false;
        stream.listen((v) => current = v, onDone: () => done = true);

        controllerX.add(40);
        async.flushMicrotasks();
        expect(current, null);

        controllerY.add(60);
        async.flushMicrotasks();
        expect(current, false);

        controllerY.add(20);
        async.flushMicrotasks();
        expect(current, true);

        controllerX.add(10);
        async.flushMicrotasks();
        expect(current, false);

        await async.flushMicrotasksUntil(controllerX.close());
        await async.flushMicrotasksUntil(controllerY.close());
        await async.unblock();
        async.flushMicrotasks();
        expect(done, true);
      });
    });
    test('Binary expression with no streams', () async {
      fakeAsync((async) {
        var expression = Expression.parse('x > y');

        var evaluator = AsyncExpressionEvaluator();

        var stream = evaluator.eval(expression, {
          'x': 10,
          'y': 20,
        });

        Object? current;
        stream.listen((v) => current = v);

        async.flushMicrotasks();
        expect(current, false);
      });
    });

    test('Unary expression with single stream', () async {
      var expression = Expression.parse('- x');

      var evaluator = AsyncExpressionEvaluator();

      var f = evaluator.eval(expression, {
        'x': Stream.fromIterable([50, 80])
      });

      expect(await f.toList(), [-50, -80]);
    });

    test('Call expression with stream result', () async {
      var expression = Expression.parse('f()');

      var evaluator = AsyncExpressionEvaluator();

      var f = evaluator.eval(expression, {
        'f': () => Stream.fromIterable(['hello', 'world'])
      });

      expect(await f.toList(), ['hello', 'world']);
    });
    test('Call expression with future result', () async {
      var expression = Expression.parse('f()');

      var evaluator = AsyncExpressionEvaluator();

      var f =
          evaluator.eval(expression, {'f': () => Future.value('hello world')});

      expect(await f.toList(), ['hello world']);
    });
    test('Call expression with non stream result', () async {
      var expression = Expression.parse('f()');

      var evaluator = AsyncExpressionEvaluator();

      var f = evaluator.eval(expression, {'f': () => 'hello world'});

      expect(await f.toList(), ['hello world']);
    });
    test('Call expression with stream arguments', () async {
      await fakeAsync((async) async {
        var expression = Expression.parse('f(x,y,z)');

        var evaluator = AsyncExpressionEvaluator();

        var controllerX = StreamController();
        var controllerY = StreamController();
        var controllerZ = StreamController();

        var stream = evaluator.eval(expression, {
          'x': controllerX.stream,
          'y': controllerY.stream,
          'z': controllerZ.stream,
          'f': (a, b, c) => a + b + c,
        });

        int? current;
        var done = false;
        stream.listen((v) => current = v, onDone: () => done = true);

        controllerX.add(40);
        async.flushMicrotasks();
        expect(current, null);

        controllerY.add(60);
        async.flushMicrotasks();
        expect(current, null);

        controllerZ.add(30);
        async.flushMicrotasks();
        expect(current, 130);

        controllerZ.add(10);
        async.flushMicrotasks();
        expect(current, 110);

        controllerX.add(10);
        async.flushMicrotasks();
        expect(current, 80);

        await async.flushMicrotasksUntil(controllerX.close());
        await async.flushMicrotasksUntil(controllerY.close());
        await async.flushMicrotasksUntil(controllerZ.close());
        await async.unblock();
        async.flushMicrotasks();

        expect(done, true);
      });
    });

    test('Call expression with subsequent stream results', () async {
      await fakeAsync((async) async {
        var expression = Expression.parse('f(x)');

        var evaluator = AsyncExpressionEvaluator();

        var controllerX = StreamController();
        var controllerY = StreamController();
        var controllerZ = StreamController();

        var stream = evaluator.eval(expression, {
          'x': controllerX.stream,
          'f': (x) => x == 'y' ? controllerY.stream : controllerZ.stream,
        });

        int? current;
        var done = false;
        stream.listen((v) => current = v, onDone: () => done = true);

        controllerX.add('y');
        async.flushMicrotasks();
        expect(current, null);

        controllerY.add(1);
        async.flushMicrotasks();
        expect(current, 1);

        controllerX.add('z');
        async.flushMicrotasks();
        expect(current, 1);

        controllerZ.add(2);
        async.flushMicrotasks();
        expect(current, 2);

        controllerY.add(3);
        async.flushMicrotasks();
        expect(current, 2);

        controllerZ.add(4);
        async.flushMicrotasks();
        expect(current, 4);

        await async.flushMicrotasksUntil(controllerX.close());
        await async.unblock();
        async.flushMicrotasks();
        expect(done, false);

        await async.flushMicrotasksUntil(controllerZ.close());
        await async.unblock();
        async.flushMicrotasks();
        expect(done, true);

        await async.flushMicrotasksUntil(controllerY.close());
      });
    });

    test('Conditional expression', () async {
      await fakeAsync((async) async {
        var expression = Expression.parse('x ? y : z');

        var evaluator = AsyncExpressionEvaluator();

        var controllerX = StreamController();
        var controllerY = StreamController();
        var controllerZ = StreamController();

        var stream = evaluator.eval(expression, {
          'x': controllerX.stream,
          'y': controllerY.stream,
          'z': controllerZ.stream,
        });

        int? current;
        var done = false;
        stream.listen((v) => current = v, onDone: () => done = true);

        controllerX.add(true);
        async.flushMicrotasks();
        expect(current, null);

        controllerZ.add(1);
        async.flushMicrotasks();
        expect(current, null);

        controllerY.add(2);
        async.flushMicrotasks();
        expect(current, 2);

        controllerX.add(false);
        async.flushMicrotasks();
        expect(current, 1);

        await async.flushMicrotasksUntil(controllerX.close());
        await async.flushMicrotasksUntil(controllerY.close());
        await async.flushMicrotasksUntil(controllerZ.close());
        await async.unblock();
        async.flushMicrotasks();

        expect(done, true);
      });
    });

    test('Index expression', () async {
      await fakeAsync((async) async {
        var expression = Expression.parse('x[y]');

        var evaluator = AsyncExpressionEvaluator();

        var controllerX = StreamController();
        var controllerY = StreamController();

        var stream = evaluator.eval(expression, {
          'x': controllerX.stream,
          'y': controllerY.stream,
        });

        int? current;
        var done = false;
        stream.listen((v) => current = v, onDone: () => done = true);

        controllerX.add([1, 2, 3, 4, 5]);
        async.flushMicrotasks();
        expect(current, null);

        controllerY.add(0);
        async.flushMicrotasks();
        expect(current, 1);

        await async.flushMicrotasksUntil(controllerX.close());
        await async.flushMicrotasksUntil(controllerY.close());
        await async.unblock();
        async.flushMicrotasks();

        expect(done, true);
      });
    });
  });
}

FutureOr<T> fakeAsync<T>(
    FutureOr<T> Function(fake_async.FakeAsync async) callback,
    {DateTime? initialTime}) {
  var async = fake_async.FakeAsync(initialTime: initialTime);
  var f = async.run(callback);
  if (f is Future<T>) {
    return async.flushMicrotasksUntil<T>(f);
  }
  return f;
}

extension FakeAsyncX on fake_async.FakeAsync {
  Future<T> flushMicrotasksUntil<T>(Future<T> f) async {
    var isDone = false;
    f = f.whenComplete(
        () => isDone = true); // check if all work in body has been done
    while (!isDone) {
      // flush the microtasks in real async zone
      await unblock();
      // flush the microtasks in the fake async zone
      flushMicrotasks();
    }
    return f;
  }

  Future<void> unblock() => Zone.root.run(() => Future.microtask(() => null));
}
