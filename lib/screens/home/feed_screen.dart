import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:timeago_flutter/timeago_flutter.dart';

import '../../build_context.dart';
import '../../components.dart';
import '../../components/card_item.dart';
import '../../components/user_item.dart';
import '../../constants.dart';
import '../../graphql/queries/activities.graphql.dart';
import '../../graphql/schema.graphql.dart';
import '../../sessions_manager.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  bool _includeGlobal = !SessionsManager.hasToken;

  @override
  Widget build(BuildContext context) {
    return Query$Activities$Widget(
      options: Options$Query$Activities(
        cacheRereadPolicy: CacheRereadPolicy.ignoreOptimisitic,
        variables: Variables$Query$Activities(first: 12, includeGlobal: _includeGlobal),
      ),
      builder: (result, {fetchMore, refetch}) {
        final hasNextPage = result.parsedData?.activities.pageInfo.hasNextPage ?? false;
        final endCursor = result.parsedData?.activities.pageInfo.endCursor;

        return InfiniteScrollView(
          hasMore: hasNextPage,
          onScrollAtBottom: () async {
            await fetchMore?.call(
              FetchMoreOptions$Query$Activities(
                variables: Variables$Query$Activities(after: endCursor, includeGlobal: _includeGlobal),
                updateQuery: (previousResultData, fetchMoreResultData) {
                  if (fetchMoreResultData == null || fetchMoreResultData['activities']['nodes'].length == 0) {
                    return previousResultData;
                  }

                  fetchMoreResultData['activities']['nodes'] = [
                    ...previousResultData?['activities']['nodes'],
                    ...fetchMoreResultData['activities']['nodes']
                        .where(
                          (node) =>
                              previousResultData?['activities']['nodes']
                                  .map((node1) => node1['id'])
                                  .contains(node['id']) !=
                              true,
                        )
                        .toList(),
                  ];

                  return fetchMoreResultData;
                },
              ),
            );
          },
          child: Column(
            spacing: 12,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.l10n.feed, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  if (SessionsManager.hasToken)
                    SegmentedButton(
                      selected: {_includeGlobal},
                      onSelectionChanged: (Set<bool> selected) {
                        setState(() {
                          _includeGlobal = selected.first;
                        });
                      },
                      segments: [
                        ButtonSegment(icon: Icon(Icons.public_rounded), tooltip: context.l10n.global, value: true),
                        ButtonSegment(icon: Icon(Icons.person_rounded), tooltip: context.l10n.local, value: false),
                      ],
                    ),
                ],
              ),
              QueryResultBuilder(
                result: result,
                buildIf: (data) => data?.activities.nodes.isNotEmpty == true,
                refetch: refetch,
                builder: (data) => Center(
                  child: Column(
                    spacing: 8,
                    children: data.activities.nodes.map((activity) {
                      String actionText = '';

                      switch (activity.action) {
                        case Enum$ActivityAction.CREATE_BOARD:
                          actionText = context.l10n.hasCreatedABoard;
                          break;
                        case Enum$ActivityAction.UPDATE_BOARD:
                          actionText = context.l10n.hasModifiedABoard;
                          break;
                        case Enum$ActivityAction.CREATE_CARD:
                          actionText = context.l10n.hasAddedACardOn;
                          break;
                        case Enum$ActivityAction.UPDATE_CARD:
                          actionText = context.l10n.hasModifiedACardOn;
                          break;
                        case Enum$ActivityAction.UPDATE_CARD_LIST || Enum$ActivityAction.UPDATE_CARD_POSITION:
                          actionText = context.l10n.hasMovedACardOn;
                          break;
                        case Enum$ActivityAction.ARCHIVE_CARD:
                          actionText = context.l10n.hasArchivedACard;
                          break;
                        case Enum$ActivityAction.UNARCHIVE_CARD:
                          actionText = context.l10n.hasUnarchivedACard;
                          break;
                        case Enum$ActivityAction.DELETE_CARD:
                          actionText = context.l10n.hasDeletedACardOn;
                          break;
                        case Enum$ActivityAction.CREATE_LIST:
                          actionText = context.l10n.hasAddedAListOn;
                          break;
                        case Enum$ActivityAction.UPDATE_LIST || Enum$ActivityAction.UPDATE_LIST_POSITION:
                          actionText = context.l10n.hasModifiedAListOn;
                          break;
                        case Enum$ActivityAction.DELETE_LIST:
                          actionText = context.l10n.hasDeletedAListOn;
                          break;
                        default:
                          break;
                      }

                      return Container(
                        width: 640,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: borderRadius,
                        ),
                        child: Column(
                          spacing: 12,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              spacing: 12,
                              children: [
                                UserItem(
                                  user: activity.user,
                                  onTap: () => activity.user != null ? context.router.pushToUser(activity.user!) : null,
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      spacing: 12,
                                      children: [
                                        Flexible(child: Text(actionText, overflow: TextOverflow.ellipsis, maxLines: 1)),
                                        if (![
                                          Enum$ActivityAction.CREATE_BOARD,
                                          Enum$ActivityAction.UPDATE_BOARD,
                                        ].contains(activity.action))
                                          Flexible(
                                            child: InkWell(
                                              onTap: () => context.router.pushToBoard(activity.board),
                                              child: Text(
                                                activity.board.name,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    Timeago(
                                      date: activity.createdAt,
                                      locale: context.locale.toString(),
                                      builder: (context, timeAgo) => Text(timeAgo, style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (activity.cardData != null)
                              CardItem(
                                card: activity.cardData!,
                                showListName: true,
                                showPopupMenu: false,
                                onTap: () {
                                  context.router.pushToBoard(activity.board);
                                  context.router.pushToCard(activity.cardData!);
                                },
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
