import 'package:flutter/material.dart';
import 'package:flutter_debug_tools/src/state/debug_tools_state.dart';

class DebugNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    updateScreenName(route.settings.name);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    updateScreenName(previousRoute?.settings.name);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    updateScreenName(newRoute?.settings.name);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    updateScreenName(previousRoute?.settings.name);
  }

  void updateScreenName(String? screenName) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      state.value = state.value.copyWith(currentScreen: screenName);
    });
  }
}
