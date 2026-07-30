import 'package:flutter/material.dart';

import '../components/query_result_builder.dart';
import '../constants.dart';
import '../graphql/fragments/board_context_fragment.graphql.dart';
import '../graphql/queries/user_board_by_slug.graphql.dart';
import '../screens/not_found_screen.dart';
import '../value_keys.dart';
import 'dialog_page.dart';

class BoardContext extends Query$UserBoardBySlug$Widget {
  BoardContext({
    super.key,
    required String username,
    required String slug,
    required Widget Function(Fragment$BoardContextFragment board) builder,
  }) : super(
         options: Options$Query$UserBoardBySlug(
           variables: Variables$Query$UserBoardBySlug(username: username, slug: slug),
         ),
         builder: (result, {fetchMore, refetch}) => QueryResultBuilder(
           result: result,
           refetch: refetch,
           buildIf: (parsedData) => parsedData?.user?.boardBySlug != null,
           noResultWidget: const NotFoundScreen(),
           builder: (parsedData) => builder(parsedData.user!.boardBySlug!),
         ),
       );
}

class BoardContextDialogPage extends DialogPage {
  BoardContextDialogPage({
    required Map<String, String> pathParameters,
    required Widget Function(Fragment$BoardContextFragment board) builder,
  }) : super(
         barrierDismissible: false,
         builder: (context) => BoardContext(
           key: ValueKeys.boardContext(pathParameters[keyUsername]!, pathParameters[keySlug]!),
           username: pathParameters[keyUsername]!,
           slug: pathParameters[keySlug]!,
           builder: builder,
         ),
       );
}
