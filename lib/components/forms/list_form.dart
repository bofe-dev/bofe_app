import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../build_context.dart';
import '../../graphql/fragments/list_fragment.graphql.dart';
import '../../graphql_client.dart';
import 'form_container.dart';
import 'switch_field.dart';
import 'text_input_field.dart';

class ListForm<T> extends StatefulWidget {
  const ListForm({super.key, required this.formKey, this.initialValues, required this.onSubmit});

  final GlobalKey<FormState> formKey;
  final Fragment$ListFragment? initialValues;
  final Future<QueryResult<T>> Function(String name, bool archiveCards) onSubmit;

  @override
  State<ListForm> createState() => _ListFormState();
}

class _ListFormState<T> extends State<ListForm<T>> {
  String _name = '';
  bool _archiveCards = false;
  String? _errorName;

  @override
  void initState() {
    super.initState();
    if (widget.initialValues != null) {
      _name = widget.initialValues!.name;
      _archiveCards = widget.initialValues!.archiveCards;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormContainer(
      formKey: widget.formKey,
      onSubmit: () async {
        final result = await widget.onSubmit(_name, _archiveCards);

        if (result.hasErrors) {
          setState(() {
            _errorName = result.getParamError('name');
          });

          return result.errorMessage;
        }

        return null;
      },
      fields: [
        TextInputField(
          labelText: 'Name',
          errorText: _errorName,
          initialValue: _name,
          required: true,
          maxLines: 1,
          onSaved: (value) {
            _name = value ?? '';
          },
        ),
        SwitchField(
          labelText: context.l10n.archiveCards,
          initialValue: _archiveCards,
          onSaved: (value) {
            _archiveCards = value == true;
          },
        ),
      ],
    );
  }
}
