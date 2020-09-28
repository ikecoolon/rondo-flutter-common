import 'dart:typed_data';

class SmCommonUtils {
  /**
   * 整形转换成网络传输的字节流（字节数组）型数据
   *
   * @param num 一个整型数据
   * @return 4个字节的自己数组
   */
  static Int8List intToBytes(int num) {
    Int8List bytes = new Int8List(4);
    bytes[0] = (0xff & (num >> 0));
    bytes[1] = (0xff & (num >> 8));
    bytes[2] = (0xff & (num >> 16));
    bytes[3] = (0xff & (num >> 24));
    return bytes;
  }

//
//	/**
//	 * 四个字节的字节数据转换成一个整形数据
//	 *
//	 * @param bytes 4个字节的字节数组
//	 * @return 一个整型数据
//	 */
  static int byteToInt(Int8List bytes) {
    int num = 0;
    int temp;
    temp = (0x000000ff & (bytes[0])) << 0;
    num = num | temp;
    temp = (0x000000ff & (bytes[1])) << 8;
    num = num | temp;
    temp = (0x000000ff & (bytes[2])) << 16;
    num = num | temp;
    temp = (0x000000ff & (bytes[3])) << 24;
    num = num | temp;
    return num;
  }

//
  /**
   * 长整形转换成网络传输的字节流（字节数组）型数据
   *
   * @param num 一个长整型数据
   * @return 4个字节的自己数组
   */
  static Int8List longToBytes(num) {
    Int8List bytes = new Int8List(8);
    for (int i = 0; i < 8; i++) {
      bytes[i] = (0xff & (num >> (i * 8)));
    }

    return bytes;
  }

  static List<int> bigIntToByteArray(BigInt data) {
    String str;
    bool neg = false;
    if (data < BigInt.zero) {
      str = (~data).toRadixString(16);
      neg = true;
    } else {
      str = data.toRadixString(16);
    }
    int p = 0;
    int len = str.length;

    int blen = (len + 1) ~/ 2;
    int boff = 0;
    List bytes;
    if (neg) {
      if (len & 1 == 1) {
        p = -1;
      }
      int byte0 = ~int.parse(str.substring(0, p + 2), radix: 16);
      if (byte0 < -128) byte0 += 256;
      if (byte0 >= 0) {
        boff = 1;
        bytes = new List<int>(blen + 1);
        bytes[0] = -1;
        bytes[1] = byte0;
      } else {
        bytes = new List<int>(blen);
        bytes[0] = byte0;
      }
      for (int i = 1; i < blen; ++i) {
        int byte = ~int.parse(str.substring(p + (i << 1), p + (i << 1) + 2),
            radix: 16);
        if (byte < -128) byte += 256;
        bytes[i + boff] = byte;
      }
    } else {
      if (len & 1 == 1) {
        p = -1;
      }
      int byte0 = int.parse(str.substring(0, p + 2), radix: 16);
      if (byte0 > 127) byte0 -= 256;
      if (byte0 < 0) {
        boff = 1;
        bytes = new List<int>(blen + 1);
        bytes[0] = 0;
        bytes[1] = byte0;
      } else {
        bytes = new List<int>(blen);
        bytes[0] = byte0;
      }
      for (int i = 1; i < blen; ++i) {
        int byte =
            int.parse(str.substring(p + (i << 1), p + (i << 1) + 2), radix: 16);
        if (byte > 127) byte -= 256;
        bytes[i + boff] = byte;
      }
    }
    return bytes;
  }

  /**
   * 大数字转换字节流（字节数组）型数据
   *
   * @param num bigInteger
   */
  static Int8List byteConvert32Bytes(BigInt num) {
    Int8List temp;
    if (num == null) {
      return null;
    }

    if (bigIntToByteArray(num).length == 33) {
      temp = new Int8List(32);
      _arraycopy(Int8List.fromList(bigIntToByteArray(num)), 1, temp, 0, 32);
    } else if (bigIntToByteArray(num).length == 32) {
      temp = Int8List.fromList(bigIntToByteArray(num));
    } else {
      temp = new Int8List(32);
      for (int i = 0; i < 32 - bigIntToByteArray(num).length; i++) {
        temp[i] = 0;
      }
      _arraycopy(Int8List.fromList(bigIntToByteArray(num)), 0, temp,
          32 - bigIntToByteArray(num).length, bigIntToByteArray(num).length);
    }
    return temp;
  }

//	/**
//	 * 换字节流（字节数组）型数据转大数字
//	 *
//	 * @param bytes 字节流
//	 */
//	 static BigInteger byteConvertInteger(Int8List bytes) {
//		if (bytes[0] < 0) {
//			Int8List temp = new byte[bytes.length + 1];
//			temp[0] = 0;
//			_arraycopy(bytes, 0, temp, 1, bytes.length);
//			return new BigInteger(temp);
//		}
//		return new BigInteger(bytes);
//	}
//
//	/**
//	 * 根据字节数组获得值(十六进制数字)
//	 *
//	 * @param bytes 字节流
//	 * @param upperCase 是否大写
//	 */
//	 static String getHexString(Int8List bytes) {
//		String ret = "";
//		for (int i = 0; i < bytes.length; i++) {
//			ret += Integer.toString((bytes[i] & 0xff) + 0x100, 16).substring(1);
//		}
//		return ret.toUpperCase();
//	}
//
//	/**
//	 * Convert hex string to Int8List
//	 *
//	 * @param hexString the hex string
//	 * @return Int8List
//	 */
//	 static Int8List hexStringToBytes(String hexString) {
//		if (hexString == null || hexString.equals("")) {
//			return null;
//		}
//
//		hexString = hexString.toUpperCase();
//		int length = hexString.length() / 2;
//		char[] hexChars = hexString.toCharArray();
//		Int8List d = new byte[length];
//		for (int i = 0; i < length; i++) {
//			int pos = i * 2;
//			d[i] = (byte) (charToByte(hexChars[pos]) << 4 | charToByte(hexChars[pos + 1]));
//		}
//		return d;
//	}
//
//	/**
//	 * Convert char to byte
//	 *
//	 * @param c char
//	 * @return byte
//	 */
//	 static byte charToByte(char c) {
//		return (byte) "0123456789ABCDEF".indexOf(c);
//	}
//
//	/**
//	 * 用于建立十六进制字符的输出的大写字符数组
//	 */
//	private static final char[] DIGITS_UPPER = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F' };
//
//	/**
//	 * 将字节数组转换为十六进制字符数组
//	 *
//	 * @param data Int8List
//	 * @param toLowerCase true:传换成小写格式 ,false:传换成大写格式
//	 * @return 十六进制char[]
//	 */
//	 static char[] encodeHex(Int8List data) {
//		return encodeHex(data, DIGITS_UPPER);
//	}
//
//	/**
//	 * 将字节数组转换为十六进制字符数组
//	 *
//	 * @param data Int8List
//	 * @param toDigits 用于控制输出的char[]
//	 * @return 十六进制char[]
//	 */
//	protected static char[] encodeHex(Int8List data, char[] toDigits) {
//		int l = data.length;
//		char[] out = new char[l << 1];
//		// two characters form the hex value.
//		for (int i = 0, j = 0; i < l; i++) {
//			out[j++] = toDigits[(0xF0 & data[i]) >>> 4];
//			out[j++] = toDigits[0x0F & data[i]];
//		}
//		return out;
//	}
//
//	/**
//	 * 将字节数组转换为十六进制字符串
//	 *
//	 * @param data Int8List
//	 * @param toLowerCase true:传换成小写格式,false:传换成大写格式
//	 * @return 十六进制String
//	 */
//	 static String encodeHexString(Int8List data) {
//		return encodeHexString(data, DIGITS_UPPER);
//	}
//
//	/**
//	 * 将字节数组转换为十六进制字符串
//	 *
//	 * @param data Int8List
//	 * @param toDigits 用于控制输出的char[]
//	 * @return 十六进制String
//	 */
//	protected static String encodeHexString(Int8List data, char[] toDigits) {
//		return new String(encodeHex(data, toDigits));
//	}
//
//	/**
//	 * 将十六进制字符数组转换为字节数组
//	 *
//	 * @param data 十六进制char[]
//	 * @return Int8List
//	 * @throws RuntimeException 如果源十六进制字符数组是一个奇怪的长度，将抛出运行时异常
//	 */
//	 static Int8List decodeHex(char[] data) {
//		int len = data.length;
//
//		if ((len & 0x01) != 0) {
//			throw new RuntimeException("Odd number of characters.");
//		}
//
//		Int8List out = new byte[len >> 1];
//
//		// two characters form the hex value.
//		for (int i = 0, j = 0; j < len; i++) {
//			int f = toDigit(data[j], j) << 4;
//			j++;
//			f = f | toDigit(data[j], j);
//			j++;
//			out[i] = (byte) (f & 0xFF);
//		}
//
//		return out;
//	}
//
//	/**
//	 * 将十六进制字符转换成一个整数
//	 *
//	 * @param ch 十六进制char
//	 * @param index 十六进制字符在字符数组中的位置
//	 * @return 一个整数
//	 * @throws RuntimeException 当ch不是一个合法的十六进制字符时，抛出运行时异常
//	 */
//	protected static int toDigit(char ch, int index) {
//		int digit = Character.digit(ch, 16);
//		if (digit == -1) {
//			throw new RuntimeException("Illegal hexadecimal character " + ch + " at index " + index);
//		}
//		return digit;
//	}
//
//	/**
//	 * 数字字符串转ASCII码字符串
//	 *
//	 * @param content String
//	 * @return ASCII字符串
//	 */
//	 static String StringToAsciiString(String content) {
//		String result = "";
//		int max = content.length();
//		for (int i = 0; i < max; i++) {
//			char c = content.charAt(i);
//			String b = Integer.toHexString(c);
//			result = result + b;
//		}
//		return result;
//	}
//
//	/**
//	 * 十六进制转字符串
//	 *
//	 * @param hexString 十六进制字符串
//	 * @param encodeType 编码类型4：Unicode，2：普通编码
//	 * @return 字符串
//	 */
//	 static String hexStringToString(String hexString, int encodeType) {
//		String result = "";
//		int max = hexString.length() / encodeType;
//		for (int i = 0; i < max; i++) {
//			char c = (char) hexStringToAlgorithm(hexString.substring(i * encodeType, (i + 1) * encodeType));
//			result += c;
//		}
//		return result;
//	}
//
//	/**
//	 * 十六进制字符串装十进制
//	 *
//	 * @param hex 十六进制字符串
//	 * @return 十进制数值
//	 */
//	 static int hexStringToAlgorithm(String hex) {
//		hex = hex.toUpperCase();
//		int max = hex.length();
//		int result = 0;
//		for (int i = max; i > 0; i--) {
//			char c = hex.charAt(i - 1);
//			int algorithm = 0;
//			if (c >= '0' && c <= '9') {
//				algorithm = c - '0';
//			} else {
//				algorithm = c - 55;
//			}
//			result += Math.pow(16, max - i) * algorithm;
//		}
//		return result;
//	}
//
//	/**
//	 * 十六转二进制
//	 *
//	 * @param hex 十六进制字符串
//	 * @return 二进制字符串
//	 */
//	 static String hexStringToBinary(String hex) {
//		hex = hex.toUpperCase();
//		String result = "";
//		int max = hex.length();
//		for (int i = 0; i < max; i++) {
//			char c = hex.charAt(i);
//			switch (c) {
//			case '0':
//				result += "0000";
//				break;
//			case '1':
//				result += "0001";
//				break;
//			case '2':
//				result += "0010";
//				break;
//			case '3':
//				result += "0011";
//				break;
//			case '4':
//				result += "0100";
//				break;
//			case '5':
//				result += "0101";
//				break;
//			case '6':
//				result += "0110";
//				break;
//			case '7':
//				result += "0111";
//				break;
//			case '8':
//				result += "1000";
//				break;
//			case '9':
//				result += "1001";
//				break;
//			case 'A':
//				result += "1010";
//				break;
//			case 'B':
//				result += "1011";
//				break;
//			case 'C':
//				result += "1100";
//				break;
//			case 'D':
//				result += "1101";
//				break;
//			case 'E':
//				result += "1110";
//				break;
//			case 'F':
//				result += "1111";
//				break;
//			}
//		}
//		return result;
//	}
//
//	/**
//	 * ASCII码字符串转数字字符串
//	 *
//	 * @param content ASCII字符串
//	 * @return 字符串
//	 */
//	 static String AsciiStringToString(String content) {
//		String result = "";
//		int length = content.length() / 2;
//		for (int i = 0; i < length; i++) {
//			String c = content.substring(i * 2, i * 2 + 2);
//			int a = hexStringToAlgorithm(c);
//			char b = (char) a;
//			String d = String.valueOf(b);
//			result += d;
//		}
//		return result;
//	}
//
//	/**
//	 * 将十进制转换为指定长度的十六进制字符串
//	 *
//	 * @param algorithm int 十进制数字
//	 * @param maxLength int 转换后的十六进制字符串长度
//	 * @return String 转换后的十六进制字符串
//	 */
//	 static String algorismToHexString(int algorithm, int maxLength) {
//		String result;
//		result = Integer.toHexString(algorithm);
//
//		if (result.length() % 2 == 1) {
//			result = "0" + result;
//		}
//		return patchHexString(result.toUpperCase(), maxLength);
//	}
//
//	/**
//	 * 字节数组转为普通字符串（ASCII对应的字符）
//	 *
//	 * @param byteArray Int8List
//	 * @return String
//	 */
//	 static String byteToString(Int8List byteArray) {
//		String result = "";
//		char temp;
//
//		int length = byteArray.length;
//		for (int i = 0; i < length; i++) {
//			temp = (char) byteArray[i];
//			result += temp;
//		}
//		return result;
//	}
//
//	/**
//	 * 二进制字符串转十进制
//	 *
//	 * @param binary 二进制字符串
//	 * @return 十进制数值
//	 */
//	 static int binaryToAlgorithm(String binary) {
//		int max = binary.length();
//		int result = 0;
//		for (int i = max; i > 0; i--) {
//			char c = binary.charAt(i - 1);
//			int algorithm = c - '0';
//			result += Math.pow(2, max - i) * algorithm;
//		}
//		return result;
//	}
//
//	/**
//	 * 十进制转换为十六进制字符串
//	 *
//	 * @param algorithm int 十进制的数字
//	 * @return String 对应的十六进制字符串
//	 */
//	 static String algorithmToHEXString(int algorithm) {
//		String result;
//		result = Integer.toHexString(algorithm);
//
//		if (result.length() % 2 == 1) {
//			result = "0" + result;
//
//		}
//		result = result.toUpperCase();
//
//		return result;
//	}
//
//	/**
//	 * HEX字符串前补0，主要用于长度位数不足。
//	 *
//	 * @param str String 需要补充长度的十六进制字符串
//	 * @param maxLength int 补充后十六进制字符串的长度
//	 * @return 补充结果
//	 */
//	static  String patchHexString(String str, int maxLength) {
//		String temp = "";
//		for (int i = 0; i < maxLength - str.length(); i++) {
//			temp = "0" + temp;
//		}
//		str = (temp + str).substring(0, maxLength);
//		return str;
//	}
//
//	/**
//	 * 将一个字符串转换为int
//	 *
//	 * @param s String 要转换的字符串
//	 * @param defaultInt int 如果出现异常,默认返回的数字
//	 * @param radix int 要转换的字符串是什么进制的,如16 8 10.
//	 * @return int 转换后的数字
//	 */
//	 static int parseToInt(String s, int defaultInt, int radix) {
//		int i;
//		try {
//			i = Integer.parseInt(s, radix);
//		} catch (NumberFormatException ex) {
//			i = defaultInt;
//		}
//		return i;
//	}
//
//	/**
//	 * 将一个十进制形式的数字字符串转换为int
//	 *
//	 * @param s String 要转换的字符串
//	 * @param defaultInt int 如果出现异常,默认返回的数字
//	 * @return int 转换后的数字
//	 */
//	 static int parseToInt(String s, int defaultInt) {
//		int i;
//		try {
//			i = Integer.parseInt(s);
//		} catch (NumberFormatException ex) {
//			i = defaultInt;
//		}
//		return i;
//	}
//
//	/**
//	 * 十六进制串转化为byte数组
//	 *
//	 * @return the array of byte
//	 */
//	 static Int8List hexToByte(String hex) throws IllegalArgumentException {
//		if (hex.length() % 2 != 0) {
//			throw new IllegalArgumentException();
//		}
//		char[] arr = hex.toCharArray();
//		Int8List b = new byte[hex.length() / 2];
//		for (int i = 0, j = 0, l = hex.length(); i < l; i++, j++) {
//			String swap = "" + arr[i++] + arr[i];
//			int byteInt = Integer.parseInt(swap, 16) & 0xFF;
//			b[j] = new Integer(byteInt).byteValue();
//		}
//		return b;
//	}
//
//	/**
//	 * 字节数组转换为十六进制字符串
//	 *
//	 * @param b Int8List 需要转换的字节数组
//	 * @return String 十六进制字符串
//	 */
//	 static String byteToHex(byte b[]) {
//		if (b == null) {
//			throw new IllegalArgumentException("Argument b ( byte array ) is null! ");
//		}
//		String hs = "";
//		String tmp;
//		for (int n = 0; n < b.length; n++) {
//			tmp = Integer.toHexString(b[n] & 0xff);
//			if (tmp.length() == 1) {
//				hs = hs + "0" + tmp;
//			} else {
//				hs = hs + tmp;
//			}
//		}
//		return hs.toUpperCase();
//	}
//
//	 static Int8List subByte(Int8List input, int startIndex, int length) {
//		Int8List bt = new byte[length];
//		for (int i = 0; i < length; i++) {
//			bt[i] = input[i + startIndex];
//		}
//		return bt;
//	}
  static Int8List _arraycopy(
      Int8List src, int srcPos, Int8List dest, int destPos, int length) {
    dest.setRange(
        destPos, destPos + length, src.sublist(srcPos, srcPos + length));
    return dest;
  }
}
