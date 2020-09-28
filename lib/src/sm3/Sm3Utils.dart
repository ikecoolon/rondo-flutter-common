import 'dart:typed_data';


import 'ByteUtils.dart';
import 'Sm3Digest.dart';

class Sm3Utils {
  static final Sm3Digest sm3Digest = new Sm3Digest();

  /**
   * 字节码SM3加密
   * @param sourceText	明文字节码
   * @return 加密字节码
   * @throws InvalidSourceDataException
   */
  static Int8List encryptFromData(Int8List sourceData) {
//		if(sourceData==null || sourceData.length == 0) {
//			throw new InvalidSourceDataException("[SM3:encryptFromData]invalid sourceData");
//		}
    Int8List encData = sm3Digest.getEncrypted(sourceData);
    return encData;
  }

  /**
   * 字符串SM3加密
   * @param sourceHex		明文16进制串
   * @return 16进制加密串
   * @throws InvalidSourceDataException
   */
  static String encryptFromHex(String sourceHex) {
//		if(StringUtils.isEmpty(sourceHex)) {
//			throw new InvalidSourceDataException("[SM3:encryptFromHex]invalid sourceData");
//		}
    Int8List sourceData = ByteUtils.hexToBytes(sourceHex);
    Int8List encData = sm3Digest.getEncrypted(sourceData);
    return ByteUtils.bytesToHex(encData);
  }

  /**
   * 字符串SM3加密
   * @param sourceText	明文字符串
   * @return 16进制加密串
   * @throws InvalidSourceDataException
   */
  static String encryptFromText(String sourceText) {
//		if(StringUtils.isEmpty(sourceText)) {
//			throw new InvalidSourceDataException("[SM3:encryptFromText]invalid sourceData");
//		}
    Int8List sourceData = ByteUtils.stringToBytes(sourceText);
    Int8List encData = sm3Digest.getEncrypted(sourceData);
    return ByteUtils.bytesToHex(encData);
  }
}
