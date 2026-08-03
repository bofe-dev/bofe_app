import 'dart:async';

import 'package:flutter/material.dart';

import '../../constants.dart';
import '../dialogs/select_dialog.dart';

class SelectField<T> extends StatelessWidget {
  SelectField({
    super.key,
    this.labelText,
    this.hintText,
    this.errorText,
    T? initialValue,
    this.required = false,
    this.filterFn,
    required this.options,
    required this.optionBuilder,
    FormFieldSetter<T>? onSaved,
    FormFieldValidator<T>? validator,
  }) : initialValue = _initialValueToMulti(initialValue),
       onSaved = _onSavedToMulti(onSaved),
       validator = _validatorToMulti(validator),
       isMulti = false;

  const SelectField.multi({
    super.key,
    this.labelText,
    this.hintText,
    this.errorText,
    this.initialValue = const [],
    this.required = false,
    this.filterFn,
    required this.options,
    required this.optionBuilder,
    this.onSaved,
    this.validator,
  }) : isMulti = true;

  final String? labelText;
  final String? hintText;
  final String? errorText;
  final List<T> initialValue;
  final bool required;
  final bool Function(T, String)? filterFn;
  final FutureOr<List<T>> Function(String filter) options;
  final Widget Function(T) optionBuilder;
  final FormFieldSetter<List<T>>? onSaved;
  final FormFieldValidator<List<T>>? validator;
  final bool isMulti;

  static List<T> _initialValueToMulti<T>(T? value) {
    return [?value];
  }

  static FormFieldSetter<List<T>>? _onSavedToMulti<T>(FormFieldSetter<T>? onSaved) {
    return (value) => onSaved?.call(value?.firstOrNull);
  }

  static FormFieldValidator<List<T>>? _validatorToMulti<T>(FormFieldValidator<T>? validator) {
    return (value) => validator?.call(value?.firstOrNull);
  }

  Future<List<T>?> _showDialog(BuildContext context, FormFieldState<List<T>> state) async {
    return await showSelectDialog(
      context,
      options: options,
      selected: state.value,
      filterFn: filterFn,
      optionBuilder: optionBuilder,
      isMulti: isMulti,
    );
  }

  String? _validator(BuildContext context, List<T>? value) {
    if (required && value?.isNotEmpty != true) {
      return 'Can\'t be blank';
    }

    return validator?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<T>>(
      initialValue: initialValue,
      onSaved: onSaved,
      validator: (value) => _validator(context, value),
      builder: (state) => InkWell(
        borderRadius: borderRadius,
        onTap: () async {
          final selected = await _showDialog(context, state) ?? state.value;

          if (context.mounted) {
            state.didChange(selected);
          }
        },
        child: InputDecorator(
          isEmpty: state.value?.isNotEmpty != true,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            errorText: errorText,
            suffixIcon: Icon(Icons.arrow_outward_rounded),
          ),
          child: state.value?.isNotEmpty == true
              ? Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children:
                      state.value
                          ?.map(
                            (option) => DefaultTextStyle(
                              style: Theme.of(context).textTheme.bodyMedium!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              child: optionBuilder(option),
                            ),
                          )
                          .toList() ??
                      [],
                )
              : null,
        ),
      ),
    );
  }
}
