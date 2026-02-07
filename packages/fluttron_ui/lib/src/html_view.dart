import 'package:flutter/material.dart';

import 'html_view_platform_stub.dart'
    if (dart.library.html) 'html_view_platform_web.dart'
    as html_view_platform;

typedef FluttronHtmlViewErrorBuilder =
    Widget Function(BuildContext context, Object error);

class FluttronHtmlView extends StatefulWidget {
  const FluttronHtmlView({
    super.key,
    required this.viewType,
    required this.jsFactoryName,
    this.jsFactoryArgs,
    this.loadingBuilder,
    this.errorBuilder,
  });

  final String viewType;
  final String jsFactoryName;
  final List<dynamic>? jsFactoryArgs;
  final WidgetBuilder? loadingBuilder;
  final FluttronHtmlViewErrorBuilder? errorBuilder;

  @override
  State<FluttronHtmlView> createState() => _FluttronHtmlViewState();
}

enum _FluttronHtmlViewStage { loading, ready, error }

class _FluttronHtmlViewState extends State<FluttronHtmlView> {
  _FluttronHtmlViewStage _stage = _FluttronHtmlViewStage.loading;
  Object? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _bootstrap(notifyLoading: false);
  }

  @override
  void didUpdateWidget(covariant FluttronHtmlView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.viewType != oldWidget.viewType ||
        widget.jsFactoryName != oldWidget.jsFactoryName ||
        !_jsonLikeEquals(widget.jsFactoryArgs, oldWidget.jsFactoryArgs)) {
      _bootstrap(notifyLoading: true);
    }
  }

  void _bootstrap({required bool notifyLoading}) {
    final int generation = ++_generation;
    if (notifyLoading) {
      setState(() {
        _stage = _FluttronHtmlViewStage.loading;
        _error = null;
      });
    } else {
      _stage = _FluttronHtmlViewStage.loading;
      _error = null;
    }

    Future<void>(() {
          if (!html_view_platform.isFluttronHtmlViewSupported) {
            throw StateError(
              'FluttronHtmlView is only supported on Flutter Web.',
            );
          }

          html_view_platform.ensureFluttronHtmlViewRegistered(
            viewType: widget.viewType,
            jsFactoryName: widget.jsFactoryName,
            jsFactoryArgs: widget.jsFactoryArgs,
          );
        })
        .then((_) {
          if (!mounted || generation != _generation) {
            return;
          }
          setState(() {
            _stage = _FluttronHtmlViewStage.ready;
          });
        })
        .catchError((Object error, StackTrace _) {
          if (!mounted || generation != _generation) {
            return;
          }
          setState(() {
            _stage = _FluttronHtmlViewStage.error;
            _error = error;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _FluttronHtmlViewStage.loading:
        return widget.loadingBuilder?.call(context) ??
            const Center(child: CircularProgressIndicator());
      case _FluttronHtmlViewStage.ready:
        return HtmlElementView(viewType: widget.viewType);
      case _FluttronHtmlViewStage.error:
        final Object error = _error ?? StateError('Unknown html view error.');
        return widget.errorBuilder?.call(context, error) ??
            SelectableText(
              'FluttronHtmlView error: $error',
              style: const TextStyle(color: Colors.redAccent),
            );
    }
  }
}

bool _jsonLikeEquals(Object? left, Object? right) {
  if (identical(left, right)) {
    return true;
  }
  if (left.runtimeType != right.runtimeType) {
    return false;
  }
  if (left is List && right is List) {
    if (left.length != right.length) {
      return false;
    }
    for (int index = 0; index < left.length; index++) {
      if (!_jsonLikeEquals(left[index], right[index])) {
        return false;
      }
    }
    return true;
  }
  if (left is Map && right is Map) {
    if (left.length != right.length) {
      return false;
    }
    for (final Object? key in left.keys) {
      if (!right.containsKey(key)) {
        return false;
      }
      if (!_jsonLikeEquals(left[key], right[key])) {
        return false;
      }
    }
    return true;
  }
  return left == right;
}
