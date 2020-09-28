import 'dart:typed_data';

import 'ByteUtils.dart';
import 'Sm2Cipher.dart';


class Sm2Utils {
//	 CipherMode cipherMode = CipherMode.C1C2C3;
//
//	 Sm2Utils() {
//		this.cipherMode = CipherMode.C1C2C3;
//	}
//
//	/**
//	 * @param cipherMode	密文格式:C1C2C3,C1C3C2
//	 */
//	 Sm2Utils(CipherMode cipherMode) {
//		this.cipherMode = cipherMode;
//	}
//
////	/**
////	 * @param cipherMode	密文格式:C1C2C3,C1C3C2
////	 * @param randomKeyHex	随机数K的16进制串
////	 */
////	 Sm2Utils(CipherMode cipherMode, String randomKeyHex) {
////		this.sm2Cipher = new Sm2Cipher(cipherMode, randomKeyHex);
////	}
//
//	/**
//	 * 产生SM2公私钥对
//	 * @return
//	 */
//	 String[] generateKeyPair() {
//		Sm2Cipher sm2Cipher = new Sm2Cipher(this.cipherMode);
//		Sm2KeyPair keyPair = sm2Cipher.generateKeyPair();
//		return new String[]{
//				ByteUtils.bytesToHex(keyPair.getKey()),
//				ByteUtils.bytesToHex(keyPair.getKey())
//		};
//	}
//
  /// 字符串加密(字符串拼接模式)
  /// @param pubKeyHex		16进制串公钥
  /// @param sourceText 	字符串明文
  /// @return 字符串拼接方式16进制串密文
  /// @throws InvalidKeyException
  /// @throws IOException
  /// @throws InvalidSourceDataException
  String encryptFromText(String pubKeyHex, String sourceText) {
    if (this.invalidKey(pubKeyHex)) {
//			throw new InvalidKeyException("[SM2:encryptFromText]invalid pubKeyHex");
    }
    if (sourceText.length == 0) {
//			throw new InvalidSourceDataException("[SM2:encryptFromText]invalid sourceText");
    }
    if (pubKeyHex.length < 130 && !pubKeyHex.startsWith("04")) {
      pubKeyHex = "04" + pubKeyHex;
    }
    Int8List pubKeyBytes = ByteUtils.hexToBytes(pubKeyHex);
    Int8List sourceBytes = ByteUtils.stringToBytes(sourceText);
    Int8List dataBytes = this.encryptFromData(pubKeyBytes, sourceBytes);
    return ByteUtils.bytesToHex(dataBytes);
  }

//
//	/**
//	 * 16进制串加密(字符串拼接模式)
//	 * @param pubKeyHex		16进制串公钥
//	 * @param sourceHex		16进制串明文
//	 * @return 字符串拼接方式16进制串密文
//	 * @throws InvalidKeyException
//	 * @throws IOException
//	 * @throws InvalidSourceDataException
//	 */
//	 String encryptFromHex(String pubKeyHex, String sourceHex) throws InvalidKeyException, InvalidSourceDataException {
//		if(this.invalidKey(pubKeyHex)) {
//			throw new InvalidKeyException("[SM2:encryptFromHex]invalid pubKeyHex");
//        }
//		if(StringUtils.length(sourceHex) == 0) {
//			throw new InvalidSourceDataException("[SM2:encryptFromHex]invalid sourceHex");
//        }
//		if(pubKeyHex.length() < 130 && !pubKeyHex.startsWith("04")) {
//			pubKeyHex = "04" + pubKeyHex;
//        }
//		Int8List pubKeyBytes = ByteUtils.hexToBytes(pubKeyHex);
//		Int8List sourceBytes = ByteUtils.hexToBytes(sourceHex);
//		Int8List dataBytes = this.encryptFromData(pubKeyBytes, sourceBytes);
//		return ByteUtils.bytesToHex(dataBytes);
//	}
//
  /**
   * 字节码加密(字符串拼接模式)
   * @param pubKeyBytes	字节码公钥
   * @param sourceBytes	字节码明文
   * @return 字符串拼接方式字节码密文
   * @throws InvalidKeyException
   * @throws IOException
   * @throws InvalidSourceDataException
   */
  Int8List encryptFromData(Int8List pubKeyBytes, Int8List sourceBytes) {
    if (this.invalidKey(pubKeyBytes)) {
//			throw new InvalidKeyException("[SM2:encryptFromBytes]invalid pubKeyBytes");
    }
    if (sourceBytes == null || sourceBytes.length == 0) {
//			throw new InvalidSourceDataException("[SM2:encryptFromBytes]invalid sourceBytes");
    }
//		Sm2Cipher sm2Cipher = new Sm2Cipher(this.cipherMode);
    Sm2Cipher sm2Cipher = new Sm2Cipher();
    return sm2Cipher.encrypt(pubKeyBytes, sourceBytes);
  }

//
//	/**
//	 * 解密为字符串(字符串拼接模式)
//	 * @param prvKeyHex		16进制串私钥
//	 * @param cipherHex		16进制串密文
//	 * @return 明文字符串
//	 * @throws InvalidKeyException
//	 * @throws InvalidCryptoDataException
//	 */
//	 String decryptToText(String prvKeyHex, String cipherHex) throws InvalidKeyException, InvalidCryptoDataException {
//		if(this.invalidKey(prvKeyHex)) {
//			throw new InvalidKeyException("[SM2:decryptToText]invalid prvKeyHex");
//        }
//		if(this.invalidCipherObj(cipherHex)) {
//			throw new InvalidCryptoDataException("[SM2:decryptToText]invalid cipherHex");
//        }
//		Int8List prvKeyBytes = ByteUtils.hexToBytes(prvKeyHex);
//		Int8List cipherBytes = ByteUtils.hexToBytes(cipherHex);
//		Int8List sourceBytes = this.decryptToData(prvKeyBytes, cipherBytes);
//		return ByteUtils.bytesToString(sourceBytes);
//	}
//
//	/**
//	 * 解密为16进制串(字符串拼接模式)
//	 * @param prvKeyHex		16进制串私钥
//	 * @param cipherHex		16进制串密文
//	 * @return 明文16进制串
//	 * @throws InvalidKeyException
//	 * @throws InvalidCryptoDataException
//	 */
//	 String decryptToHex(String prvKeyHex, String cipherHex) throws InvalidKeyException, InvalidCryptoDataException {
//		if(this.invalidKey(prvKeyHex)) {
//			throw new InvalidKeyException("[SM2:decryptToHex]invalid prvKeyHex");
//        }
//		if(this.invalidCipherObj(cipherHex)) {
//			throw new InvalidCryptoDataException("[SM2:decryptToHex]invalid cipherHex");
//        }
//		Int8List prvKeyBytes = ByteUtils.hexToBytes(prvKeyHex);
//		Int8List cipherBytes = ByteUtils.hexToBytes(cipherHex);
//		Int8List sourceBytes = this.decryptToData(prvKeyBytes, cipherBytes);
//		return ByteUtils.bytesToHex(sourceBytes);
//	}
//
//	/**
//	 * 解密为字节码(字符串拼接模式)
//	 * @param prvKeyBytes	字节码私钥
//	 * @param cipherBytes	字节码密文
//	 * @return 明文字节码
//	 * @throws InvalidKeyException
//	 * @throws InvalidCryptoDataException
//	 */
//	 Int8List decryptToData(Int8List prvKeyBytes, Int8List cipherBytes) throws InvalidKeyException, InvalidCryptoDataException {
//		if(this.invalidKey(prvKeyBytes)) {
//			throw new InvalidKeyException("[SM2:decryptToData]invalid prvKeyBytes");
//        }
//		if(this.invalidCipherObj(cipherBytes)) {
//			throw new InvalidCryptoDataException("[SM2:decryptToData]invalid cipherBytes");
//        }
//		Sm2Cipher sm2Cipher = new Sm2Cipher(this.cipherMode);
//		return sm2Cipher.decrypt(prvKeyBytes, cipherBytes);
//	}
//
//	/**
//	 * 字符串加密(对象转换模式)
//	 * @param pubKeyHex		16进制串公钥
//	 * @param sourceText 	字符串明文
//	 * @return 对象转换模式16进制串密文
//	 * @throws InvalidKeyException
//	 * @throws InvalidSourceDataException
//	 */
//	 String encryptASN1FromText(String pubKeyHex, String sourceText) throws InvalidKeyException, InvalidSourceDataException {
//		if(this.invalidKey(pubKeyHex)) {
//			throw new InvalidKeyException("[SM2:encryptASN1FromText]invalid pubKeyHex");
//        }
//		if(StringUtils.length(sourceText) == 0) {
//			throw new InvalidSourceDataException("[SM2:encryptASN1FromText]invalid sourceText");
//        }
//		Int8List pubKeyBytes = ByteUtils.hexToBytes(pubKeyHex);
//		Int8List sourceBytes = ByteUtils.stringToBytes(sourceText);
//		Int8List dataBytes = this.encryptASN1FromData(pubKeyBytes, sourceBytes);
//		return ByteUtils.bytesToHex(dataBytes);
//	}
//
//	/**
//	 * 解密为字符串(对象转换模式)
//	 * @param prvKeyHex		16进制串私钥
//	 * @param cipherHex		16进制串密文
//	 * @return 明文字符串
//	 * @throws InvalidKeyException
//	 * @throws InvalidCryptoDataException
//	 */
//	 String decryptASN1ToText(String prvKeyHex, String cipherHex) throws InvalidKeyException, InvalidCryptoDataException {
//		if(this.invalidKey(prvKeyHex)) {
//			throw new InvalidKeyException("[SM2:decryptASN1ToText]invalid prvKeyHex");
//        }
//		if(this.invalidCipherObj(cipherHex)) {
//			throw new InvalidCryptoDataException("[SM2:decryptASN1ToText]invalid cipherHex");
//        }
//		Int8List prvKeyBytes = ByteUtils.hexToBytes(prvKeyHex);
//		Int8List cipherBytes = ByteUtils.hexToBytes(cipherHex);
//		Int8List sourceBytes = decryptASN1ToData(prvKeyBytes, cipherBytes);
//		return ByteUtils.bytesToString(sourceBytes);
//	}
//
//	/**
//	 * 16进制串加密(对象转换模式)
//	 * @param pubKeyHex		16进制串公钥
//	 * @param sourceHex 	16进制串明文
//	 * @return 对象转换模式16进制串密文
//	 * @throws InvalidKeyException
//	 * @throws InvalidSourceDataException
//	 */
//	 String encryptASN1FromHex(String pubKeyHex, String sourceHex) throws InvalidKeyException, InvalidSourceDataException {
//		if(this.invalidKey(pubKeyHex)) {
//			throw new InvalidKeyException("[SM2:encryptASN1FromHex]invalid pubKeyHex");
//        }
//		if(StringUtils.length(sourceHex) == 0) {
//			throw new InvalidSourceDataException("[SM2:encryptASN1FromHex]invalid sourceText");
//        }
//		Int8List pubKeyBytes = ByteUtils.hexToBytes(pubKeyHex);
//		Int8List sourceBytes = ByteUtils.hexToBytes(sourceHex);
//		Int8List dataBytes = this.encryptASN1FromData(pubKeyBytes, sourceBytes);
//		return ByteUtils.bytesToHex(dataBytes);
//	}
//
//	/**
//	 * 解密为16进制串(对象转换模式)
//	 * @param prvKeyHex		16进制串私钥
//	 * @param cipherHex		16进制串密文
//	 * @return 明文字符串
//	 * @throws InvalidKeyException
//	 * @throws InvalidCryptoDataException
//	 */
//	 String decryptASN1ToHex(String prvKeyHex, String cipherHex)  throws InvalidKeyException, InvalidCryptoDataException {
//		if(this.invalidKey(prvKeyHex)) {
//			throw new InvalidKeyException("[SM2:decryptASN1ToHex]invalid prvKeyHex");
//        }
//		if(this.invalidCipherObj(cipherHex)) {
//			throw new InvalidCryptoDataException("[SM2:decryptASN1ToHex]invalid cipherHex");
//        }
//		Int8List prvKeyBytes = ByteUtils.hexToBytes(prvKeyHex);
//		Int8List cipherBytes = ByteUtils.hexToBytes(cipherHex);
//		Int8List sourceBytes = decryptASN1ToData(prvKeyBytes, cipherBytes);
//		return ByteUtils.bytesToHex(sourceBytes);
//	}
//
//	/**
//	 * 字节码加密(对象转换模式)
//	 * @param pubKeyBytes	字节码公钥
//	 * @param sourceBytes	字节码明文
//	 * @return 对象转换模式字节码密文
//	 * @throws InvalidKeyException
//	 * @throws InvalidSourceDataException
//	 */
//	 Int8List encryptASN1FromData(Int8List pubKeyBytes, Int8List sourceBytes) throws InvalidKeyException, InvalidSourceDataException {
//		if(this.invalidKey(pubKeyBytes)) {
//			throw new InvalidKeyException("[SM2:encryptASN1FromData]invalid pubKeyBytes");
//        }
//		if(sourceBytes == null || sourceBytes.length == 0) {
//			throw new InvalidSourceDataException("[SM2:encryptASN1FromData]invalid sourceBytes");
//        }
//		Sm2Cipher sm2Cipher = new Sm2Cipher(this.cipherMode);
//		return sm2Cipher.encryptToASN1(pubKeyBytes, sourceBytes);
//	}
//
//	/**
//	 * 解密为字节码(对象转换模式)
//	 * @param prvKeyBytes	字节码私钥
//	 * @param cipherBytes	字节码密文
//	 * @return 明文字节码
//	 * @throws InvalidKeyException
//	 * @throws InvalidCryptoDataException
//	 */
//	 Int8List decryptASN1ToData(Int8List prvKeyBytes, Int8List cipherBytes) throws InvalidKeyException, InvalidCryptoDataException {
//		if(this.invalidKey(prvKeyBytes)) {
//			throw new InvalidKeyException("[SM2:decryptASN1ToData]invalid prvKeyBytes");
//        }
//		if(this.invalidCipherObj(cipherBytes)) {
//			throw new InvalidCryptoDataException("[SM2:decryptASN1ToData]invalid cipherBytes");
//        }
//		Sm2Cipher sm2Cipher = new Sm2Cipher(this.cipherMode);
//		return sm2Cipher.decryptFromASN1(prvKeyBytes, cipherBytes);
//	}
//
//	/**
//	 * 字符串签名
//	 * @param prvKeyHex		16进制串私钥
//	 * @param sourceText	字符串明文
//	 * @return
//	 * @throws InvalidKeyException
//	 * @throws InvalidSourceDataException
//	 */
//	 String signFromText(String prvKeyHex, String sourceText) throws InvalidKeyException, InvalidSourceDataException {
//		if(this.invalidKey(prvKeyHex)) {
//			throw new InvalidKeyException("[SM2:signFromText]invalid prvKeyHex");
//        }
//		if(StringUtils.length(sourceText) == 0) {
//			throw new InvalidSourceDataException("[SM2:signFromText]invalid sourceText");
//        }
//		Int8List prvKeyBytes = ByteUtils.hexToBytes(prvKeyHex);
//		Int8List sourceBytes = ByteUtils.stringToBytes(sourceText);
//		Int8List signBytes = signFromData(prvKeyBytes, sourceBytes);
//		return ByteUtils.bytesToHex(signBytes);
//	}
//
//	/**
//	 * 16进制串签名
//	 * @param prvKeyHex		16进制串私钥
//	 * @param sourceHex		16进制串明文
//	 * @return
//	 * @throws InvalidKeyException
//	 * @throws InvalidSourceDataException
//	 */
//	 String signFromHex(String prvKeyHex, String sourceHex) throws InvalidKeyException, InvalidSourceDataException {
//		if(this.invalidKey(prvKeyHex)) {
//			throw new InvalidKeyException("[SM2:signFromHex]invalid prvKeyHex");
//        }
//		if(StringUtils.length(sourceHex) == 0) {
//			throw new InvalidSourceDataException("[SM2:signFromHex]invalid sourceText");
//        }
//		Int8List prvKeyBytes = ByteUtils.hexToBytes(prvKeyHex);
//		Int8List sourceBytes = ByteUtils.hexToBytes(sourceHex);
//		Int8List signBytes = signFromData(prvKeyBytes, sourceBytes);
//		return ByteUtils.bytesToHex(signBytes);
//	}
//
//	/**
//	 * 字节码签名
//	 * @param prvKeyBytes	字节码私钥
//	 * @param sourceBytes	字节码明文
//	 * @return
//	 * @throws InvalidKeyException
//	 * @throws InvalidSourceDataException
//	 */
//	 Int8List signFromData(Int8List prvKeyBytes, Int8List sourceBytes) throws InvalidKeyException, InvalidSourceDataException {
//		if(this.invalidKey(prvKeyBytes)) {
//			throw new InvalidKeyException("[SM2:signFromData]invalid prvKeyBytes");
//        }
//		if(sourceBytes == null || sourceBytes.length == 0) {
//			throw new InvalidSourceDataException("[SM2:signFromData]invalid sourceBytes");
//        }
//		Sm2Cipher sm2Cipher = new Sm2Cipher(this.cipherMode);
//		return sm2Cipher.signToASN1(prvKeyBytes, sourceBytes);
//	}
//
//	/**
//	 * 字符串验签
//	 * @param pubKeyHex		16进制串公钥
//	 * @param sourceText	字符串明文
//	 * @param signHex		16进制串签名
//	 * @return
//	 * @throws InvalidSignDataException
//	 * @throws InvalidKeyException
//	 * @throws InvalidSourceDataException
//	 */
//	 boolean verifySignFromText(String pubKeyHex, String sourceText, String signHex) throws InvalidSignDataException, InvalidKeyException, InvalidSourceDataException {
//		if(this.invalidKey(pubKeyHex)) {
//			throw new InvalidKeyException("[SM2:verifySignFromText]invalid pubKeyHex");
//        }
//		if(StringUtils.length(sourceText) == 0) {
//			throw new InvalidSourceDataException("[SM2:verifySignFromText]invalid sourceText");
//        }
//		if(StringUtils.length(signHex) == 0) {
//			throw new InvalidSourceDataException("[SM2:verifySignFromHex]invalid signHex");
//        }
//		Int8List pubKeyBytes = ByteUtils.hexToBytes(pubKeyHex);
//		Int8List sourceBytes = ByteUtils.stringToBytes(sourceText);
//		Int8List signBytes = ByteUtils.hexToBytes(signHex);
//		return verifySignFromData(pubKeyBytes, sourceBytes, signBytes);
//	}
//
//	/**
//	 * 16进制串验签
//	 * @param pubKeyHex		16进制串公钥
//	 * @param sourceHex		16进制串明文
//	 * @param signHex		16进制串签名
//	 * @return
//	 * @throws InvalidSignDataException
//	 * @throws InvalidKeyException
//	 * @throws InvalidSourceDataException
//	 */
//	 boolean verifySignFromHex(String pubKeyHex, String sourceHex, String signHex) throws InvalidKeyException, InvalidSourceDataException, InvalidSignDataException {
//		if(this.invalidKey(pubKeyHex)) {
//			throw new InvalidKeyException("[SM2:verifySignFromHex]invalid pubKeyHex");
//        }
//		if(StringUtils.length(sourceHex) == 0) {
//			throw new InvalidSourceDataException("[SM2:verifySignFromHex]invalid sourceText");
//        }
//		if(StringUtils.length(signHex) == 0) {
//			throw new InvalidSourceDataException("[SM2:verifySignFromHex]invalid signHex");
//        }
//		Int8List pubKeyBytes = ByteUtils.hexToBytes(pubKeyHex);
//		Int8List sourceBytes = ByteUtils.hexToBytes(sourceHex);
//		Int8List signBytes = ByteUtils.hexToBytes(signHex);
//		return verifySignFromData(pubKeyBytes, sourceBytes, signBytes);
//	}
//
//	/**
//	 * 字节码验签
//	 * @param pubKeyBytes	字节码公钥
//	 * @param sourceBytes	字节码明文
//	 * @param signBytes		字节码签名
//	 * @return
//	 * @throws InvalidSignDataException
//	 * @throws InvalidKeyException
//	 * @throws InvalidSourceDataException
//	 */
//	 boolean verifySignFromData(Int8List pubKeyBytes, Int8List sourceBytes, Int8List signBytes) throws InvalidSignDataException, InvalidKeyException, InvalidSourceDataException {
//		if(this.invalidKey(pubKeyBytes)) {
//			throw new InvalidKeyException("[SM2:verifySignFromData]invalid pubKeyBytes");
//        }
//		if(sourceBytes == null || sourceBytes.length == 0) {
//			throw new InvalidSourceDataException("[SM2:verifySignFromData]invalid sourceBytes");
//        }
//		if(signBytes == null || signBytes.length == 0) {
//			throw new InvalidSignDataException("[SM2:verifySignFromData]invalid signBytes");
//        }
//		Sm2Cipher sm2Cipher = new Sm2Cipher(this.cipherMode);
//		return sm2Cipher.verifySignByASN1(pubKeyBytes, sourceBytes, signBytes);
//	}
//
  static List<int> keyHexLenList =
      Int32List.fromList([60, 62, 64, 66, 68, 128]);

//
  static List<int> keyByteLenList =
      Int32List.fromList([30, 31, 32, 33, 34, 64]);

//
//
  /// 验证是否是无效的Key
  /// @param keyObj
  /// @return
  bool invalidKey(final Object keyObj) {
    if (keyObj == null) {
      return true;
    } else if (keyObj is String) {
      String keyString = keyObj;
      int keyLength = keyString.length;
      if (keyLength == 130 && keyString.startsWith("04")) {
        return false;
      } else if (keyHexLenList.contains(keyLength)) {
        return false;
      } else {
        return true;
      }
    } else if (keyObj is Int8List) {
      Int8List keyBytes = keyObj;
      if (keyBytes.length == 65 && keyBytes[0] == 4) {
        return false;
      } else if (keyByteLenList.contains(keyBytes.length)) {
        return false;
      } else {
        return true;
      }
    } else {
      return true;
    }
  }
//
//	/**
//	 * 验证是否是无效的密文
//	 * @param cipherObj
//	 * @return
//	 */
//	 final boolean invalidCipherObj(final Object cipherObj) {
//		if(cipherObj == null) {
//			return true;
//		} else if(cipherObj instanceof String) {
//			String cipherHex = (String)cipherObj;
//			int cipherLength = cipherHex.length();
//			if(cipherLength < 196 || cipherLength%2 == 1) {
//				return true;
//			} else {
//				return false;
//			}
//		} else if(cipherObj instanceof Int8List) {
//			Int8List cipherBytes = (Int8List)cipherObj;
//			if(cipherBytes.length < 98) {
//				return true;
//			} else {
//				return false;
//			}
//		} else {
//			return true;
//		}
//	}

}
