import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../build_context.dart';
import '../constants.dart';
import '../graphql/fragments/card_item_fragment.graphql.dart';
import '../graphql/mutations/update_card_list.graphql.dart';
import '../graphql/mutations/update_card_position.graphql.dart';
import 'card_menu_anchor.dart';
import 'card_metadata.dart';
import 'label_chip.dart';
import 'loading_overlay.dart';
import 'snack_bar_alert.dart';

class DraggableCardItem extends StatefulWidget {
  const DraggableCardItem({super.key, required this.card, required this.onDragOutside, required this.onDragEnded});

  final Fragment$CardItemFragment card;
  final Function() onDragOutside;
  final Function() onDragEnded;

  @override
  State<DraggableCardItem> createState() => _DraggableCardItemState();
}

class _DraggableCardItemState extends State<DraggableCardItem> {
  final GlobalKey _cardItemSizeKey = GlobalKey();
  Size? _cardItemSize;
  Offset? _initialOffset;
  bool _isOutside = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox = _cardItemSizeKey.currentContext?.findRenderObject() as RenderBox;

      setState(() {
        _cardItemSize = renderBox.size;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable(
      data: widget.card,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.5,
          child: CardItem(key: ValueKey(widget.card.id), card: widget.card),
        ),
      ),
      childWhenDragging: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: _isOutside ? 0 : _cardItemSize?.height,
        decoration: BoxDecoration(color: Colors.grey.withAlpha(192), borderRadius: BorderRadius.circular(16)),
      ),
      onDragUpdate: (details) {
        final currentOffset = details.globalPosition;
        _initialOffset ??= currentOffset;

        if (!_isOutside &&
            (currentOffset.dx > _initialOffset!.dx + 80 ||
                currentOffset.dx < _initialOffset!.dx - 80 ||
                currentOffset.dy > _initialOffset!.dy + 30 ||
                currentOffset.dy < _initialOffset!.dy - 30)) {
          setState(() {
            _isOutside = true;
          });

          widget.onDragOutside();
        }
      },
      onDraggableCanceled: (velocity, offset) {
        setState(() {
          _initialOffset = null;
          _isOutside = false;
        });
        widget.onDragEnded();
      },
      onDragEnd: (details) {
        setState(() {
          _initialOffset = null;
          _isOutside = false;
        });
        widget.onDragEnded();
      },
      child: SizedBox(
        key: _cardItemSizeKey,
        child: CardItem(key: ValueKey(widget.card.id), card: widget.card),
      ),
    );
  }
}

class CardItem extends StatelessWidget {
  const CardItem({super.key, required this.card, this.showListName = false, this.onTap});

  final Fragment$CardItemFragment card;
  final bool showListName;
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        color: colorScheme.onInverseSurface,
        borderRadius: borderRadius,
      ),
      child: Stack(
        children: [
          Column(
            spacing: 6,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (card.coverImageAttachment?.thumbnailUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.only(topLeft: borderRadius.topLeft, topRight: borderRadius.topRight),
                  child: CachedNetworkImage(
                    useOldImageOnUrlChange: true,
                    imageUrl: card.coverImageAttachment!.thumbnailUrl.toString(),
                    width: 320,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  spacing: 6,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      spacing: 6,
                      children: [
                        CardMetadata(card: card, showListName: showListName),
                        CardMenuAnchor(card: card, iconSize: 20),
                      ],
                    ),
                    Text(card.content, maxLines: 3, overflow: TextOverflow.fade, style: TextStyle(fontSize: 16)),
                    if (card.attachmentsCount > 0)
                      Row(
                        spacing: 2,
                        children: [Text(card.attachmentsCount.toString()), Icon(Icons.attach_file_rounded, size: 16)],
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
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(borderRadius: borderRadius, onTap: onTap ?? () => context.router.pushToCard(card)),
            ),
          ),
        ],
      ),
    );
  }
}

class CardItemDragTarget extends StatelessWidget {
  const CardItemDragTarget({super.key, required this.listId, required this.position, required this.isVisible});

  final String listId;
  final int position;
  final bool isVisible;

  Future<void> _attemptToUpdateCardPosition(BuildContext context, Fragment$CardItemFragment card, int position) async {
    int newPosition = position;

    if (card.position < position) {
      newPosition = position - 1;
    }

    if (card.position == newPosition) {
      return;
    }

    final loadingOverlay = showLoadingOverlay(context);

    final result = await context.graphQLClient.mutate$UpdateCardPosition(
      Options$Mutation$UpdateCardPosition(
        variables: Variables$Mutation$UpdateCardPosition(id: card.id, position: newPosition),
      ),
    );

    if (result.parsedData?.updateCardPosition == null && context.mounted) {
      showSnackBarAlert(context, 'Failed to update card position');
    }

    loadingOverlay.hide();
  }

  Future<void> _attemptToUpdateCardList(
    BuildContext context,
    Fragment$CardItemFragment card,
    String listId,
    int position,
  ) async {
    final loadingOverlay = showLoadingOverlay(context);

    final result = await context.graphQLClient.mutate$UpdateCardList(
      Options$Mutation$UpdateCardList(
        variables: Variables$Mutation$UpdateCardList(id: card.id, listId: listId, position: position),
      ),
    );

    if (result.parsedData?.updateCardList == null && context.mounted) {
      showSnackBarAlert(context, 'Failed to update card list');
    }

    loadingOverlay.hide();
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: isVisible,
      child: DragTarget<Fragment$CardItemFragment>(
        builder: (context, accepted, rejected) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(vertical: 6),
            height: accepted.isNotEmpty ? 92 : 12,
            decoration: BoxDecoration(
              color: accepted.isNotEmpty ? Colors.grey.withAlpha(192) : Colors.grey.withAlpha(128),
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
        onAcceptWithDetails: (details) {
          final card = details.data;

          if (listId == card.list.id) {
            _attemptToUpdateCardPosition(context, card, position);
          } else {
            _attemptToUpdateCardList(context, card, listId, position);
          }
        },
      ),
    );
  }
}
