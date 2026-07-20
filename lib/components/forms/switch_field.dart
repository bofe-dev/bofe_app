import 'package:flutter/material.dart';

import '../../constants.dart';

class SwitchField extends StatelessWidget {
  const SwitchField({
    super.key,
    this.labelText,
    this.hintText,
    this.errorText,
    this.initialValue = false,
    this.required = false,
    this.onSaved,
    this.validator,
  });

  final String? labelText;
  final String? hintText;
  final String? errorText;
  final bool initialValue;
  final bool required;
  final FormFieldSetter<bool>? onSaved;
  final FormFieldValidator<bool>? validator;

  String? _validator(BuildContext context, bool? value) {
    if (required && value != true) {
      return 'Can\'t be blank';
    }

    return validator?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return FormField(
      initialValue: initialValue,
      onSaved: onSaved,
      validator: (value) => _validator(context, value),
      builder: (state) => InkWell(
        borderRadius: borderRadius,
        onTap: () {
          state.didChange(!(state.value == true));
        },
        child: InputDecorator(
          isEmpty: true,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            errorText: errorText,
            suffixIcon: Switch(
              padding: EdgeInsets.only(right: 16),
              value: state.value == true,
              onChanged: (value) {
                state.didChange(!(state.value == true));
              },
            ),
          ),
          child: null,
        ),
      ),
    );
  }
}
