import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:rondo_flutter_common/main.dart';
import 'package:rondo_flutter_common/src/other/RondoKey.dart';

/**
 * author by zyl
 */
class RondoUtils {
  static FlutterWebviewPlugin flutterWebviewPlugin = FlutterWebviewPlugin();
  static StreamSubscription<WebViewStateChanged> _onStateChanged;

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
    var htmlData = await rootBundle.loadString('static/secret/index.html');
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
        //处理安卓���差异加密后的值会带两个冒号，将其去掉
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
      }
    });
  }
}
