import 'package:flutter/material.dart';

import '../graphql/fragments/board_item_fragment.graphql.dart';
import 'board_item.dart';

class BoardsGridView extends StatelessWidget {
  const BoardsGridView({super.key, required this.boards});

  final List<Fragment$BoardItemFragment> boards;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    late final int columns;

    if (screenWidth < 640) {
      columns = 2;
    } else if (screenWidth < 1024) {
      columns = 3;
    } else {
      columns = 4;
    }

    return Center(
      child: SizedBox(
        width: 1300,
        child: GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: boards.length,
          itemBuilder: (context, index) {
            final board = boards[index];

            return BoardItem(board: board);
          },
        ),
      ),
    );
  }
}
