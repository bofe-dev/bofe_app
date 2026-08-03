import 'package:flutter/material.dart';
import 'package:timeago_flutter/timeago_flutter.dart';

import '../build_context.dart';
import '../graphql/fragments/card_fragment.graphql.dart';
import 'user_item.dart';

class CardMetadata extends StatelessWidget {
  const CardMetadata({super.key, required this.card, this.showListName = false, this.onUserTap});

  final Fragment$CardFragment card;
  final bool showListName;
  final void Function()? onUserTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 6,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UserItem(user: card.user, onTap: onUserTap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            spacing: 3,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 6,
                children: card.isArchived
                    ? [
                        Text(context.l10n.archived, style: TextStyle(fontSize: 12)),
                        const Icon(Icons.archive_rounded, size: 14),
                      ]
                    : [
                        Timeago(
                          date: card.createdAt,
                          locale: context.locale.toString(),
                          builder: (context, timeAgo) => Text(timeAgo, style: TextStyle(fontSize: 12)),
                        ),
                        const Icon(Icons.access_time_rounded, size: 14),
                      ],
              ),
              if (showListName)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 6,
                  children: [
                    Flexible(
                      child: Text(
                        card.list.name,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.list_rounded, size: 14),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
