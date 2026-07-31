import 'package:flutter/material.dart';

/// Colors & shapes
const colorSeed = Color(0xFF1997a2);
const colorTranslucent = Color(0x22000000);
const borderRadius = BorderRadius.all(Radius.circular(16));
const borderRadius12 = BorderRadius.all(Radius.circular(12));
const roundedRectangleBorder = RoundedRectangleBorder(borderRadius: borderRadius);

/// HTTP Headers
const headerXAppToken = 'X-App-Token';
const headerAcceptLanguage = 'Accept-Language';

/// Path parameters & Map keys
const keyCurrentUserId = 'current_user_id';
const keyId = 'id';
const keyLanguage = 'language';
const keyList = 'list';
const keySessions = 'sessions';
const keySlug = 'slug';
const keyThemeMode = 'theme_mode';
const keyUsername = 'username';

/// Route names
const routeNameBoard = 'board';
const routeNameCard = 'card';
const routeNameHome = 'home';
const routeNameLabels = 'labels';
const routeNameLogin = 'login';
const routeNameMembers = 'members';
const routeNameNewBoard = 'new_board';
const routeNameRegister = 'register';
const routeNameResetPassword = 'reset_password';
const routeNameSettings = 'settings';
const routeNameSettingsChangePassword = 'change_password';
const routeNameSettingsEditProfile = 'edit_profile';
const routeNameSettingsEmail = 'settings_email';
const routeNameSettingsSwitchAccount = 'switch_account';
const routeNameUser = 'show_user';

const labelColors = [
  (Color(0xFFF44336), 'Red'),
  (Color(0xFFFF9800), 'Orange'),
  (Color(0xFFE91E63), 'Pink'),
  (Color(0xFFFFEB3B), 'Yellow'),
  (Color(0xFFCDDC39), 'Lime'),
  (Color(0xFF4CAF50), 'Green'),
  (Color(0xFF9E9E9E), 'Grey'),
  (Color(0xFF009688), 'Teal'),
  (Color(0xFF2196F3), 'Blue'),
  (Color(0xFF9C27B0), 'Purple'),
  (Color(0xFF00BCD4), 'Cyan'),
];

const urlPrivacy = 'https://about.bofe.app/privacy';
const urlTerms = 'https://about.bofe.app/terms';
