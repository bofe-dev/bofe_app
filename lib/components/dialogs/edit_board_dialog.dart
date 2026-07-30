import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../build_context.dart';
import '../../graphql/schema.graphql.dart';
import '../../graphql/fragments/board_context_fragment.graphql.dart';
import '../../graphql/mutations/update_board.graphql.dart';
import '../forms/board_form.dart';
import '../snack_bar_alert.dart';

Future<dynamic> showEditBoardDialog(BuildContext context, {required Fragment$BoardContextFragment board}) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Edit Board'),
        content: _EditBoardForm(board: board),
      );
    },
  );
}

class _EditBoardForm extends StatelessWidget {
  _EditBoardForm({required this.board});

  final Fragment$BoardContextFragment board;

  final _formEditBoard = GlobalKey<FormState>();

  Future<QueryResult<Mutation$UpdateBoard>> _attemptToUpdateBoard(
    BuildContext context,
    Input$BoardParams params,
  ) async {
    final result = await context.graphQLClient.mutate$UpdateBoard(
      Options$Mutation$UpdateBoard(
        variables: Variables$Mutation$UpdateBoard(id: board.id, params: params),
      ),
    );

    if (!context.mounted) {
      return result;
    }

    final updatedBoard = result.parsedData?.updateBoard;

    if (updatedBoard != null) {
      showSnackBarAlert(context, 'Board updated successfully');

      if (board.slug == updatedBoard.slug) {
        context.pop();
      } else {
        context.pop();
        context.router.goToBoard(updatedBoard);
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return BoardForm(
      formKey: _formEditBoard,
      initialValues: board,
      onSubmit: (params) => _attemptToUpdateBoard(context, params),
    );
  }
}
