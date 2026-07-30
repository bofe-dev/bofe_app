import 'package:bofe/build_context.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../graphql/schema.graphql.dart';
import '../graphql/fragments/board_item_fragment.graphql.dart';
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

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.router.pushToBoard(board),
      child: Ink(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: colorScheme.onInverseSurface),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.hardEdge,
          children: [
            if (board.backgroundImageAttachment != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: board.backgroundImageAttachment!.thumbnailUrl!.toString(),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
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
          ],
        ),
      ),
    );
  }
}
