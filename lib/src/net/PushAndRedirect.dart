class PushAndRedirect {
  PushAndRedirect.init({RouteType routeType, String redirect}) {
    this.pushType = routeType;
    this.redirect = redirect;
  }

  RouteType pushType;
  String redirect;
}

enum RouteType {
  push,
  replace,
}
