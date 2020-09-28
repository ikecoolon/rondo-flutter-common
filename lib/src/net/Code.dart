import 'package:rondo_flutter_common/main.dart';
import 'package:rondo_flutter_common/src/event/BusinessEvent.dart';
import 'package:event_bus/event_bus.dart';
import 'package:rondo_flutter_common/src/net/PushAndRedirect.dart';

///错误编码
class Code {
  ///网络错误
  static const NETWORK_ERROR = -1;

  ///网络超时
  static const NETWORK_TIMEOUT = -2;

  ///网络返回数据格式化一次
  static const NETWORK_JSON_EXCEPTION = -3;

  ///网关密码错误
  static const LOGIN_PASSWORD_ERROR = -4;

  ///网关验证码错误
  static const LOGIN_SMS_ERROR = -5;

  ///账号锁定
  static const USER_LOCKED = -6;

  //账号休眠
  static const USER_DORMANCY = -9;

  //帐号不存在
  static const USER_NOTFOUND = -10;

  static const SUCCESS = 200;

  ///验证码长度错误
  static const LOGIN_SMS_ERRORLENGTH = -7;

  ///网关验证码字符错误
  static const LOGIN_SMS_ERRORCHAR = -8;

  static final EventBus eventBus = new EventBus();

  static errorHandleFunction(code, message, noTip,
      { dynamic busCode, businessData,PushAndRedirect pushRouter}) {
//    print('发出http异常事件');
//    print(code.toString()+"|"+message.toString()+'|'+noTip.toString());

    if (busCode!=null) {
      eventBus.fire(new BusinessEvent(busCode, data: businessData));
      return message;
    }

    if (noTip) {
      return message;
    }

    if(pushRouter!=null){
      eventBus.fire(new HttpErrorEvent(code, message,pushRouter: pushRouter));
    }else{
      eventBus.fire(new HttpErrorEvent(code, message));

    }


    return message;
  }
}
