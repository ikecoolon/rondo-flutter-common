import 'package:rondo_flutter_common/src/net/PushAndRedirect.dart';

class HttpErrorEvent {
  final int code;
  final PushAndRedirect pushRouter;
  final String message;

  HttpErrorEvent(this.code, this.message, {this.pushRouter});
}
