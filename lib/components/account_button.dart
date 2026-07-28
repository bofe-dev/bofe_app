import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../build_context.dart';
import '../graphql/fragments/user_fragment.graphql.dart';
import '../constants.dart';
import 'current_user.dart';
import 'scrollable_dialog.dart';
import 'user_item.dart';

class AccountButton extends StatelessWidget {
  const AccountButton({super.key});

  void _showAccountDialog(BuildContext context, {Fragment$UserFragment? user}) {
    showDialog(
      context: context,
      builder: (BuildContext context) => ScrollableDialog(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            Column(
              spacing: 8,
              children: user != null
                  ? [
                      Center(child: UserAvatarImage(user: user, size: 32)),
                      Text(
                        '@${user.username}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.pop();
                            context.router.pushToUser(user);
                          },
                          icon: const Icon(Icons.person_rounded),
                          label: Text(context.l10n.profile),
                        ),
                      ),
                    ]
                  : [LoginButton(), RegisterButton()],
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.pop();
                  context.router.goToSettings();
                },
                icon: Icon(Icons.settings_rounded),
                label: Text(context.l10n.settings),
              ),
            ),
            SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 4,
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      if (await canLaunchUrlString(urlPrivacy)) {
                        await launchUrlString(urlPrivacy, mode: LaunchMode.inAppBrowserView);
                      }
                    },
                    child: Text(context.l10n.privacyPolicy, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      if (await canLaunchUrlString(urlTerms)) {
                        await launchUrlString(urlTerms, mode: LaunchMode.inAppBrowserView);
                      }
                    },
                    child: Text(context.l10n.termsOfService, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
            FutureBuilder(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Center(
                    child: Text('${context.l10n.version} ${snapshot.data!.version}', style: TextStyle(fontSize: 13)),
                  );
                }

                return SizedBox();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CurrentUser(
      builder: (user) {
        if (user != null) {
          return IconButton(
            padding: EdgeInsets.all(2),
            onPressed: () => _showAccountDialog(context, user: user),
            icon: UserAvatarImage(user: user, size: 18),
          );
        } else {
          return IconButton.outlined(
            onPressed: () => _showAccountDialog(context),
            icon: const Icon(Icons.account_circle_rounded),
          );
        }
      },
    );
  }
}

class LoginButton extends StatelessWidget {
  const LoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => context.router.goToLogin(),
        icon: const Icon(Icons.login_rounded),
        label: Text(context.l10n.login),
      ),
    );
  }
}

class RegisterButton extends StatelessWidget {
  const RegisterButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => context.router.goToRegister(),
        icon: const Icon(Icons.person_add_rounded),
        label: Text(context.l10n.register),
      ),
    );
  }
}
