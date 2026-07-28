import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../build_context.dart';
import '../../components.dart';
import '../../components/screen_title.dart';
import '../../graphql/fragments/attachment_fragment.graphql.dart';
import '../../graphql/mutations/update_profile.graphql.dart';
import '../../graphql/queries/current_user_profile.graphql.dart';
import '../../graphql/schema.graphql.dart';
import '../../graphql_client.dart';
import '../not_found_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formEditProfile = GlobalKey<FormState>();

  String _displayName = '';
  String _fullName = '';
  DateTime? _birthdate;
  Enum$LanguageCode? _languageCode;
  Enum$CountryCode? _countryCode;
  Fragment$AttachmentFragment? _avatarImageAttachment;
  String? _errorDisplayName;
  String? _errorFullName;
  String? _errorBirthdate;
  String? _errorLanguage;
  String? _errorCountryCode;
  String? _errorAvatarImageAttachment;

  Future<String?> _attemptToUpdateProfile() async {
    final result = await context.graphQLClient.mutate$UpdateProfile(
      Options$Mutation$UpdateProfile(
        variables: Variables$Mutation$UpdateProfile(
          params: Input$UpdateProfileParams(
            displayName: _displayName,
            fullName: _fullName,
            birthdate: _birthdate!,
            languageCode: _languageCode,
            countryCode: _countryCode!,
            avatarImageAttachmentId: _avatarImageAttachment?.id,
          ),
        ),
      ),
    );

    if (!mounted) {
      return null;
    }

    if (result.parsedData?.updateProfile != null) {
      showSnackBarAlert(context, 'Profile updated successfully');
      context.pop();
    } else {
      setState(() {
        _errorDisplayName = result.getParamError('displayName');
        _errorFullName = result.getParamError('fullName');
        _errorBirthdate = result.getParamError('birthdate');
        _errorLanguage = result.getParamError('languageCode');
        _errorCountryCode = result.getParamError('countryCode');
        _errorAvatarImageAttachment = result.getParamError('avatarImageAttachmentId');
      });

      return result.errorMessage ?? 'Failed to update profile';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final title = context.l10n.editProfile;

    return Query$CurrentUserProfile$Widget(
      options: Options$Query$CurrentUserProfile(fetchPolicy: FetchPolicy.noCache),
      builder: (result, {fetchMore, refetch}) => QueryResultBuilder(
        result: result,
        refetch: refetch,
        noResultWidget: const NotFoundScreen(),
        buildIf: (parsedData) => parsedData?.currentUser != null,
        builder: (parsedData) => ScreenTitle(
          title: title,
          child: Scaffold(
            appBar: AppBar(title: Text(title)),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: FormContainer(
                  formKey: _formEditProfile,
                  onSubmit: _attemptToUpdateProfile,
                  fields: [
                    TextInputField(
                      labelText: 'Display name',
                      errorText: _errorDisplayName,
                      required: true,
                      maxLines: 1,
                      initialValue: parsedData.currentUser?.displayName,
                      onSaved: (value) {
                        _displayName = value ?? '';
                      },
                    ),
                    TextInputField(
                      labelText: 'Full name',
                      errorText: _errorFullName,
                      required: true,
                      maxLines: 1,
                      initialValue: parsedData.currentUser?.fullName,
                      onSaved: (value) {
                        _fullName = value ?? '';
                      },
                    ),
                    DateField(
                      labelText: 'Birthdate',
                      errorText: _errorBirthdate,
                      required: true,
                      initialValue: parsedData.currentUser?.birthdate,
                      onSaved: (value) {
                        _birthdate = value;
                      },
                    ),
                    SelectField(
                      labelText: context.l10n.preferredLanguage,
                      errorText: _errorLanguage,
                      required: true,
                      initialValue: parsedData.currentUser?.languageCode,
                      options: (_) =>
                          Enum$LanguageCode.values.where((code) => code != Enum$LanguageCode.$unknown).toList(),
                      optionBuilder: (code) => Text(context.l10n.languages(code.name.toLowerCase())),
                      onSaved: (value) => _languageCode = value,
                    ),
                    CountryField(
                      errorText: _errorCountryCode,
                      required: true,
                      initialValue: parsedData.currentUser?.countryCode,
                      onSaved: (value) => _countryCode = value,
                    ),
                    ImagePickerField(
                      labelText: context.l10n.avatarImage,
                      errorText: _errorAvatarImageAttachment,
                      initialValue: parsedData.currentUser?.avatarImageAttachment,
                      onSaved: (value) {
                        setState(() {
                          _avatarImageAttachment = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
