import 'package:flutter/material.dart';
import 'package:world_info_plus/world_info_plus.dart';

import '../../build_context.dart';
import '../../graphql/schema.graphql.dart';
import 'select_field.dart';

class CountryField extends StatelessWidget {
  const CountryField({super.key, this.errorText, this.required = false, this.initialValue, required this.onSaved});

  final String? errorText;
  final bool required;
  final Enum$CountryCode? initialValue;
  final ValueChanged<Enum$CountryCode?> onSaved;

  (Enum$CountryCode, Country)? _countryCodeToValue(Enum$CountryCode? countryCode) {
    if (countryCode == null || countryCode == Enum$CountryCode.$unknown) {
      return null;
    }

    final countryInfo = WorldInfoPlus.getCountryByAlpha2(countryCode.name);

    if (countryInfo != null) {
      return (countryCode, countryInfo);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SelectField<(Enum$CountryCode, Country)>(
      labelText: context.l10n.country,
      initialValue: _countryCodeToValue(initialValue),
      filterFn: (option, filter) => option.$2.name.toLowerCase().contains(filter.toLowerCase()),
      optionBuilder: (option) {
        return Row(
          spacing: 12,
          children: [
            Image.asset(option.$2.imagePath, height: 24, width: 32, fit: BoxFit.cover),
            Text(option.$2.name),
          ],
        );
      },
      options: (_) => Enum$CountryCode.values
          .map((code) => (code, WorldInfoPlus.getCountryByAlpha2(code.name)))
          .whereType<(Enum$CountryCode, Country)>()
          .where((item) => item.$1 != Enum$CountryCode.$unknown)
          .toList(),
      onSaved: (item) => onSaved(item?.$1),
    );
  }
}
