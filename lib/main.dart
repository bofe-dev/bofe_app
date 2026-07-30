import 'package:bofe/preferences.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import 'constants.dart';
import 'graphql_client.dart';
import 'l10n/app_localizations.g.dart';
import 'router.dart';
import 'screens/home_screen.dart';
import 'sessions_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHiveForFlutter();
  await Preferences.init();
  await SessionsManager.init();

  GoRouter.optionURLReflectsImperativeAPIs = true;

  final graphQLClient = getGraphQLClient();
  final goRouter = getGoRouter();

  await SessionsManager.attemptToRefresh();

  final currentUser = await SessionsManager.getUser();

  if (currentUser != null) {
    HomeScreen.showEmailConfirmationDialog = !currentUser.emailIsConfirmed;
  }

  runApp(App(graphQLClient: graphQLClient, goRouter: goRouter));
}

class MobileLikeScrollBehavior extends MaterialScrollBehavior {
  const MobileLikeScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

class App extends StatelessWidget {
  const App({super.key, required this.graphQLClient, required this.goRouter});

  final GraphQLClient graphQLClient;
  final GoRouter goRouter;

  ThemeData _getThemeData(Brightness brightness) => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: colorSeed, brightness: brightness),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(actionsPadding: EdgeInsets.only(right: 8)),
    dialogTheme: const DialogThemeData(shape: roundedRectangleBorder),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.all(20),
        textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        backgroundColor: colorSeed,
        foregroundColor: Colors.white,
        shape: roundedRectangleBorder,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(20),
        textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        shape: roundedRectangleBorder,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        iconAlignment: IconAlignment.start,
        padding: const EdgeInsets.all(20),
        textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        shape: roundedRectangleBorder,
      ),
    ),
    chipTheme: ChipThemeData(
      shape: roundedRectangleBorder,
      labelPadding: const EdgeInsets.all(0),
      backgroundColor: Colors.transparent,
      checkmarkColor: Colors.black,
      deleteIconColor: Colors.black,
    ),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder(borderRadius: borderRadius)),
  );

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: ValueNotifier(graphQLClient),
      child: Preferences.listenableBuilder(
        builder: (context, data) => MaterialApp.router(
          title: 'Bofe',
          scrollBehavior: const MobileLikeScrollBehavior(),
          themeMode: data.themeMode,
          theme: _getThemeData(Brightness.light),
          darkTheme: _getThemeData(Brightness.dark),
          locale: data.language,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: goRouter,
        ),
      ),
    );
  }
}
