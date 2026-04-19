import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Describes a single action in an adaptive dialog.
class AdaptiveDialogAction<T> {
  const AdaptiveDialogAction({
    required this.label,
    this.onPressed,
    this.isDefault = false,
    this.isDestructive = false,
    this.result,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isDefault;
  final bool isDestructive;
  final T? result;
}

/// Shows a platform-appropriate alert dialog.
///
/// On iOS/macOS renders a `CupertinoAlertDialog`, on other platforms a
/// Material `AlertDialog`. If [onPressed] on an action is null, the dialog
/// pops automatically returning [result].
Future<T?> showAdaptiveAlertDialog<T>({
  required BuildContext context,
  String? title,
  String? content,
  required List<AdaptiveDialogAction<T>> actions,
  bool barrierDismissible = true,
}) {
  return showAdaptiveDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) {
      final isCupertino =
          Theme.of(ctx).platform == TargetPlatform.iOS ||
          Theme.of(ctx).platform == TargetPlatform.macOS;

      final children = actions.map((action) {
        void handleTap() {
          if (action.onPressed != null) {
            action.onPressed!();
          } else {
            Navigator.of(ctx).pop(action.result);
          }
        }

        if (isCupertino) {
          return CupertinoDialogAction(
            onPressed: handleTap,
            isDefaultAction: action.isDefault,
            isDestructiveRole: action.isDestructive,
            child: Text(action.label),
          );
        }
        return TextButton(
          onPressed: handleTap,
          child: Text(
            action.label,
            style: action.isDestructive
                ? TextStyle(color: Theme.of(ctx).colorScheme.error)
                : null,
          ),
        );
      }).toList();

      return AlertDialog.adaptive(
        title: title == null ? null : Text(title),
        content: content == null ? null : Text(content),
        actions: children,
      );
    },
  );
}
