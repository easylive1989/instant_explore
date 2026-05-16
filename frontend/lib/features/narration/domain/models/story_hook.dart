import 'package:flutter/foundation.dart';

/// 一段歷史故事的「鉤子」預告。
///
/// 使用者在選擇頁面看到 2-3 個鉤子，挑一個之後才會展開成完整 narration。
@immutable
class StoryHook {
  final String id;
  final String title;
  final String teaser;

  const StoryHook({
    required this.id,
    required this.title,
    required this.teaser,
  });

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'teaser': teaser};

  factory StoryHook.fromJson(Map<String, dynamic> json) => StoryHook(
    id: json['id'] as String,
    title: json['title'] as String,
    teaser: json['teaser'] as String,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryHook &&
          other.id == id &&
          other.title == title &&
          other.teaser == teaser;

  @override
  int get hashCode => Object.hash(id, title, teaser);
}
