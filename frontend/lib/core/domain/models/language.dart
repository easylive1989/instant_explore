class Language {
  final String code;

  const Language(this.code);

  /// 繁體中文
  static const traditionalChinese = Language('zh-TW');

  /// 英文
  static const english = Language('en-US');

  factory Language.fromString(String code) {
    return Language(code);
  }

  @override
  String toString() => code;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Language && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;
}
