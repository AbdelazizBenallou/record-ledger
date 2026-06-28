class Calculator {
  static double? calculateAverage(List<double?> grades) {
    final valid = grades.where((g) => g != null).cast<double>().toList();
    if (valid.isEmpty) return null;
    return valid.reduce((a, b) => a + b) / valid.length;
  }

  static bool isPassing(double average) => average >= 10;
}
