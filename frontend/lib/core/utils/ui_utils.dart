import 'package:flutter/material.dart';

/// UI 相關工具方法
///
/// 提供統一的 UI 元件顯示方法，包括 SnackBar、Dialog 等
class UiUtils {
  UiUtils._(); // 私有建構子，防止實例化

  /// 顯示錯誤訊息 SnackBar
  ///
  /// [context] BuildContext
  /// [message] 錯誤訊息內容
  static void showErrorSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: '關閉',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// 顯示成功訊息 SnackBar
  ///
  /// [context] BuildContext
  /// [message] 成功訊息內容
  static void showSuccessSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 顯示一般訊息 SnackBar
  ///
  /// [context] BuildContext
  /// [message] 訊息內容
  static void showInfoSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  /// 顯示載入對話框
  ///
  /// [context] BuildContext
  /// [message] 載入訊息（選填）
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(message ?? '載入中...'),
            ],
          ),
        ),
      ),
    );
  }

  /// 顯示確認對話框
  ///
  /// [context] BuildContext
  /// [title] 對話框標題
  /// [content] 對話框內容
  /// [confirmText] 確認按鈕文字（預設：「確定」）
  /// [cancelText] 取消按鈕文字（預設：「取消」）
  /// [isDangerous] 是否為危險操作（會將確認按鈕設為紅色）
  ///
  /// 返回：使用者是否確認（true/false）
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = '確定',
    String cancelText = '取消',
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDangerous
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
