class FfException implements Exception {
  FfException(this.message);
  final String message;

  @override
  String toString() => 'FfException: $message';
}
