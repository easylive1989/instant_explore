import 'package:equatable/equatable.dart';

class Language extends Equatable {
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
  List<Object?> get props => [code];
}
