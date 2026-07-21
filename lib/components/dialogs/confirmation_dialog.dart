import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../build_context.dart';

Future<dynamic> showConfirmationDialog(
  BuildContext context, {
  String? titleText,
  required String messageText,
  required FutureOr<void> Function() onConfirm,
}) {
  return showDialog(
    context: context,
    builder: (context) => _ConfirmationDialog(titleText: titleText, messageText: messageText, onConfirm: onConfirm),
  );
}

class _ConfirmationDialog extends StatelessWidget {
  const _ConfirmationDialog({this.titleText, required this.messageText, required this.onConfirm});

  final String? titleText;
  final String messageText;
  final FutureOr<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(titleText ?? context.l10n.confirmThisAction),
      content: Text(messageText),
      actions: [
        OutlinedButton(child: Text(context.l10n.cancel), onPressed: () => context.pop()),
        FilledButton(
          child: Text(context.l10n.confirm),
          onPressed: () async {
            context.pop();
            await onConfirm();
          },
        ),
      ],
    );
  }
}
