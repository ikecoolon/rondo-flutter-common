import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

class AostarWebViewCommonPage extends StatefulWidget {
  AostarWebViewCommonPage({Key key, this.title, this.url, this.jsFuncStr, this.hiddenButtonBar, this.barTextColor})
      : super(key: key);

  final String title;
  final String url;
  final bool hiddenButtonBar;
  final Color barTextColor;
  final String jsFuncStr;

  @override
  State<StatefulWidget> createState() {
    return new AostarWebViewCommonPageState();
  }
}

class AostarWebViewCommonPageState extends State<AostarWebViewCommonPage> {
  final flutterWebViewPlugin = FlutterWebviewPlugin();
  String currentUrl;
  StreamSubscription<String> _onUrlChanged;
  StreamSubscription<WebViewStateChanged> _onStateChanged;
  StreamSubscription _onDestroy;

  String title = '';

  bool hiddenButtonBar = false;

  @override
  void initState() {
    if (widget.hiddenButtonBar != null) {
      hiddenButtonBar = widget.hiddenButtonBar;
    } else {
      hiddenButtonBar = true;
    }

    super.initState();
    title = widget.title;
    _onUrlChanged = flutterWebViewPlugin.onUrlChanged.listen((url) {
      debugPrint("url:$url");

      //在这里处理特殊url的去向，包括传值

      currentUrl = url;
    });

    _onStateChanged = flutterWebViewPlugin.onStateChanged.listen((state) {
      if (state.type == WebViewState.finishLoad) {
        debugPrint(state.type.toString());
        findHtmlTitle();
        //做些js操作
        if (widget.jsFuncStr != null && widget.jsFuncStr.isNotEmpty) {
          flutterWebViewPlugin.evalJavascript(widget.jsFuncStr).then((value) {});
        }
      }
    });

    flutterWebViewPlugin.onDestroy.listen((_) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _onDestroy?.cancel();
    _onUrlChanged?.cancel();
    _onStateChanged?.cancel();
    flutterWebViewPlugin.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new WebviewScaffold(
      url: widget.url,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          title,
          style: new TextStyle(fontSize: 18, color: widget.barTextColor ?? Color(0xff444444)),
        ),
      ),
      withZoom: true,
      withLocalStorage: true,
      hidden: true,
      initialChild: Container(
//                      color: Colors.redAccent,
        child: const Center(
          child: Text('加载中.....'),
        ),
      ),
      bottomNavigationBar: hiddenButtonBar
          ? null
          : BottomAppBar(
              child: Row(
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () {
                      flutterWebViewPlugin.goBack();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: () {
                      flutterWebViewPlugin.goForward();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.autorenew),
                    onPressed: () {
                      flutterWebViewPlugin.reload();
                    },
                  ),
                ],
              ),
            ),
    );
  }

  void findHtmlTitle() async {
    flutterWebViewPlugin.evalJavascript("document.title").then((String title) {
      setState(() {
        if (Platform.isAndroid && title.trim().length > 1) {
          this.title = title.replaceAll('"', '');
        } else {
          this.title = title;
        }
      });
    });
  }

//  Future<bool> _onWillPop() {
//    flutterWebViewPlugin.close();
//    return Future.value(currentUrl == widget.url);
//  }
}
