import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../build_context.dart';
import '../config.dart';
import '../graphql/fragments/card_fragment.graphql.dart';
import '../graphql/mutations/archive_card.graphql.dart';
import '../graphql/mutations/delete_card.graphql.dart';
import '../graphql/mutations/unarchive_card.graphql.dart';
import 'dialogs/confirmation_dialog.dart';
import 'dialogs/edit_card_dialog.dart';
import 'loading_overlay.dart';
import 'snack_bar_alert.dart';

class CardMenuAnchor extends StatelessWidget {
  const CardMenuAnchor({
    super.key,
    required this.card,
    this.iconSize,
    this.beforeEdit,
    this.afterArchive,
    this.afterDelete,
  });

  final Fragment$CardFragment card;
  final double? iconSize;
  final Function()? beforeEdit;
  final Function()? afterArchive;
  final Function()? afterDelete;

  Future<void> _attemptToArchiveCard(BuildContext context) async {
    final loadingOverlay = showLoadingOverlay(context);
    final result = await context.graphQLClient.mutate$ArchiveCard(
      Options$Mutation$ArchiveCard(variables: Variables$Mutation$ArchiveCard(id: card.id)),
    );

    if (context.mounted && result.parsedData?.archiveCard == null) {
      final errors = result.exception?.graphqlErrors.first;

      showSnackBarAlert(context, errors?.message ?? context.l10n.failedToArchiveCard);
    }

    loadingOverlay.hide();
  }

  Future<void> _attemptToDeleteCard(BuildContext context) async {
    final loadingOverlay = showLoadingOverlay(context);
    final result = await context.graphQLClient.mutate$DeleteCard(
      Options$Mutation$DeleteCard(variables: Variables$Mutation$DeleteCard(id: card.id)),
    );

    if (context.mounted && result.parsedData?.deleteCard != true) {
      final errors = result.exception?.graphqlErrors.first;

      showSnackBarAlert(context, errors?.message ?? 'Failed to delete card');
    }

    loadingOverlay.hide();
  }

  Future<void> _attemptToUnarchiveCard(BuildContext context) async {
    final loadingOverlay = showLoadingOverlay(context);

    final result = await context.graphQLClient.mutate$UnarchiveCard(
      Options$Mutation$UnarchiveCard(variables: Variables$Mutation$UnarchiveCard(id: card.id)),
    );

    if (context.mounted && result.parsedData?.unarchiveCard == null) {
      final errors = result.exception?.graphqlErrors.first;

      showSnackBarAlert(context, errors?.message ?? context.l10n.failedToUnarchiveCard);
    }

    loadingOverlay.hide();
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      builder: (context, controller, child) => IconButton(
        onPressed: () => controller.isOpen ? controller.close() : controller.open(),
        icon: const Icon(Icons.more_vert_rounded),
        tooltip: context.l10n.more,
      ),
      menuChildren: [
        MenuItemButton(
          onPressed: () {
            SharePlus.instance.share(
              ShareParams(
                uri: Config.appUrl.replace(path: '/${card.board.user.username}/${card.board.slug}/cards/${card.id}'),
              ),
            );
          },
          leadingIcon: Icon(Icons.share_rounded),
          child: Text(context.l10n.share),
        ),
        if (card.isEditable)
          MenuItemButton(
            onPressed: () {
              beforeEdit?.call();
              showEditCardDialog(context, card: card);
            },
            leadingIcon: const Icon(Icons.edit_rounded),
            child: Text(context.l10n.edit),
          ),
        if (card.isArchivable)
          MenuItemButton(
            onPressed: () => showConfirmationDialog(
              context,
              messageText: context.l10n.areYouSureYouWantToArchiveThisCard,
              onConfirm: () async {
                await _attemptToArchiveCard(context);
                afterArchive?.call();
              },
            ),
            leadingIcon: Icon(Icons.archive_rounded),
            child: Text(context.l10n.archive),
          ),
        if (card.isUnarchivable)
          MenuItemButton(
            onPressed: () => showConfirmationDialog(
              context,
              messageText: context.l10n.areYouSureYouWantToUnarchiveThisCard,
              onConfirm: () async {
                await _attemptToUnarchiveCard(context);
                afterArchive?.call();
              },
            ),
            leadingIcon: Icon(Icons.unarchive_rounded),
            child: Text(context.l10n.unarchive),
          ),
        if (card.isDeletable)
          MenuItemButton(
            onPressed: () => showConfirmationDialog(
              context,
              messageText: context.l10n.areYouSureYouWantToDeleteThisCard,
              onConfirm: () async {
                await _attemptToDeleteCard(context);
                afterDelete?.call();
              },
            ),
            leadingIcon: const Icon(Icons.delete_rounded),
            child: Text(context.l10n.delete),
          ),
      ],
    );
  }
}
