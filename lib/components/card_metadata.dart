import 'package:flutter/material.dart';
import 'package:timeago_flutter/timeago_flutter.dart';

import '../build_context.dart';
import '../graphql/fragments/card_fragment.graphql.dart';
import 'user_item.dart';

class CardMetadata extends StatelessWidget {
  const CardMetadata({super.key, required this.card, this.showListName = false});

  final Fragment$CardFragment card;
  final bool showListName;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        spacing: 6,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserItem(user: card.user, onTap: card.user != null ? () => context.router.pushToUser(card.user!) : null),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 3,
            children: [
              Row(
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
                  spacing: 6,
                  children: [
                    Text(card.list.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const Icon(Icons.list_rounded, size: 14),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
