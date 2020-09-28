import 'dart:convert';
import 'dart:core';
import 'dart:typed_data';

/// 16进制与字节码转换工具
/// @author bgu
///
class ByteUtils {
  static final String HEX_STRING_MAPPING = "0123456789ABCDEF";

  static final String CHARSET_NAME = "UTF-8";

  /// 字节码转为大写16进制串
  /// @param bytes
  /// @return
  static String bytesToHex(Int8List bytes) {
    if (bytes == null) {
      return null;
    }
    if (bytes.length <= 0) {
      return "";
    }
    StringBuffer stringBuilder = new StringBuffer("");
    for (var unit in bytes) {
      int unitInt = unit & 0xFF;
//            String unitHex = charToUnicodeString(unitInt).toString();
      String unitHex = unitInt.toRadixString(16).toString();
      if (unitHex.length < 2) {
        stringBuilder.write(0);
      }
      stringBuilder.write(unitHex);
    }
    return stringBuilder.toString().toUpperCase();
  }

  static String charToUnicodeString(int char) => (char < 0 || char > 0xFFFFFF)
      ? throw new ArgumentError("out of Unicode range: $char")
      : char <= 0xFFFF
          ? "\\u${(char + 0x10000).toRadixString(16).substring(1)}"
          : "\\u{${char.toRadixString(16)}}";

  /// 16进制串转为字节码
  /// @param hexString
  /// @return
  static Int8List hexToBytes(String hexString) {
    if (hexString == null) {
      return null;
    }
    if (hexString.length <= 0) {
      return new Int8List(0);
    }
    hexString = hexString.toUpperCase();
    int length = hexString.length ~/ 2;
//		 char[] hexChars = hexString.toCharArray();
    List hexChars = new List();
//		 for(int i=0;i<hexString.length;i++){
//		 	hexChars[i]=hexString
//		 }
    hexString.runes.forEach((int rune) {
      hexChars.add(new String.fromCharCode(rune));

//		 print(new String.fromCharCode(rune));
    });
    Int8List result = new Int8List(length);
    for (int i = 0; i < length; i++) {
      int step = i * 2;
      result[i] =
          (charToByte(hexChars[step]) << 4 | charToByte(hexChars[step + 1]));
//			 result[i] =  (charToByte(hexChars.elementAt(step).toString()) << 4 | charToByte(hexChars.elementAt(step + 1).toString()));
    }

    return result;
  }

//	/**
//	 * 字节码转为字符串
//	 * @param bytes
//	 * @return
//	 */
//	 static String bytesToString(Int8List bytes) {
//		try {
//			return new String(bytes, CHARSET_NAME);
//		} catch (UnsupportedEncodingException e) {
//			return null;
//		}
//	}

  /**
   * 字符串转为字节码转
   * @param str
   * @return
   */
  static Int8List stringToBytes(String str) {
    try {
//			return str.codeUnits;
      return Int8List.fromList(utf8.encode(str));
    } catch (UnsupportedEncodingException) {
      return null;
    }
  }

//
//	/**
//	 * 16进制串转为字符串
//	 * @param hexString
//	 * @return
//	 */
//	 static String hexToString(String hexString) {
//		return bytesToString(hexToBytes(hexString));
//	}
//
//	/**
//	 * 字符串转为16进制串
//	 * @param str
//	 * @return
//	 */
//	 static String stringToHex(String str) {
//		return bytesToHex(stringToBytes(str));
//	}
//
//	/**
//	 * 字符转为字节
//	 * @param c
//	 * @return
//	 */
  static charToByte(c) {
    return HEX_STRING_MAPPING.indexOf(c);
  }
}
