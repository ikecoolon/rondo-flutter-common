import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:rondo_flutter_common/main.dart';
import 'package:rondo_flutter_common/src/event/HttpErrorEvent.dart';
import 'package:rondo_flutter_common/src/net/Code.dart';
import 'package:rondo_flutter_common/src/net/PushAndRedirect.dart';
import 'package:rondo_flutter_common/src/other/RondoKey.dart';

class AostarCommonWidget extends StatefulWidget {
  final Widget child;

  AostarCommonWidget({Key key, this.child}) : super(key: key);

  @override
  State<AostarCommonWidget> createState() {
    return new _AostarCommonWidget();
  }
}

class _AostarCommonWidget extends State<AostarCommonWidget> {
  StreamSubscription stream;

//  DateTime recordTime;

  @override
  Widget build(BuildContext context) {
//    return new StoreBuilder<GlobalState>(builder: (context, store) {
    ///通过 StoreBuilder 和 Localizations 实现实时多语言切换
//    return new Localizations.override(
//      context: context,
////        locale: store.state.locale,
//      child: widget.child,
//    );
    return widget.child;
//    }
//    );
  }

  @override
  void initState() {
    super.initState();
    stream = Code.eventBus.on<HttpErrorEvent>().listen((HttpErrorEvent event) {
      errorHandleFunction(event.code, event.message,
          pushRouter: event.pushRouter);
    });
  }

  @override
  void dispose() {
    super.dispose();
    if (stream != null) {
      stream.cancel();
      stream = null;
    }
  }

  errorHandleFunction(int code, message, {PushAndRedirect pushRouter}) async {
    switch (code) {
      case Code.NETWORK_ERROR:
        Fluttertoast.showToast(msg: '网络错误');
        break;
      case Code.LOGIN_PASSWORD_ERROR:
        Fluttertoast.showToast(msg: '账号或密码错误');
        break;
      case Code.LOGIN_SMS_ERROR:
        Fluttertoast.showToast(msg: '验证码错误，请重试');
        break;
      case Code.USER_LOCKED:
        Fluttertoast.showToast(msg: '用户已经锁定，请联系客服');
        break;
      case Code.LOGIN_SMS_ERRORLENGTH:
        Fluttertoast.showToast(msg: '验证码非法长度');
        break;
      case Code.LOGIN_SMS_ERRORCHAR:
        Fluttertoast.showToast(msg: '验证码非法字符');
        break;
      case Code.USER_DORMANCY:
        Fluttertoast.showToast(msg: '账号已经休眠，请联系客服');
        break;
      case Code.USER_NOTFOUND:
        Fluttertoast.showToast(msg: '账号不存在');
        break;
      case 401:
        //401对登录的处理
        Fluttertoast.showToast(msg: '请登录后重试!', timeInSecForIos: 3);

        // todo 清空store里的用户信息
//        _getStore().dispatch(UpdateUserAction(User.empty()));
        if (pushRouter == null) {
          Navigator.of(context).pushReplacementNamed(Api().loginRoute);
        } else {
          if (pushRouter.redirect != null &&
              pushRouter.redirect.toString().trim() != '') {
            await LocalStorage.save(RondoKey.REDIRECT_KEY, pushRouter.redirect);
          }

          switch (pushRouter.pushType) {
            case RouteType.replace:
              Navigator.of(context).pushReplacementNamed(Api().loginRoute);
              break;
            case RouteType.push:
              Navigator.of(context).pushNamed(Api().loginRoute);
              break;
          }
        }

        break;
      case 403:
        Fluttertoast.showToast(msg: '403权限错误');
        break;
      case 302:
        break;
      case 404:
        Fluttertoast.showToast(msg: '404错误');
        break;
      case Code.NETWORK_TIMEOUT:
        //超时
        Fluttertoast.showToast(msg: '请求超时');
        break;
      default:
        Fluttertoast.showToast(msg: '$message');
        break;
    }
  }
}
