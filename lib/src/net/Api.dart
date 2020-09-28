import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:alice/alice.dart';
import 'package:connectivity/connectivity.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info/device_info.dart';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:package_info/package_info.dart';
import 'package:rondo_flutter_common/src/local/LocalStorage.dart';
import 'package:rondo_flutter_common/src/net/Code.dart';
import 'package:rondo_flutter_common/src/net/ResultData.dart';
import 'package:rondo_flutter_common/src/sm3/Sm3Utils.dart';

import 'PushAndRedirect.dart';

///http请求
///author Zyl
class Api {
  Api._();

  static Api _instance = Api._();

  factory Api() => _instance;

  String tokenKey, //token 键
      refreshTokenKey, //刷新 token 键
      userInfoKey, //用户身份键
      developmentModeKey, //开发模式键
      userBasicCode, //头部的验证规范
      prodHost, //生产域名
      devHost, //开发域名
      authorizationUrl, //授权token 的访问路径
      loginRoute; //您应用的登录页命名

  bool debug = false;

  //http 分析工具
  Alice alice;

  //设备信息
  DeviceInfoPlugin deviceInfo;

  init({
    @required bool debug,
    @required String tokenKey,
    @required String refreshTokenKey,
    @required String userInfoKey,
    @required String developmentModeKey,
    @required String userBasicCode,
    @required String prodHost,
    @required String devHost,
    @required String authorizationUrl,
    @required String loginRoute,
  }) {
    alice = Alice(showNotification: false, showInspectorOnShake: this.debug);
    deviceInfo = DeviceInfoPlugin();
    this.debug = debug;
    this.tokenKey = tokenKey;
    this.refreshTokenKey = refreshTokenKey;
    this.userInfoKey = userInfoKey;
    this.developmentModeKey = developmentModeKey;
    this.userBasicCode = userBasicCode;
    this.prodHost = prodHost;
    this.devHost = devHost;
    this.authorizationUrl = authorizationUrl;
    this.loginRoute = loginRoute;
  }

   Map optionParams = {
    "timeoutMs": 15000,
    "token": null,
    "Authorization": null,
  };

   Map<String, String> antiReplayParams = {
    'X-Request-Token': '',
    'X-Request-Time': '',
    'X-Request-Sign': '',
  };

   Map<String, String> deviceParams = {
    'Client-DeviceId': '',
    'Client-OS': '',
    'Client-OSversion': '',
  };

   getUUID() {
    List<String> s = [];
    String hexDigits = "0123456789abcdef";
    for (int i = 0; i < 36; i++) {
      int index = (Random().nextDouble() * 0x10).floor();
      s.add(hexDigits.substring(index, index + 1));
    }
    s[14] = "4";

    int a = 0;
    try {
      a = int.tryParse((s[19]));
      if (a == null) {
        a = 0;
      }
    } catch (e) {
      a = 0;
    }

    int secondIndex = (a & 0x3) | 0x8;

    s[19] = hexDigits.substring(secondIndex, secondIndex + 1);
    s[8] = s[13] = s[18] = s[23] = "-";
    String uuid = s.join("");
    return uuid;
  }

  antiReplay() {
    antiReplayParams['X-Request-Token'] = getUUID();
    antiReplayParams['X-Request-Time'] =
        DateTime.now().millisecondsSinceEpoch.toString();
    antiReplayParams['X-Request-Sign'] = Sm3Utils.encryptFromText(
        antiReplayParams['X-Request-Time'] +
            ',' +
            antiReplayParams['X-Request-Token']);

    return antiReplayParams;
  }

  getDeviceInfo() async {
    String deviceId = '';
    String os = '';
    String osVersion = '';
    String appVersion = '';
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appVersion = packageInfo.version + '+' + packageInfo.buildNumber;

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id;
      os = 'Android';
      osVersion = androidInfo.version.release;
    }
    if (Platform.isIOS) {
      IosDeviceInfo iosDeviceInfo = await deviceInfo.iosInfo;
      deviceId = iosDeviceInfo.identifierForVendor;
      os = 'IOS';
      osVersion = iosDeviceInfo.systemVersion;
    }
    deviceParams['Client-DeviceId'] = deviceId;
    deviceParams['Client-OS'] = os;
    deviceParams['Client-OSversion'] = osVersion;
    deviceParams['Client-AppVersion'] = appVersion;

    return deviceParams;
  }

  getUrlParams(String url) {
    print(url);
    Map obj = {};
    if (url.indexOf("?") != -1) {
      var arr = url.substring(url.indexOf('?') + 1).split('&');
      for (var i = 0; i < arr.length; i++) {
        obj[arr[i].split("=")[0]] = arr[i].split("=")[1];
      }
    }
    return obj;
  }

  getParams(params, urlStr, method) {
    var urlParams = getUrlParams(urlStr);
    if (params == null) params = {};
    Map paramsData = {...urlParams};

    var arr = [];
    paramsData.forEach((key, value) {
      arr.add(key);
    });
    arr.sort();
    String url = "";
    for (var i in arr) {
      url += i + "=" + paramsData[i] + "&";
    }
    String object = '', urlString = '';
    try {
      method == 'post' ? object = jsonEncode(params) : object = "";
    } catch (err) {}

    (url != null && url.isNotEmpty)
        ? urlString = url.substring(0, url.length - 1)
        : urlString = "";
    //针对这个接口做特殊处理
    if (urlStr.indexOf('regUserAuto') > -1) {
      if (object.trim() == '{}') {
        object = '';
      }
    }

    String newData = object + urlString;

    if (newData != null && newData.isNotEmpty) {
      var key = utf8.encode('1234@ABCD');
      var bytes = utf8.encode(newData);

      var hmacSha256 = new Hmac(sha256, key); // HMAC-SHA256
      newData = hmacSha256.convert(bytes).toString();
    }

    return {'awlSign': newData};
  }

  ///发起网络请求
  ///[ url] 请求url
  ///[ data] 请求参数
  ///[ header] 外加头
  ///[ option] 配置
  ///[ noTip] 是否提示登录
  ///[ pushRouter] 登录页出现的方式
  ///1、null 【默认方式】登录页替换底页 ,并没有指定登录成功后的跳转去向
  ///2、其他方式详见[ PushAndRedirect ]
  netFetch(
    String url,
    data,
    Map<String, String> header,
    Options option, {
    noTip = false,
    showParameters = false,
    PushAndRedirect pushRouter,
  }) async {
    //没有网络
    var connectivityResult = await (new Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      return new ResultData(
          Code.errorHandleFunction(Code.NETWORK_ERROR, "", noTip),
          false,
          Code.NETWORK_ERROR);
    }

    //判断是否开启开发者模式
    url = await checkDevelopment(url);

    Map<String, String> headers = new HashMap();
    if (header != null) {
      headers.addAll(header);
    }
    //增加防重放字符串
    headers.addAll(antiReplay());
    //增加防篡改
    headers.addAll(getParams(data, url, option?.method));
    //增加当前设备信息
    headers.addAll(await getDeviceInfo());
    //授权码
    if (optionParams["Authorization"] == null) {
      var authorizationCode = await getAuthorization(url);
      if (authorizationCode != null) {
        optionParams["Authorization"] = authorizationCode;
      }
    }
    headers["Authorization"] = optionParams["Authorization"];

    if (option != null) {
      option.headers = headers;
    } else {
      option = new Options(method: "get");
      option.headers = headers;
    }

    ///超时
    option.receiveTimeout = 15000;
    option.sendTimeout = 15000;

    Dio dio = Dio();
    dio.interceptors.add(alice.getDioInterceptor());
    //设置忽略证书信任
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (client) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        return true;
      };
//       client.findProxy=(uri){
//        return 'PROXY 192.168.3.91:9352';
//      };
    };

    if (debug) {
      print('--------------------------');
      print('请求前查看参数：${data.toString()}');
      print('请求前查看contentType参数：${option.contentType.toString()}');
      print('请求前查看header：${option.headers.toString()}');
      print('--------------------------');
    }

    Response response;
    try {
      //授权登录时将map拼接在url后
      if (url.contains('oauth/token')) {
        showParameters = true;
      }
      response = await dio.request(url,
          data: data,
          options: option,
          queryParameters:
              (data is Map<String, dynamic>) && showParameters ? data : null);
    } on DioError catch (e) {
      Response errorResponse;
      if (e.response != null) {
        errorResponse = e.response;
      } else {
        errorResponse = new Response(statusCode: 666);
      }
      if (e.type == DioErrorType.CONNECT_TIMEOUT) {
        errorResponse.statusCode = Code.NETWORK_TIMEOUT;
      }
      if (debug) {
        print('请求异常: ' + e.toString());
        print('请求异常http-code: ' + errorResponse.statusCode.toString());
        print('请求异常repsonse: ' + errorResponse.data.toString());
        print('请求异常url: ' + url);
      }
      //如果遇到401，
      if (errorResponse.statusCode == 401) {
        //尝试续约token
        var result = await refreshToken(dio,
            url: url, params: data, header: headers, option: option);
        if (result != null) {
          return result;
        }

        //若仍401，说明用户token失效，清除token
        optionParams["Authorization"] = null;
        LocalStorage.remove(this.tokenKey);
        LocalStorage.remove(this.refreshTokenKey);
      }

      //如果auth/token登录返回的400 可能是密码错误，用户被锁、验证码错误等等，做特殊处理
      if (errorResponse.statusCode == 400 &&
          errorResponse.data.toString().indexOf('invalid_grant') != -1) {
        switch (errorResponse.data['error_description'].toString()) {
          //AccountLoginLockedException
          case 'AccountLockedException':
            return new ResultData(
                Code.errorHandleFunction(Code.USER_LOCKED, e.message, noTip),
                false,
                Code.USER_LOCKED);
            break;
          case 'AccountLoginLockedException':
            return new ResultData(
                Code.errorHandleFunction(Code.USER_LOCKED, e.message, noTip),
                false,
                Code.USER_LOCKED);
            break;
          case 'VerifyCodeIllegalCharException':
            return new ResultData(
                Code.errorHandleFunction(
                    Code.LOGIN_SMS_ERRORCHAR, e.message, noTip),
                false,
                Code.LOGIN_SMS_ERRORCHAR);
            break;
          case 'VerifyCodeIllegalLengthException':
            return new ResultData(
                Code.errorHandleFunction(
                    Code.LOGIN_SMS_ERRORLENGTH, e.message, noTip),
                false,
                Code.LOGIN_SMS_ERRORLENGTH);
            break;
          case 'AccountDormancyException':
            return new ResultData(
                Code.errorHandleFunction(Code.USER_DORMANCY, e.message, noTip),
                false,
                Code.USER_DORMANCY);
            break;
          case 'VerifyCodeException':
            return new ResultData(
                Code.errorHandleFunction(
                    Code.LOGIN_SMS_ERROR, e.message, noTip),
                false,
                Code.LOGIN_SMS_ERROR);
            break;
          case 'FailedLoginException':
            return new ResultData(
                Code.errorHandleFunction(
                    Code.LOGIN_PASSWORD_ERROR, e.message, noTip),
                false,
                Code.LOGIN_PASSWORD_ERROR);
            break;
          case 'AccountNotFoundException':
            return new ResultData(
                Code.errorHandleFunction(Code.USER_NOTFOUND, e.message, noTip),
                false,
                Code.USER_NOTFOUND);
          default:
//               return new ResultData(
//              Code.errorHandleFunction(
//                  Code.LOGIN_PASSWORD_ERROR, e.message, noTip),
//              false,
//              Code.LOGIN_PASSWORD_ERROR);
            break;
        }
      }
      if (errorResponse.statusCode == 302) {
        return new ResultData(
            Code.errorHandleFunction(errorResponse.statusCode, '', noTip),
            false,
            errorResponse.statusCode);
      }
      return new ResultData(
          Code.errorHandleFunction(errorResponse.statusCode, e.message, noTip,
              pushRouter: pushRouter),
          false,
          errorResponse.statusCode);
    }

    if (debug) {
      print('请求url: ' + url);
      print('请求头: ' + option.headers.toString());
      if (data != null) {
        print('请求参数: ' + data.toString());
      }
      if (response != null) {
        print('返回参数: ' + response.toString());
      }
      if (optionParams["Authorization"] != null) {
//        print('authorization: ' + optionParams["Authorization"]);
      }
    }

    try {
      if (option.contentType != null && option.contentType == "text") {
        return new ResultData(response.data, true, Code.SUCCESS);
      } else {
        var responseJson = response.data;
        if (responseJson["access_token"] != null) {
          optionParams["Authorization"] =
              'Bearer ' + responseJson["access_token"];
          await LocalStorage.save(this.tokenKey, responseJson["access_token"]);
          await LocalStorage.save(
              this.refreshTokenKey, responseJson["refresh_token"]);
        }
      }
      if (response.statusCode == 200 || response.statusCode == 201) {
        return new ResultData(response.data, true, Code.SUCCESS,
            headers: response.headers);
      }
    } catch (e) {
      print(e.toString() + url);
      return new ResultData(response.data, false, response.statusCode,
          headers: response.headers);
    }
    return new ResultData(
        Code.errorHandleFunction(response.statusCode, "", noTip),
        false,
        response.statusCode);
  }

  ///判断app的开发者模式
  checkDevelopment(String url) async {
    String development = await LocalStorage.get(this.developmentModeKey);
    if (development != null && development.isNotEmpty) {
      if (url.contains(prodHost)) {
        url = url.replaceAll(prodHost, devHost);
      }
    }
    return url;
  }

  ///清除授权
  clearAuthorization() {
    optionParams["Authorization"] = null;
    LocalStorage.remove(this.tokenKey);
    LocalStorage.remove(this.refreshTokenKey);
    //清除localstore中的userInfo
    LocalStorage.remove(this.userInfoKey);
  }

  ///获取授权token
  getAuthorization(String url) async {
    String token = await LocalStorage.get(this.tokenKey);
    if (token == null) {
      if (url.contains('oauth/token')) {
        String basic = await LocalStorage.get(this.userBasicCode);
        if (basic == null) {
//        提示输入账号密码
        } else {
//        通过 basic 去获取token，
          return "Basic $basic";
        }
      } else {
        return null;
      }
    } else {
      return 'Bearer ' + token;
//      optionParams["Authorization"] = 'Bearer ' + token;
//      return token;
    }
  }

  hasToken() async {
    String token = await LocalStorage.get(this.tokenKey);
    if (token == null || token.isEmpty) {
      return false;
    }
    return true;
  }

  refreshToken(dio, {url, params, header, option}) async {
    String refToken = await LocalStorage.get(this.refreshTokenKey);

    if (refToken != null) {
      String basic = await LocalStorage.get(this.userBasicCode);
      Response response;
      if (basic == null) {
        return null;
      }
      Map requestParams = {
//      "scopes": AuthConfig.SCOPE,
        "grant_type": 'refresh_token',
        "refresh_token": refToken,
//      "client_id": AuthConfig.CLIENT_ID,
//      "client_secret": AuthConfig.CLIENT_SECRET
      };

      Map<String, String> headers = new HashMap();
//      headers.addAll(antiReplay());
      headers["Authorization"] = 'Basic $basic';
      String refUrl = this.authorizationUrl;
      //auth/token 接口加入防重放列表，续约 token 实现需注意加入
      headers.addAll(antiReplay());
      Options refOption = new Options(
          headers: headers,
          method: "post",
          contentType: Headers.formUrlEncodedContentType);

      if (debug) {
        print('--------------------------');
        print('refresh请求前查看url：$refUrl');
        print('refresh请求前查看参数：${requestParams.toString()}');
        print('refresh请求前查看header：${refOption.headers.toString()}');
        print('--------------------------');
      }

      try {
        response =
            await dio.request(refUrl, data: requestParams, options: refOption);
      } on DioError catch (e) {
        //无论什么异常，将继续执行
        print(e);
        print(e.response);
      }

      if (response != null) {
        var responseJson = response.data;
        if (responseJson["access_token"] != null) {
          optionParams["Authorization"] =
              'Bearer ' + responseJson["access_token"];
          await LocalStorage.save(this.tokenKey, responseJson["access_token"]);
          await LocalStorage.save(
              this.refreshTokenKey, responseJson["refresh_token"]);
          //如果更新了token，重新请求当前的请求
          return netFetch(url, params, header, option);
        }
      }
      return null;
    } else {
      return null;
    }
  }
}
