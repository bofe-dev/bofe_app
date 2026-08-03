import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../build_context.dart';
import '../../components/cached_image_attachment.dart';
import '../../components/card_menu_anchor.dart';
import '../../components/card_metadata.dart';
import '../../components/dialogs/card_attachment_dialog.dart';
import '../../components/label_chip.dart';
import '../../components/query_result_builder.dart';
import '../../components/scrollable_dialog.dart';
import '../../components/thumbnail_item.dart';
import '../../constants.dart';
import '../../graphql/fragments/board_fragment.graphql.dart';
import '../../graphql/queries/card.graphql.dart';

class CardDialogScreen extends StatelessWidget {
  const CardDialogScreen({super.key, required this.board, required this.id});

  final Fragment$BoardFragment board;
  final String id;

  @override
  Widget build(BuildContext context) {
    return ScrollableDialog(
      padding: const EdgeInsets.all(0),
      child: Query$Card$Widget(
        options: Options$Query$Card(variables: Variables$Query$Card(id: id)),
        builder: (result, {fetchMore, refetch}) {
          return QueryResultBuilder(
            result: result,
            refetch: refetch,
            loadingWidget: const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            buildIf: (parsedData) => parsedData?.card?.board.id == board.id,
            builder: (parsedData) {
              final card = parsedData.card!;

              return Column(
                spacing: 8,
                children: [
                  if (card.coverImageAttachment?.thumbnailUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.only(topLeft: borderRadius.topLeft, topRight: borderRadius.topRight),
                      child: AspectRatio(
                        aspectRatio: 16 / 5,
                        child: CachedImageAttachment.thumbnailLarge(
                          attachment: card.coverImageAttachment!,
                          width: 640,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      spacing: 8,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          spacing: 6,
                          children: [
                            Expanded(
                              child: CardMetadata(
                                card: card,
                                showListName: true,
                                onUserTap: card.user != null ? () => context.router.pushToUser(card.user!) : null,
                              ),
                            ),
                            CardMenuAnchor(
                              card: card,
                              beforeEdit: () {
                                context.pop();
                              },
                              afterArchive: () {
                                refetch?.call();
                              },
                              afterDelete: () {
                                context.pop();
                              },
                            ),
                          ],
                        ),
                        MarkdownBody(
                          data: card.content,
                          selectable: true,
                          softLineBreak: true,
                          styleSheet: MarkdownStyleSheet(textScaler: TextScaler.linear(1.3)),
                          onTapLink: (text, href, title) async {
                            if (href != null && await canLaunchUrlString(href)) {
                              launchUrlString(href, mode: LaunchMode.inAppBrowserView);
                            }
                          },
                        ),
                        if (card.attachmentsCount > 0)
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: card.allAttachments
                                .map(
                                  (attachment) => InkWell(
                                    onTap: () => showCardAttachmentDialog(context, cardId: id, id: attachment.id),
                                    child: ThumbnailItem(attachment: attachment),
                                  ),
                                )
                                .toList(),
                          ),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: card.allLabels.map((label) => LabelChip(label: label)).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
