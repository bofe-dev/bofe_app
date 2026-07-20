import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../build_context.dart';
import '../../graphql/fragments/attachment_fragment.graphql.dart';
import '../../graphql_client.dart';
import '../label_chip.dart';
import '../../graphql/fragments/label_fragment.graphql.dart';
import '../../graphql/fragments/list_fragment.graphql.dart';
import '../../graphql/fragments/edit_card_fragment.graphql.dart';
import '../../graphql/queries/board_labels.graphql.dart';
import '../../graphql/queries/board_lists.graphql.dart';
import '../../graphql/schema.graphql.dart';
import 'file_picker_field.dart';
import 'form_container.dart';
import 'image_picker_field.dart';
import 'select_field.dart';
import 'text_input_field.dart';

class CardForm<T> extends StatefulWidget {
  const CardForm({
    super.key,
    required this.formKey,
    required this.boardId,
    this.initialList,
    this.initialValues,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final String boardId;
  final Fragment$ListFragment? initialList;
  final Fragment$EditCardFragment? initialValues;
  final Future<QueryResult<T>> Function(Input$CardParams params) onSubmit;

  @override
  State<CardForm> createState() => _CardFormState();
}

class _CardFormState<T> extends State<CardForm<T>> {
  Fragment$ListFragment? _list;
  Fragment$AttachmentFragment? _coverImageAttachment;
  String _content = '';
  List<Fragment$AttachmentFragment> _attachments = [];
  List<Fragment$LabelFragment> _labels = [];
  String? _errorList;
  String? _errorCoverImageAttachment;
  String? _errorContent;
  String? _errorAttachments;
  String? _errorLabels;

  @override
  void initState() {
    super.initState();

    _coverImageAttachment = widget.initialValues?.coverImageAttachment;
    _content = widget.initialValues?.content ?? '';
    _list = widget.initialValues?.list ?? widget.initialList;
    _attachments = widget.initialValues?.allAttachments ?? [];
    _labels = widget.initialValues?.allLabels ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return FormContainer(
      formKey: widget.formKey,
      onSubmit: () async {
        final result = await widget.onSubmit(
          Input$CardParams(
            listId: _list!.id,
            coverImageAttachmentId: _coverImageAttachment?.id,
            content: _content,
            attachmentIds: _attachments.map((attachment) => attachment.id).toList(),
            labelIds: _labels.map((label) => label.id).toList(),
          ),
        );

        if (result.hasErrors) {
          setState(() {
            _errorList = result.getParamError('listId');
            _errorCoverImageAttachment = result.getParamError('coverImageAttachmentId');
            _errorContent = result.getParamError('content');
            _errorAttachments = result.getParamError('attachmentIds');
            _errorLabels = result.getParamError('labelIds');
          });

          return result.errorMessage;
        }

        return null;
      },
      fields: [
        Query$BoardLists$Widget(
          options: Options$Query$BoardLists(variables: Variables$Query$BoardLists(id: widget.boardId)),
          builder: (result, {refetch, fetchMore}) => SelectField<Fragment$ListFragment>(
            labelText: 'List',
            errorText: _errorList,
            initialValue: _list,
            required: true,
            filterFn: (option, filter) => option.name.toLowerCase().contains(filter.toLowerCase()),
            optionBuilder: (item) => Text(item.name),
            options: result.parsedData?.board?.allLists.where((list) => list.canMoveCard).toList() ?? [],
            onSaved: (list) {
              setState(() {
                _list = list;
              });
            },
          ),
        ),
        ImagePickerField(
          labelText: context.l10n.coverImage,
          errorText: _errorCoverImageAttachment,
          initialValue: _coverImageAttachment,
          onSaved: (value) {
            setState(() {
              _coverImageAttachment = value;
            });
          },
        ),
        TextInputField(
          labelText: 'Content',
          errorText: _errorContent,
          keyboardType: TextInputType.multiline,
          initialValue: _content,
          required: true,
          minLines: 4,
          maxLines: 100,
          onSaved: (value) {
            _content = value ?? '';
          },
        ),
        FilePickerField.multi(
          labelText: context.l10n.attachments,
          errorText: _errorAttachments,
          initialValue: _attachments,
          onSaved: (values) {
            setState(() {
              _attachments = values ?? [];
            });
          },
        ),
        Query$BoardLabels$Widget(
          options: Options$Query$BoardLabels(variables: Variables$Query$BoardLabels(id: widget.boardId)),
          builder: (result, {refetch, fetchMore}) => SelectField<Fragment$LabelFragment>.multi(
            labelText: 'Labels',
            errorText: _errorLabels,
            initialValue: _labels,
            filterFn: (option, filter) => option.name.toLowerCase().contains(filter.toLowerCase()),
            options: result.parsedData?.board?.allLabels ?? [],
            optionBuilder: (option) => LabelChip(label: option),
            onSaved: (values) {
              setState(() {
                _labels = values ?? [];
              });
            },
          ),
        ),
      ],
    );
  }
}
