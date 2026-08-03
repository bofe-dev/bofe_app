import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' show MultipartFile;
import 'package:http_parser/http_parser.dart' show MediaType;

import '../../build_context.dart';
import '../../config.dart';
import '../../constants.dart';
import '../../graphql/fragments/attachment_thumbnail_small_fragment.graphql.dart';
import '../../graphql/mutations/create_attachment.graphql.dart';
import '../thumbnail_item.dart';

const _acceptedTypeGroups = [
  XTypeGroup(label: 'PDF documents', extensions: ['pdf'], mimeTypes: ['application/pdf']),
  XTypeGroup(label: 'GIF images', extensions: ['gif'], mimeTypes: ['image/gif']),
  XTypeGroup(label: 'JPG images', extensions: ['jpeg', 'jpg'], mimeTypes: ['image/jpeg']),
  XTypeGroup(label: 'PNG images', extensions: ['png'], mimeTypes: ['image/png']),
  XTypeGroup(label: 'SVG images', extensions: ['svg'], mimeTypes: ['image/svg+xml']),
  XTypeGroup(label: 'WEBP images', extensions: ['webp'], mimeTypes: ['image/webp']),
  XTypeGroup(label: 'MP4 videos', extensions: ['mp4'], mimeTypes: ['video/mp4']),
  XTypeGroup(label: 'OGG videos', extensions: ['ogg'], mimeTypes: ['video/ogg']),
  XTypeGroup(label: 'WEBM videos', extensions: ['webm'], mimeTypes: ['video/webm']),
];

class FilePickerField extends StatefulWidget {
  FilePickerField({
    super.key,
    this.labelText,
    this.hintText,
    this.errorText,
    Fragment$AttachmentThumbnailSmallFragment? initialValue,
    this.required = false,
    FormFieldSetter<Fragment$AttachmentThumbnailSmallFragment>? onSaved,
    FormFieldValidator<Fragment$AttachmentThumbnailSmallFragment>? validator,
  }) : initialValue = _initialValueToMulti(initialValue),
       onSaved = _onSavedToMulti(onSaved),
       validator = _validatorToMulti(validator),
       isMulti = false;

  const FilePickerField.multi({
    super.key,
    this.labelText,
    this.hintText,
    this.errorText,
    this.initialValue = const [],
    this.required = false,
    this.onSaved,
    this.validator,
  }) : isMulti = true;

  final String? labelText;
  final String? hintText;
  final String? errorText;
  final List<Fragment$AttachmentThumbnailSmallFragment> initialValue;
  final bool required;
  final FormFieldSetter<List<Fragment$AttachmentThumbnailSmallFragment>>? onSaved;
  final FormFieldValidator<List<Fragment$AttachmentThumbnailSmallFragment>>? validator;
  final bool isMulti;

  static List<Fragment$AttachmentThumbnailSmallFragment> _initialValueToMulti(
    Fragment$AttachmentThumbnailSmallFragment? value,
  ) {
    return [?value];
  }

  static FormFieldSetter<List<Fragment$AttachmentThumbnailSmallFragment>>? _onSavedToMulti(
    FormFieldSetter<Fragment$AttachmentThumbnailSmallFragment>? onSaved,
  ) {
    return (value) => onSaved?.call(value?.firstOrNull);
  }

  static FormFieldValidator<List<Fragment$AttachmentThumbnailSmallFragment>>? _validatorToMulti(
    FormFieldValidator<Fragment$AttachmentThumbnailSmallFragment>? validator,
  ) {
    return (value) => validator?.call(value?.firstOrNull);
  }

  @override
  State<FilePickerField> createState() => _FilePickerFieldState();
}

class _FilePickerFieldState extends State<FilePickerField> {
  final List<XFile> _pendingXFiles = [];

  Future<void> _addFiles(FormFieldState<List<Fragment$AttachmentThumbnailSmallFragment>> state) async {
    final List<XFile> pickedXFiles = [];

    if (widget.isMulti) {
      pickedXFiles.addAll(await openFiles(acceptedTypeGroups: _acceptedTypeGroups));
    } else {
      final pickedXFile = await openFile(acceptedTypeGroups: _acceptedTypeGroups);

      if (pickedXFile != null) {
        pickedXFiles.add(pickedXFile);
      }
    }

    for (final xFile in pickedXFiles) {
      if ((await xFile.length()) > Config.maxFileSizeBytes) {
        continue;
      }

      setState(() {
        _pendingXFiles.add(xFile);
      });

      final file = MultipartFile.fromBytes(
        'file',
        await xFile.readAsBytes(),
        filename: xFile.name,
        contentType: xFile.mimeType != null ? MediaType.parse(xFile.mimeType!) : null,
      );

      if (!mounted) {
        return;
      }

      context.graphQLClient
          .mutate$CreateAttachment(
            Options$Mutation$CreateAttachment(variables: Variables$Mutation$CreateAttachment(file: file)),
          )
          .then((result) {
            final createdAttachment = result.parsedData?.createAttachment;

            if (createdAttachment != null &&
                state.value?.where((att) => att.id == createdAttachment.id).isNotEmpty != true) {
              state.didChange([if (widget.isMulti) ...state.value ?? [], createdAttachment]);
            }

            setState(() {
              _pendingXFiles.remove(xFile);
            });
          });
    }
  }

  String? _validator(BuildContext context, List<Fragment$AttachmentThumbnailSmallFragment>? value) {
    if (widget.required && value?.isNotEmpty != true) {
      return 'Can\'t be blank';
    }

    return widget.validator?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<Fragment$AttachmentThumbnailSmallFragment>>(
      initialValue: widget.initialValue,
      onSaved: widget.onSaved,
      validator: (value) => _validator(context, value),
      builder: (state) => InkWell(
        borderRadius: borderRadius,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            errorText: widget.errorText,
          ),
          child: Column(
            spacing: 4,
            children: [
              ...state.value
                      ?.map(
                        (attachment) => Row(
                          spacing: 8,
                          children: [
                            ThumbnailItem(attachment: attachment, size: 36),
                            Expanded(child: Text(attachment.fileName, maxLines: 1, overflow: TextOverflow.ellipsis)),
                            IconButton(
                              icon: Icon(Icons.remove_rounded),
                              tooltip: context.l10n.remove,
                              onPressed: () =>
                                  state.didChange(state.value!.where((att) => att.id != attachment.id).toList()),
                            ),
                          ],
                        ),
                      )
                      .toList() ??
                  [],
              ..._pendingXFiles.map(
                (xFile) => Row(
                  spacing: 8,
                  children: [
                    CircularProgressIndicator(),
                    Expanded(child: Text(xFile.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
              if (widget.isMulti || state.value?.firstOrNull == null || _pendingXFiles.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    icon: Icon(Icons.add_rounded),
                    label: Text(context.l10n.addFile),
                    onPressed: () => _addFiles(state),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
