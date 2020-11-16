import 'dart:async';
import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:rondo_flutter_common/main.dart';
import 'package:rondo_flutter_common/src/other/RondoKey.dart';

enum EncryptType { SM3SM2, SM2 }

/// author by zyl
class RondoUtils {
  static final double MILLIS_LIMIT = 1000.0;
  static final double SECONDS_LIMIT = 60 * MILLIS_LIMIT;
  static final double MINUTES_LIMIT = 60 * SECONDS_LIMIT;
  static final double HOURS_LIMIT = 24 * MINUTES_LIMIT;
  static final double DAYS_LIMIT = 30 * HOURS_LIMIT;

  static FlutterWebviewPlugin flutterWebviewPlugin = FlutterWebviewPlugin();
  static StreamSubscription<WebViewStateChanged> _onStateChanged;
  static DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  /// 通用登录后逻辑
  ///[ context ] 上下文
  ///
  static loginRedirect(context) async {
    String key = await LocalStorage.get(RondoKey.REDIRECT_KEY);

    if (key != null) {
      Navigator.pushReplacementNamed(context, key);
    } else {
      Navigator.of(context).pop();
    }
  }

  /// 加密工具
  ///[ context ] 上下文
  ///[ publicKey ] 密钥
  ///[ value ] 需要加密的对象
  ///[ callback ] 返回结果，如果加密失败返回 null
  static secretToEncrypt(context, publicKey, value,
      {Function(String) callback}) async {
    var htmlData = await rootBundle.loadString('static/secret/sm3Sm2.html');
//      flutterWebViewPlugin.launch(Address.hostWebSM3,
    flutterWebviewPlugin.launch(
      Uri.dataFromString(htmlData, mimeType: 'text/html').toString(),
      hidden: true,
    );

    String result;
    _onStateChanged = flutterWebviewPlugin.onStateChanged.listen((state) async {
      if (state.type == WebViewState.finishLoad) {
        result = await flutterWebviewPlugin.evalJavascript(
            "this.sm3AndSm2EncryptRP('$publicKey','$value','|');");
        //处理安卓端差异(加密后的值会带两个冒号，将其去掉)
        _onStateChanged.cancel();
        if (Platform.isAndroid) {
          result = result.substring(1, result.length - 1);
        }
        if (result.trim() == '') {
          callback(null);
        } else {
          callback(result);
        }
//        return Future.value(result);
        flutterWebviewPlugin?.close();
      }
    });
  }

  static Future<String> secretToEncryptPromise(publicKey, value,
      {EncryptType encryptType = EncryptType.SM3SM2,
      String functionStr}) async {
    List<String> result = await secretMultiToEncryptPromise(publicKey, [value],
        encryptType: encryptType, functionStr: functionStr);
    if (result != null && result.length > 0) {
      return result[0];
    }
    return null;
  }

  static Future<List<String>> secretMultiToEncryptPromise(
      publicKey, List values,
      {EncryptType encryptType = EncryptType.SM3SM2,
      String functionStr}) async {
    flutterWebviewPlugin?.close();
    String file = 'static/secret/sm3Sm2.html';
    if (encryptType == EncryptType.SM2) file = 'static/secret/sm2.html';
    String htmlData = await rootBundle.loadString(file);

    await flutterWebviewPlugin.launch(
      Uri.dataFromString(htmlData, mimeType: 'text/html').toString(),
      hidden: true,
    );

    await flutterWebviewPlugin.onStateChanged.firstWhere((state) {
      if (state.type == WebViewState.finishLoad) {
        return true;
      } else {
        return false;
      }
    });

    List<String> results = [];
    for (var element in values) {
      String result = await flutterWebviewPlugin.evalJavascript(
          "this.${functionStr != null ? functionStr : "sm3AndSm2EncryptRP"}('$publicKey','$element','|');");
      //处理安卓端差异(加密后的值会带两个冒号，将其去掉)
      if (Platform.isAndroid) {
        result = result.substring(1, result.length - 1);
      }
      results.add(result);
    }

    flutterWebviewPlugin?.close();
    return results;
  }

  static Future<Null> showLoadingDialog(BuildContext context,
      {int dismissTimeout = 60}) {
    bool timeout = false;
    Timer _timerDia;
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          //为通用调用设置超时关闭时间
          return StatefulBuilder(builder: (context, mSetState) {
            _timerDia = Timer(Duration(seconds: dismissTimeout), () {
              timeout = true;

//            Navigator.maybePop(context);
            });
            // mSetState((){});
            if (timeout) {
              _timerDia?.cancel();
            }
            return GestureDetector(
              onTap: () async {
                if (timeout) {
                  Navigator.maybePop(context);
                }
              },
              child: new Material(
                  color: Colors.transparent,
                  child: WillPopScope(
                    onWillPop: () async {
                      return timeout;
                    },
                    child: Center(
                      child: new Container(
                        width: 200.0,
                        height: 200.0,
                        padding: new EdgeInsets.all(4.0),
                        decoration: new BoxDecoration(
                          color: Colors.transparent,
                          //用一个BoxDecoration装饰器提供背景图片
                          borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        ),
                        child: new Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            new Container(
                                child: SpinKitCubeGrid(color: Colors.white)),
                            new Container(height: 10.0),
                            new Container(
                                child: new Text('加载中...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ))),
                          ],
                        ),
                      ),
                    ),
                  )),
            );
          });
        });
  }

  //至少一个汉字+字母+数值+下划线+中文+中文标点符号+英文标点符号
  static String getRegHanZi() {
    return '[a-zA-Z0-9_\u4e00-\u9fa5.,?!。，？！]+';
  }

  //不允许输入的字符
  static String getRegNotAllow() {
    return '[@\$%^&<>`]+';
  }

  // 不允许输入特殊字符
  static String checkTszf() {
    return '[A-Za-z0-9-_\u4e00-\u9fa5]+';
  }

  //只能输入汉字
  static String getRegOnlyHanZi() {
    return '^[\u4e00-\u9fa5]+';
  }

  static String getRegPhone() {
    return '^((13[0-9])|(15[^4])|(166)|(17[0-8])|(18[0-9])|(19[0-9])|(147,145))\\d{8}\$';
  }

  static String getRegMobilePhone() {
    return '^[0-9]+([-])?[0-9]{0,2}';
  }

  //非0开头，最多保留两位小数的正数
  static String getRegNum() {
    return '(?!00)(?!01)(?!02)(?!03)(?!04)(?!05)(?!06)(?!07)(?!08)(?!09)[0-9]+([.])?[0-9]{0,2}';
//    return '0.\\d?[1-9]|^[1-9]{1}\\d*.\\d?[1-9]|^[1-9]{1}\\d*';
//    return '[0-9]+([.])?[0-9]{0,2}';
  }

  //最多保留两位小数的正数
  static String getRegPrice() {
    return '[0-9]+([.])?[0-9]{0,2}';
  }

  static String getDateStr(DateTime date) {
    if (date == null || date.toString() == null) {
      return "";
    } else if (date.toString().length < 10) {
      return date.toString();
    }
    return date.toString().substring(0, 10);
  }

  static String getDateTimeStr(DateTime date) {
    if (date == null || date.toString() == null) {
      return "";
    } else if (date.toString().length < 10) {
      return date.toString();
    }
    return date.toString().substring(0, 19);
  }

  static Future<bool> isIosSimulator() async {
    if (Platform.isIOS) {
      IosDeviceInfo iosDeviceInfo = await deviceInfo.iosInfo;
      return !iosDeviceInfo.isPhysicalDevice;
    } else {
      return false;
    }
  }

  ///日期格式转换
  static String getNewsTimeStr(DateTime date) {
    int subTime =
        DateTime.now().millisecondsSinceEpoch - date.millisecondsSinceEpoch;

    if (subTime < MILLIS_LIMIT) {
      return "刚刚";
    } else if (subTime < SECONDS_LIMIT) {
      return (subTime / MILLIS_LIMIT).round().toString() + " 秒前";
    } else if (subTime < MINUTES_LIMIT) {
      return (subTime / SECONDS_LIMIT).round().toString() + " 分钟前";
    } else if (subTime < HOURS_LIMIT) {
      return (subTime / MINUTES_LIMIT).round().toString() + " 小时前";
    } else if (subTime < DAYS_LIMIT) {
      return (subTime / HOURS_LIMIT).round().toString() + " 天前";
    } else {
      return getDateStr(date);
    }
  }
}
