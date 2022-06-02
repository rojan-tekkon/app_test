import 'dart:async';
import 'dart:developer';
import 'package:bluetooth_test/hooks/image_hooks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

extension CompactMap<T> on Iterable<T?> {
  Iterable<T> compactMap<E>([E? Function(T?)? transform]) =>
      map(transform ?? (e) => e as E).where((e) => e != null).cast();
}

void testIt() {
  final values = [1, 2, null, 3];

  final nonNull = values.compactMap((e) {
    if (e != null && e < 5) {
      return e;
    } else {
      return null;
    }
  });

  log("$nonNull");
}

const url =
    "https://previews.123rf.com/images/singpentinkhappy/singpentinkhappy2009/singpentinkhappy200910339/156087322-colorful-abstract-2021-banner-template-trend-with-dummy-text-for-web-design-landing-page-story-and-p.jpg";

class HooksPage extends HookWidget {
  const HooksPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final future = useMemoized(
      () => NetworkAssetBundle(Uri.parse(url))
          .load(url)
          .then((data) => data.buffer.asUint8List())
          .then((data) => Image.memory(data)),
    );
    final snapshot = useFuture(future);

    final countDown = useMemoized(() => CountDown(from: 20));
    final notifier = useListenable(countDown);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hooks'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Column(
              // mainAxisAlignment: MainAxisAlignment.center,
              children: [
                snapshot.data,
              ].compactMap().toList(),
            ),
            const SizedBox(height: 30),
            Text(notifier.value.toString()),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: ((context) => const ImageHooks())));
              },
              child: const Text("Open Image list"),
            ),
          ],
        ),
      ),
    );
  }
}

class CountDown extends ValueNotifier<int> {
  late StreamSubscription sub;

  CountDown({required int from}) : super(from) {
    sub = Stream.periodic(const Duration(seconds: 1), (v) => from - v).takeWhile((value) => value >= 0).listen((value) {
      this.value = value;
    });
  }

  @override
  void dispose() {
    sub.cancel();
    super.dispose();
  }
}
