import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../build_context.dart';
import '../scrollable_dialog.dart';

Future<List<T>?> showSelectDialog<T>(
  BuildContext context, {
  required FutureOr<List<T>> Function(String filter) options,
  List<T>? selected,
  bool Function(T option, String filter)? filterFn,
  required Widget Function(T option) optionBuilder,
  bool isMulti = false,
  Duration searchDelay = const Duration(seconds: 0),
}) {
  return showDialog(
    context: context,
    builder: (context) => _SelectDialog<T>(
      options: options,
      selected: selected,
      filterFn: filterFn,
      optionBuilder: optionBuilder,
      isMulti: isMulti,
      searchDelay: searchDelay,
    ),
  );
}

class _SelectDialog<T> extends StatefulWidget {
  const _SelectDialog({
    required this.options,
    required this.selected,
    this.filterFn,
    required this.optionBuilder,
    required this.isMulti,
    required this.searchDelay,
  });

  final FutureOr<List<T>> Function(String filter) options;
  final List<T>? selected;
  final bool Function(T option, String filter)? filterFn;
  final Widget Function(T option) optionBuilder;
  final bool isMulti;
  final Duration searchDelay;

  @override
  State<_SelectDialog<T>> createState() => _SelectDialogState();
}

class _SelectDialogState<T> extends State<_SelectDialog<T>> {
  String _filter = '';
  List<T> _options = [];
  List<T> _selected = [];

  void _toggleSelected(T option) {
    setState(() {
      if (_selected.contains(option) == true) {
        _selected.remove(option);
      } else {
        _selected.add(option);
      }
    });
  }

  void _fetchOptions(String filter) {
    setState(() {
      _filter = filter;
    });

    Future.delayed(widget.searchDelay, () async {
      if (filter != _filter) {
        return;
      }

      await _setOptions();
    });
  }

  Future<void> _setOptions() async {
    late final List<T> options;
    if (widget.filterFn != null) {
      options = (await widget.options(_filter)).where((option) => widget.filterFn!.call(option, _filter)).toList();
    } else {
      options = await widget.options(_filter);
    }

    setState(() {
      _options = options;
    });
  }

  Widget _getOptions() {
    if (_options.isEmpty) {
      return Center(child: Text(context.l10n.noResultsFound));
    }

    if (widget.isMulti) {
      return Column(
        spacing: 4,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _options
            .map(
              (option) => InkWell(
                onTap: () {
                  _toggleSelected(option);
                },
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    spacing: 2,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      widget.optionBuilder(option),
                      IgnorePointer(
                        child: Checkbox(onChanged: (_) {}, value: _selected.contains(option)),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      );
    } else {
      return RadioGroup(
        onChanged: (_) {},
        groupValue: _selected.firstOrNull,
        child: Column(
          spacing: 4,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _options
              .map(
                (option) => InkWell(
                  onTap: () => context.pop([option]),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      spacing: 2,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: DefaultTextStyle(
                            style: Theme.of(context).textTheme.bodyMedium!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            child: widget.optionBuilder(option),
                          ),
                        ),
                        IgnorePointer(child: Radio(value: option)),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.selected != null) {
      _selected = widget.selected!;
    }

    _setOptions();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollableDialog(
      width: 480,
      child: Column(
        spacing: 8,
        children: [
          if (widget.filterFn != null)
            TextField(
              autofocus: true,
              decoration: InputDecoration(hintText: context.l10n.search, suffixIcon: Icon(Icons.search_rounded)),
              onChanged: _fetchOptions,
            ),
          _getOptions(),
          if (widget.isMulti)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () => context.pop(_selected), child: Text(context.l10n.ok)),
            ),
        ],
      ),
    );
  }
}
