import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../build_context.dart';
import '../components.dart';
import '../components/screen_title.dart';
import '../constants.dart';
import '../sessions_manager.dart';
import 'home/explore_screen.dart';
import 'home/feed_screen.dart';
import 'home/my_boards_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static bool showEmailConfirmationDialog = false;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  int currentIndex = SessionsManager.hasToken ? 0 : 1;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (HomeScreen.showEmailConfirmationDialog) {
        showEmailConfirmationDialog(context, barrierDismissible: false).then((_) {
          HomeScreen.showEmailConfirmationDialog = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textHome = context.l10n.home;

    return ScreenTitle(
      title: textHome,
      child: Scaffold(
        appBar: AppBar(
          title: Row(spacing: 12, children: [Image.asset('assets/icon.png', height: 32), Text('Bofe')]),
          actions: [
            if (SessionsManager.hasToken)
              IconButton.outlined(
                tooltip: context.l10n.newBoard,
                icon: Icon(Icons.add),
                onPressed: () => context.goNamed(routeNameNewBoard),
              ),
            SizedBox(width: 8),
            AccountButton(),
          ],
        ),
        body: [MyBoardsScreen(), ExploreScreen(), FeedScreen()][currentIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: textHome,
            ),
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore_rounded),
              label: context.l10n.explore,
            ),
            NavigationDestination(
              icon: Icon(Icons.rss_feed_outlined),
              selectedIcon: Icon(Icons.rss_feed_rounded),
              label: context.l10n.feed,
            ),
          ],
        ),
      ),
    );
  }
}
