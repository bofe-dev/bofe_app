import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../build_context.dart';
import '../graphql/schema.graphql.dart';
import '../graphql/mutations/create_list.graphql.dart';
import 'forms/list_form.dart';

Future<dynamic> showNewListDialog(BuildContext context, {required boardId}) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('New List'),
        content: _NewListForm(boardId: boardId),
      );
    },
  );
}

class _NewListForm extends StatefulWidget {
  const _NewListForm({required this.boardId});

  final String boardId;

  @override
  _NewListFormState createState() => _NewListFormState();
}

class _NewListFormState extends State<_NewListForm> {
  final _formNewList = GlobalKey<FormState>();

  Future<QueryResult<Mutation$CreateList>> _attemptToCreateList(
    BuildContext context,
    String name,
    bool archiveCards,
  ) async {
    final result = await context.graphQLClient.mutate$CreateList(
      Options$Mutation$CreateList(
        variables: Variables$Mutation$CreateList(
          params: Input$ListParams(boardId: widget.boardId, name: name, archiveCards: archiveCards),
        ),
      ),
    );

    if (!context.mounted) {
      return result;
    }

    if (result.parsedData?.createList != null) {
      context.pop();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return ListForm(
      formKey: _formNewList,
      onSubmit: (name, archiveCards) => _attemptToCreateList(context, name, archiveCards),
    );
  }
}
