import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../build_context.dart';
import '../components.dart';
import '../components/board_context.dart';
import '../components/dialogs/select_dialog.dart';
import '../components/label_chip.dart';
import '../components/list_item.dart';
import '../components/loading_overlay.dart';
import '../components/new_list_dialog.dart';
import '../components/screen_title.dart';
import '../config.dart';
import '../graphql/fragments/board_fragment.graphql.dart';
import '../graphql/fragments/label_fragment.graphql.dart';
import '../graphql/mutations/delete_board.graphql.dart';
import '../graphql/queries/board_labels.graphql.dart';
import '../graphql/subscriptions/board.graphql.dart';
import '../screens/not_found_screen.dart';
import '../value_keys.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key, required this.username, required this.slug});

  final String username;
  final String slug;

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  String? _draggingListId;
  bool _isDraggingCard = false;
  final _scrollController = ScrollController();
  bool _isAnimating = false;
  final _pixelsPerSecond = 250.0;
  final _edgeThreshold = 50;
  List<Fragment$LabelFragment> _labels = [];

  Future<void> _attemptToDeleteBoard(String id) async {
    final loadingOverlay = showLoadingOverlay(context);
    final result = await context.graphQLClient.mutate$DeleteBoard(
      Options$Mutation$DeleteBoard(variables: Variables$Mutation$DeleteBoard(id: id)),
    );

    if (!mounted) {
      return;
    }

    if (result.parsedData?.deleteBoard == true) {
      context.pop();
    } else {
      final errors = result.exception?.graphqlErrors.first;

      showSnackBarAlert(context, errors?.message ?? 'Failed to delete board');
    }

    loadingOverlay.hide();
  }

  List<Widget> _getActions(Fragment$BoardFragment board) {
    return [
      IconButton(
        onPressed: () async {
          final labels = await showSelectDialog<Fragment$LabelFragment>(
            context,
            options: (_) async {
              return (await context.graphQLClient.query$BoardLabels(
                    Options$Query$BoardLabels(variables: Variables$Query$BoardLabels(id: board.id)),
                  )).parsedData?.board?.allLabels ??
                  [];
            },
            selected: _labels,
            filterFn: (option, filter) => option.name.toLowerCase().contains(filter.toLowerCase()),
            optionBuilder: (option) => LabelChip(label: option),
            isMulti: true,
          );

          if (labels != null) {
            setState(() {
              _labels = labels;
            });
          }
        },
        tooltip: context.l10n.filter,
        icon: Icon(Icons.filter_alt_rounded),
      ),
      IconButton(
        onPressed: () {
          SharePlus.instance.share(ShareParams(uri: Config.appUrl.replace(path: '/${widget.username}/${widget.slug}')));
        },
        tooltip: context.l10n.share,
        icon: Icon(Icons.share_rounded),
      ),
      MenuAnchor(
        builder: (context, controller, child) => IconButton(
          onPressed: () => controller.isOpen ? controller.close() : controller.open(),
          icon: const Icon(Icons.more_vert_rounded),
          tooltip: context.l10n.more,
        ),
        menuChildren: [
          MenuItemButton(
            onPressed: () => context.router.pushToMembers(board),
            leadingIcon: Icon(Icons.groups_3_rounded),
            child: Text(context.l10n.members),
          ),
          if (board.isEditable) ...[
            MenuItemButton(
              onPressed: () => showEditBoardDialog(context, board: board),
              leadingIcon: const Icon(Icons.edit_rounded),
              child: Text(context.l10n.edit),
            ),
            MenuItemButton(
              onPressed: () => context.router.goToLabels(board),
              leadingIcon: const Icon(Icons.label_rounded),
              child: Text(context.l10n.labels),
            ),
            MenuItemButton(
              onPressed: () => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm your action'),
                  content: const Text('Are you sure you want to delete this board?'),
                  actions: [
                    OutlinedButton(child: Text(context.l10n.cancel), onPressed: () => context.pop()),
                    FilledButton(
                      child: Text(context.l10n.confirm),
                      onPressed: () {
                        context.pop();
                        _attemptToDeleteBoard(board.id);
                      },
                    ),
                  ],
                ),
              ),
              leadingIcon: const Icon(Icons.delete_rounded),
              child: Text(context.l10n.delete),
            ),
          ],
        ],
      ),
    ];
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_isDraggingCard || _draggingListId != null) {
      final pointerPosition = event.localPosition;

      if (!_isAnimating) {
        if (pointerPosition.dx <= _edgeThreshold) {
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
            pointerPosition.dx >= _scrollController.position.viewportDimension - _edgeThreshold) {
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
      } else if (pointerPosition.dx > _edgeThreshold &&
          pointerPosition.dx < _scrollController.position.viewportDimension - _edgeThreshold) {
        setState(() {
          _isAnimating = false;
        });

        _scrollController.jumpTo(_scrollController.offset);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BoardContext(
      key: ValueKeys.boardContext(widget.username, widget.slug),
      username: widget.username,
      slug: widget.slug,
      builder: (board) {
        return ScreenTitle(
          title: '${board.name} by @${board.user.username}',
          child: Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(board.name),
                  Text('by @${board.user.username}', style: TextStyle(fontSize: 12)),
                ],
              ),
              actions: _getActions(board),
            ),
            body: SafeArea(
              child: Subscription$Board$Widget(
                options: Options$Subscription$Board(variables: Variables$Subscription$Board(id: board.id)),
                builder: (result) {
                  final board = result.parsedData?.board;

                  if (board == null) {
                    if (result.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else {
                      return const NotFoundScreen();
                    }
                  }

                  return Listener(
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
                    child: SizedBox(
                      height: double.infinity,
                      width: double.infinity,
                      child: Scrollbar(
                        controller: _scrollController,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(16),
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: _draggingListId == null ? 12 : 0,
                            children:
                                board.allLists
                                    .map(
                                      (list) => board.canMoveList
                                          ? [
                                              ListItemDragTarget(
                                                position: list.position,
                                                isVisible: _draggingListId != null && _draggingListId != list.id,
                                              ),
                                              DraggableListItem(
                                                board: board,
                                                list: list,
                                                labels: _labels,
                                                isDraggingCard: _isDraggingCard,
                                                onDragOutside: () {
                                                  setState(() {
                                                    _draggingListId = list.id;
                                                  });
                                                },
                                                onDragEnded: () {
                                                  setState(() {
                                                    _draggingListId = null;
                                                  });
                                                },
                                                onCardDragOutside: () {
                                                  setState(() {
                                                    _isDraggingCard = true;
                                                  });
                                                },
                                                onCardDragEnded: () {
                                                  setState(() {
                                                    _isDraggingCard = false;
                                                  });
                                                },
                                              ),
                                            ]
                                          : [
                                              ListItem(
                                                key: ValueKey(list.id),
                                                board: board,
                                                list: list,
                                                labels: _labels,
                                                isDraggingCard: _isDraggingCard,
                                                onCardDragOutside: () {
                                                  setState(() {
                                                    _isDraggingCard = true;
                                                  });
                                                },
                                                onCardDragEnded: () {
                                                  setState(() {
                                                    _isDraggingCard = false;
                                                  });
                                                },
                                              ),
                                            ],
                                    )
                                    .expand((item) => item)
                                    .toList() +
                                [
                                  if (board.canMoveList)
                                    ListItemDragTarget(
                                      position: board.allLists.lastOrNull?.position != null
                                          ? board.allLists.lastOrNull!.position + 1
                                          : 0,
                                      isVisible: _draggingListId != null,
                                    ),
                                  if (board.canCreateList)
                                    SizedBox(
                                      width: 320,
                                      child: OutlinedButton(
                                        onPressed: () => showNewListDialog(context, boardId: board.id),
                                        child: Text('NEW LIST'),
                                      ),
                                    ),
                                ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
