extension IterableExtension on Iterable {
  List<T> joinWith<T>(T separator, {bool includeSides = false}) {
    if (isEmpty) return [];
    final list = toList();
    final joinedList = List<T>.generate(
      length * 2 - 1,
      (index) => index % 2 == 0 ? list[index ~/ 2] : separator,
    );
    return includeSides ? [separator, ...joinedList, separator] : joinedList;
  }
}
