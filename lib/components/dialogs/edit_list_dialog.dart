import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../build_context.dart';
import '../../graphql/schema.graphql.dart';
import '../../graphql/fragments/list_fragment.graphql.dart';
import '../../graphql/mutations/update_list.graphql.dart';
import '../forms/list_form.dart';

Future<dynamic> showEditListDialog(BuildContext context, {required Fragment$ListFragment list}) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Edit List'),
        content: _EditListForm(list: list),
      );
    },
  );
}

class _EditListForm extends StatelessWidget {
  _EditListForm({required this.list});

  final Fragment$ListFragment list;

  final _formEditList = GlobalKey<FormState>();

  Future<QueryResult<Mutation$UpdateList>> _attemptToUpdateList(
    BuildContext context,
    String name,
    bool archiveCards,
  ) async {
    final result = await context.graphQLClient.mutate$UpdateList(
      Options$Mutation$UpdateList(
        variables: Variables$Mutation$UpdateList(
          id: list.id,
          params: Input$UpdateListParams(name: name, archiveCards: archiveCards),
        ),
      ),
    );

    if (!context.mounted) {
      return result;
    }

    if (result.parsedData?.updateList != null) {
      context.pop();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return ListForm(
      formKey: _formEditList,
      initialValues: list,
      onSubmit: (name, archiveCards) => _attemptToUpdateList(context, name, archiveCards),
    );
  }
}
