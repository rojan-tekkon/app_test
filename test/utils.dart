const oneSecond = Duration(seconds: 1);

extension WithDelay<T> on T {
  toFuture([Duration? delay]) => delay != null ? Future.delayed(delay, () => this) : Future.value(this);
}

// void testIt() {
//   final value = true.toFuture(oneSecond);
// }
