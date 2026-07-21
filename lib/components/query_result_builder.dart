import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../build_context.dart';
import '../router.dart';

class QueryResultBuilder<T> extends StatefulWidget {
  const QueryResultBuilder({
    super.key,
    required this.result,
    required this.buildIf,
    this.loadingWidget,
    this.noResultWidget,
    this.refetch,
    required this.builder,
  });

  final QueryResult<T> result;
  final bool Function(T?) buildIf;
  final Widget? loadingWidget;
  final Widget? noResultWidget;
  final Refetch<T>? refetch;
  final Widget Function(T) builder;

  @override
  State<QueryResultBuilder<T>> createState() => _QueryResultBuilderState<T>();
}

class _QueryResultBuilderState<T> extends State<QueryResultBuilder<T>> with RouteAware {
  Widget _wrapInMaterial(Widget child) {
    if (context.findAncestorWidgetOfExactType<Material>() != null) {
      return child;
    } else {
      return Material(child: child);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final currentRoute = ModalRoute.of(context);

    if (currentRoute != null) {
      routeObserver.subscribe(this, currentRoute);
    }
  }

  @override
  void didPopNext() {
    widget.refetch?.call();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.buildIf(widget.result.parsedData)) {
      return widget.builder(widget.result.parsedData as T);
    } else if (widget.result.isLoading) {
      return _wrapInMaterial(widget.loadingWidget ?? const Center(child: CircularProgressIndicator()));
    } else if (widget.result.hasException) {
      return _wrapInMaterial(
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            spacing: 14,
            children: [
              Text(context.l10n.somethingWentWrong),
              OutlinedButton(
                onPressed: () {
                  widget.refetch?.call();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    } else {
      return _wrapInMaterial(widget.noResultWidget ?? Center(child: Text('No results found 👀')));
    }
  }
}
