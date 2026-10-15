import 'package:flutter/widgets.dart';

/// Lets pages react when they come back into view (e.g. Home refreshes its
/// recent list after a chat or recording).
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
