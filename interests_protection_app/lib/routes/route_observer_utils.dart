import 'package:flutter/material.dart';

class RouteObserverUtils {
  //这是实际上的路由监听器
  static final MyRouteObserver<PageRoute> _routeObserver =
      MyRouteObserver<PageRoute>();
  //这是个单例
  static final RouteObserverUtils _routeObserverUtils =
      RouteObserverUtils._internal();
  RouteObserverUtils._internal();
  //通过单例的get方法轻松获取路由监听器
  MyRouteObserver<PageRoute> get routeObserver {
    return _routeObserver;
  }

  factory RouteObserverUtils() {
    return _routeObserverUtils;
  }
}

class MyRouteObserver<R extends Route<dynamic>> extends RouteObserver<R> {
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);
  }

  @override
  void didStartUserGesture(Route route, Route? previousRoute) {
    super.didStartUserGesture(route, previousRoute);
  }

  @override
  void didStopUserGesture() {
    super.didStopUserGesture();
  }
}
