import 'package:bofe/build_context.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../graphql/schema.graphql.dart';
import '../graphql/fragments/board_item_fragment.graphql.dart';
import 'cached_image_attachment.dart';
import 'user_item.dart';

class BoardItem extends StatelessWidget {
  const BoardItem({super.key, required this.board});

  final Fragment$BoardItemFragment board;

  Icon _getVisibilityIcon() {
    switch (board.visibility) {
      case Enum$BoardVisibility.PRIVATE:
        return Icon(Icons.lock_rounded);
      case Enum$BoardVisibility.USERS:
        return Icon(Icons.group_rounded);
      default:
        return Icon(Icons.public_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.onInverseSurface,
        borderRadius: borderRadius12,
        boxShadow: kElevationToShadow[1],
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.hardEdge,
        children: [
          if (board.backgroundImageAttachment != null)
            ClipRRect(
              borderRadius: borderRadius12,
              child: CachedImageAttachment.thumbnailMedium(
                attachment: board.backgroundImageAttachment!,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: borderRadius12,
              color: colorScheme.onInverseSurface.withValues(alpha: 0.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              spacing: 4,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  board.name,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(board.description, maxLines: 3, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
              ],
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                UserItem(user: board.user),
                _getVisibilityIcon(),
              ],
            ),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              borderRadius: borderRadius12,
              child: InkWell(borderRadius: borderRadius12, onTap: () => context.router.pushToBoard(board)),
            ),
          ),
        ],
      ),
    );
  }
}
