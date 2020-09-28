import 'package:rondo_flutter_common/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  test('测试 LocalStorage 功能', () async {
    await LocalStorage.save('key', 'keySaved');
    expect((await LocalStorage.get('key')).toString(), 'keySaved');
    await LocalStorage.remove('key');
    expect(await LocalStorage.get('key'), null);
  });
}
