import 'dart:async';

import 'package:bofe/components/dialogs/new_card_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../build_context.dart';
import '../components/loading_overlay.dart';
import '../graphql/fragments/board_fragment.graphql.dart';
import '../graphql/fragments/label_fragment.graphql.dart';
import '../graphql/fragments/list_with_cards_fragment.graphql.dart';
import '../graphql/mutations/delete_list.graphql.dart';
import '../graphql/mutations/update_list_position.graphql.dart';
import 'card_item.dart';
import 'dialogs/edit_list_dialog.dart';
import 'snack_bar_alert.dart';

class DraggableListItem extends StatefulWidget {
  const DraggableListItem({
    super.key,
    required this.board,
    required this.list,
    required this.labels,
    required this.isDraggingCard,
    required this.onDragOutside,
    required this.onDragEnded,
    required this.onCardDragOutside,
    required this.onCardDragEnded,
  });

  final Fragment$BoardFragment board;
  final Fragment$ListWithCardsFragment list;
  final List<Fragment$LabelFragment> labels;
  final bool isDraggingCard;
  final Function() onDragOutside;
  final Function() onDragEnded;
  final Function() onCardDragOutside;
  final Function() onCardDragEnded;

  @override
  State<DraggableListItem> createState() => _DraggableListItemState();
}

class _DraggableListItemState extends State<DraggableListItem> {
  final GlobalKey _listItemSizeKey = GlobalKey();
  Size? _listItemSize;
  double? _initialX;
  bool _isOutside = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox = _listItemSizeKey.currentContext?.findRenderObject() as RenderBox;

      setState(() {
        _listItemSize = renderBox.size;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable(
      data: widget.list,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.50,
          child: SizedBox(
            height: _listItemSize?.height,
            child: ListItem(
              key: ValueKey(widget.list.id),
              board: widget.board,
              list: widget.list,
              labels: widget.labels,
              isDraggingCard: false,
            ),
          ),
        ),
      ),
      childWhenDragging: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: _isOutside ? 0 : _listItemSize?.width,
        decoration: BoxDecoration(color: Colors.grey.withAlpha(192), borderRadius: BorderRadius.circular(16)),
      ),
      onDragUpdate: (details) {
        final currentX = details.globalPosition.dx;
        _initialX ??= currentX;

        if (!_isOutside && (currentX > _initialX! + 100 || currentX < _initialX! - 100)) {
          setState(() {
            _isOutside = true;
          });

          widget.onDragOutside();
        }
      },
      onDraggableCanceled: (velocity, offset) {
        setState(() {
          _initialX = null;
          _isOutside = false;
        });
        widget.onDragEnded();
      },
      onDragEnd: (details) {
        setState(() {
          _initialX = null;
          _isOutside = false;
        });
        widget.onDragEnded();
      },
      child: SizedBox(
        key: _listItemSizeKey,
        child: ListItem(
          key: ValueKey(widget.list.id),
          board: widget.board,
          list: widget.list,
          labels: widget.labels,
          isDraggingCard: widget.isDraggingCard,
          onCardDragOutside: widget.onCardDragOutside,
          onCardDragEnded: widget.onCardDragEnded,
        ),
      ),
    );
  }
}

class ListItem extends StatefulWidget {
  const ListItem({
    super.key,
    required this.board,
    required this.list,
    required this.labels,
    required this.isDraggingCard,
    this.onCardDragOutside,
    this.onCardDragEnded,
  });

  final Fragment$BoardFragment board;
  final Fragment$ListWithCardsFragment list;
  final List<Fragment$LabelFragment> labels;
  final bool isDraggingCard;
  final Function()? onCardDragOutside;
  final Function()? onCardDragEnded;

  @override
  State<ListItem> createState() => _ListItemState();
}

class _ListItemState extends State<ListItem> {
  String? _draggingCardId;
  final _scrollController = ScrollController();
  bool _isAnimating = false;
  final _pixelsPerSecond = 250.0;
  final _edgeThreshold = 50;

  Future<void> _attemptToDeleteList() async {
    final loadingOverlay = showLoadingOverlay(context);
    final result = await context.graphQLClient.mutate$DeleteList(
      Options$Mutation$DeleteList(variables: Variables$Mutation$DeleteList(id: widget.list.id)),
    );

    if (!mounted) {
      return;
    }

    if (result.parsedData?.deleteList != true) {
      final errors = result.exception?.graphqlErrors.first;

      showSnackBarAlert(context, errors?.message ?? 'Failed to delete list');
    }

    loadingOverlay.hide();
  }

  void _onPointerMove(PointerMoveEvent event) {
    if ((widget.isDraggingCard || _draggingCardId != null)) {
      final pointerPosition = event.localPosition;

      if (!_isAnimating) {
        if (pointerPosition.dy <= _edgeThreshold) {
          setState(() {
            _isAnimating = true;
          });
          final minExtent = _scrollController.position.minScrollExtent;
          final distanceToScroll = (_scrollController.offset - minExtent).abs();
          final durationMs = ((distanceToScroll / _pixelsPerSecond) * 1000).round();

          _scrollController.animateTo(
            minExtent,
            duration: Duration(milliseconds: durationMs),
            curve: Curves.easeInOut,
          );
        } else if (!_isAnimating &&
            pointerPosition.dy >= _scrollController.position.viewportDimension - _edgeThreshold) {
          setState(() {
            _isAnimating = true;
          });

          final maxExtent = _scrollController.position.maxScrollExtent;
          final distanceToScroll = (maxExtent - _scrollController.offset).abs();
          final durationMs = ((distanceToScroll / _pixelsPerSecond) * 1000).round();

          _scrollController.animateTo(
            maxExtent,
            duration: Duration(milliseconds: durationMs),
            curve: Curves.easeInOut,
          );
        }
      } else if (pointerPosition.dy > _edgeThreshold &&
          pointerPosition.dy < _scrollController.position.viewportDimension - _edgeThreshold) {
        setState(() {
          _isAnimating = false;
        });

        _scrollController.jumpTo(_scrollController.offset);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 344,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.onInverseSurface.withValues(alpha: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.list.name,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              widget.list.isEditable
                  ? PopupMenuButton(
                      icon: Icon(Icons.more_vert_rounded),
                      tooltip: 'More',
                      position: PopupMenuPosition.under,
                      onSelected: (value) {
                        switch (value) {
                          case 1:
                            showEditListDialog(context, list: widget.list);
                            break;
                          case 2:
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirm your action'),
                                content: const Text('Are you sure you want to delete this list?'),
                                actions: [
                                  OutlinedButton(child: const Text('Cancel'), onPressed: () => context.pop()),
                                  FilledButton(
                                    child: const Text('Confirm'),
                                    onPressed: () {
                                      context.pop();
                                      _attemptToDeleteList();
                                    },
                                  ),
                                ],
                              ),
                            );
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 1,
                          child: ListTile(leading: Icon(Icons.edit_rounded), title: Text('Edit')),
                        ),
                        PopupMenuItem(
                          value: 2,
                          child: ListTile(leading: Icon(Icons.delete_rounded), title: Text('Delete')),
                        ),
                      ],
                    )
                  : SizedBox(),
            ],
          ),
          Expanded(
            child: Listener(
              onPointerMove: _onPointerMove,
              onPointerUp: (event) {
                setState(() {
                  _isAnimating = false;
                });
              },
              onPointerCancel: (event) {
                setState(() {
                  _isAnimating = false;
                });
              },
              child: Scrollbar(
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    spacing: 8,
                    children:
                        widget.list.allCards
                            .where(
                              (card) =>
                                  widget.labels.isEmpty ||
                                  widget.labels.every(
                                    (label) => card.allLabels.map((label) => label.id).contains(label.id),
                                  ),
                            )
                            .map(
                              (card) => card.isMovable
                                  ? [
                                      CardItemDragTarget(
                                        listId: widget.list.id,
                                        position: card.position,
                                        isVisible: widget.isDraggingCard && _draggingCardId != card.id,
                                      ),
                                      DraggableCardItem(
                                        card: card,
                                        onDragOutside: () {
                                          setState(() {
                                            _draggingCardId = card.id;
                                          });
                                          widget.onCardDragOutside?.call();
                                        },
                                        onDragEnded: () {
                                          setState(() {
                                            _draggingCardId = null;
                                          });
                                          widget.onCardDragEnded?.call();
                                        },
                                      ),
                                    ]
                                  : [CardItem(key: ValueKey(card.id), card: card)],
                            )
                            .expand((item) => item)
                            .toList() +
                        [
                          if (widget.list.canMoveCard)
                            CardItemDragTarget(
                              listId: widget.list.id,
                              position: widget.list.allCards.lastOrNull?.position != null
                                  ? widget.list.allCards.lastOrNull!.position + 1
                                  : 0,
                              isVisible: widget.isDraggingCard,
                            ),
                        ],
                  ),
                ),
              ),
            ),
          ),
          if (widget.list.canCreateCard)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  showNewCardDialog(context, board: widget.board, list: widget.list);
                },
                child: Text('NEW CARD'),
              ),
            ),
        ],
      ),
    );
  }
}

class ListItemDragTarget extends StatelessWidget {
  const ListItemDragTarget({super.key, required this.position, required this.isVisible});

  final int position;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: isVisible,
      child: DragTarget<Fragment$ListWithCardsFragment>(
        builder: (context, accepted, rejected) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 12),
            width: accepted.isNotEmpty ? 344 : 16,
            decoration: BoxDecoration(
              color: accepted.isNotEmpty ? Colors.grey.withAlpha(192) : Colors.grey.withAlpha(128),
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
        onAcceptWithDetails: (details) async {
          final list = details.data;
          int newPosition = position;

          if (list.position < position) {
            newPosition = position - 1;
          }

          if (list.position == newPosition) {
            return;
          }

          final loadingOverlay = showLoadingOverlay(context);

          final result = await context.graphQLClient.mutate$UpdateListPosition(
            Options$Mutation$UpdateListPosition(
              variables: Variables$Mutation$UpdateListPosition(id: list.id, position: newPosition),
            ),
          );

          if (result.parsedData?.updateListPosition == null && context.mounted) {
            showSnackBarAlert(context, 'Failed to update list position');
          }

          loadingOverlay.hide();
        },
      ),
    );
  }
}
