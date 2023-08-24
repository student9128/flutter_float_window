import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_float_window_example/main.dart';


class RouteInfo {

  Route? currentRoute;
  List<Route> routes;

  RouteInfo(this.currentRoute, this.routes);
  static Map<String, WidgetBuilder> configRoutes = {
    'main': (context)=>MyApp()
  };
  @override
  String toString() {
    return 'RouteInfo{currentRoute: $currentRoute, routes: $routes}';
  }
}

class NavigationUtil extends NavigatorObserver {
  static NavigationUtil? _instance;

  static Map<String, WidgetBuilder> configRoutes = {

  };

  ///路由信息
  RouteInfo? _routeInfo;
  RouteInfo? get routeInfo => _routeInfo;

  ///存储当前路由页面名字
  final List<String> _routeNames = [];
  List<String> get routeNames => _routeNames;

  ///stream相关
  static late StreamController<RouteInfo> _streamController;
  StreamController<RouteInfo> get streamController => _streamController;

  ///用来路由跳转
  static NavigatorState? navigatorState;

  static NavigationUtil getInstance() {
    if (_instance == null) {
      _instance = NavigationUtil();
      _streamController = StreamController<RouteInfo>.broadcast();
    }
    return _instance!;
  }

  pushPage(BuildContext context, String routeName,
      {required Widget widget, bool fullscreenDialog=false,Function? func}) {
    return Navigator.of(context).push(CupertinoPageRoute(
      builder: (context) => widget,
      settings: RouteSettings(name: routeName),
      fullscreenDialog: fullscreenDialog,
    )).then((value){
      func?.call(value);
    });
  }

  pushReplacementPage(BuildContext context, String routeName,
      {required Widget widget, bool fullscreenDialog = false}) {
    return Navigator.of(context).pushReplacement(CupertinoPageRoute(
      builder: (context) => widget,
      settings: RouteSettings(name: routeName),
      fullscreenDialog: fullscreenDialog,
    ));
  }

  pushAndRemoveUtil(BuildContext context, String routeName,
      {required Widget widget, bool fullscreenDialog = false}) async {
    return Navigator.pushAndRemoveUntil(
        context,
        CupertinoPageRoute(
            builder: (context) => widget,
            settings: RouteSettings(name: routeName),
            fullscreenDialog: fullscreenDialog),
        (route) => route == null);
  }

  /// you could also specify the route predicate that will tell you when you need to stop popping your stack before pushing your next route
  pushAndRemoveUtilPage(
      BuildContext context, String routeName, String predicateRouteName,
      {required Widget widget, bool fullscreenDialog = false,Function? func}) {
    return Navigator.pushAndRemoveUntil(
        context,
        CupertinoPageRoute(
            builder: (context) => widget,
            settings: RouteSettings(name: routeName),
            fullscreenDialog: fullscreenDialog),
        ModalRoute.withName(predicateRouteName)).then((value) => func?.call());
  }

  popUtilPage(BuildContext context, String routeName) {
    return Navigator.popUntil(context, ModalRoute.withName(routeName));
  }

  ///Push the given route onto the navigator.
  push(BuildContext context, String routeName,
      {required Widget Function(BuildContext) builder,
      bool fullscreenDialog = false}) {
    return Navigator.of(context).push(CupertinoPageRoute(
      builder: builder,
      settings: RouteSettings(name: routeName),
      fullscreenDialog: fullscreenDialog,
    ));
  }

  pushReplacement(BuildContext context, String routeName,
      {required Widget Function(BuildContext) builder,Function? func,
      bool fullscreenDialog = false}) {
    return Navigator.of(context).pushReplacement(CupertinoPageRoute(
      builder: builder,
      settings: RouteSettings(name: routeName),
      fullscreenDialog: fullscreenDialog,
    )).then((value) => func?.call);
  }

  popPage(BuildContext context) {
    Navigator.of(context).pop();
  }

  ///push页面
  Future<T?>? pushNamed<T>(String routeName,
      {WidgetBuilder? builder, bool? fullscreenDialog}) {
    return navigatorState?.push<T>(
      CupertinoPageRoute(
        builder: (builder ?? configRoutes[routeName])!,
        settings: RouteSettings(name: routeName),
        fullscreenDialog: fullscreenDialog ?? false,
      ),
    );
  }

  ///replace页面
  Future<T?>? pushReplacementNamed<T, R>(String routeName,
      {WidgetBuilder? builder, bool? fullscreenDialog}) {
    return navigatorState?.pushReplacement<T, R>(
      CupertinoPageRoute(
        builder: (builder ?? configRoutes[routeName])!,
        settings: RouteSettings(name: routeName),
        fullscreenDialog: fullscreenDialog ?? false,
      ),
    );
  }

  // pop 页面
  pop<T>([T? result]) {
    navigatorState?.pop<T>(result);
  }

  //poputil返回到指定页面
  popUntil(String newRouteName) {
    return navigatorState?.popUntil(ModalRoute.withName(newRouteName));
  }

  pushNamedAndRemoveUntil(String newRouteName, {arguments}) {
    return navigatorState?.pushNamedAndRemoveUntil(
        newRouteName, (Route<dynamic> route) => false,
        arguments: arguments);
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _routeInfo ??= RouteInfo(null, <Route>[]);

    ///这里过滤调push的是dialog的情况
    if (route is CupertinoPageRoute || route is MaterialPageRoute) {
      _routeInfo?.routes.add(route);

      var name = route.settings.name;
      debugPrint('🚀routeName==============push===$name');
      if (name != null) {
        _routeNames.add(name);
      }
      routeObserver();
    }
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace();
    if (newRoute is CupertinoPageRoute || newRoute is MaterialPageRoute) {
      _routeInfo?.routes.remove(oldRoute);
      _routeInfo?.routes.add(newRoute!);

      var oldName = oldRoute!.settings.name;
      var newName = newRoute!.settings.name;
      debugPrint('🚀🚀routeName==============didReplace===$oldName,,,,$newName');
      if (_routeNames.contains(oldName)) {
        _routeNames.remove(oldName);
      }
      if (newName != null) {
        _routeNames.add(newName);
      }
      routeObserver();
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    if (route is CupertinoPageRoute || route is MaterialPageRoute) {
      _routeInfo?.routes.remove(route);

      var name = route.settings.name;
      debugPrint('🇫🇯routeName==============didPop===$name');
      if (_routeNames.contains(name)) {
        _routeNames.remove(name);
      }
      routeObserver();
    }
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);
    if (route is CupertinoPageRoute || route is MaterialPageRoute) {
      _routeInfo?.routes.remove(route);

      var name = route.settings.name;
      debugPrint('✈️routeName==============didRemove===$name');
      if (_routeNames.contains(name)) {
        _routeNames.remove(name);
      }
      routeObserver();
    }
  }

  void routeObserver() {
    if (_routeInfo != null) {
      _routeInfo!.currentRoute = _routeInfo!.routes.last;
      navigatorState = _routeInfo!.currentRoute?.navigator;
      debugPrint(
          "NavigationUtil: $navigatorState, currentRoute: ${_routeInfo!.currentRoute?.settings.name}");
      _streamController.sink.add(_routeInfo!);
    }
  }
}

