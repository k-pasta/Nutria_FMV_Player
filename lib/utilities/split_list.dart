List<List<T>> splitList<T>(List<T> items) {
    int len = items.length;

    // For 3 or fewer, everything goes to the top
    if (len <= 3) {
      return [items, []];
    }

    // Split in half, give the extra item to the top row
    int topCount = (len / 2).ceil();
    List<T> top = items.take(topCount).toList();
    List<T> bottom = items.skip(topCount).toList();

    return [top, bottom];
  }