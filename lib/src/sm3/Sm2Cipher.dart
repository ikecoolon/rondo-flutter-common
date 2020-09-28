import "dart:math" as Math;
import 'dart:typed_data';

import 'package:pointycastle/ecc/ecc_base.dart';
import 'package:pointycastle/ecc/ecc_fp.dart';
import 'package:pointycastle/export.dart' hide ECPoint, ECCurve, ECFieldElement;
import 'package:pointycastle/key_generators/ec_key_generator.dart';

import 'ByteUtils.dart';
import 'CipherMode.dart';
import 'Sm2EncryptedData.dart';
import 'Sm3Digest.dart';
import 'SmCommonUtils.dart';

/**
 * SM2加密器
 * 注意:由于对象内存在buffer, 请勿多线程同时操作一个实例, 每次new一个Cipher使用,或使用ThreadLocal保持每个线程一个Cipher实例.
 *
 */
class Sm2Cipher {
  /**
   * SM2的ECC椭圆曲线参数
   */
  final BigInt SM2_ECC_P = BigInt.parse(
      "FFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFFFFFF",
      radix: 16);
  final BigInt SM2_ECC_A = BigInt.parse(
      "FFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFFFFFC",
      radix: 16);
  final BigInt SM2_ECC_B = BigInt.parse(
      "28E9FA9E9D9F5E344D5A9E4BCF6509A7F39789F515AB8F92DDBCBD414D940E93",
      radix: 16);
  final BigInt SM2_ECC_N = BigInt.parse(
      "FFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFF7203DF6B21C6052B53BBF40939D54123",
      radix: 16);
  final BigInt SM2_ECC_GX = BigInt.parse(
      "32C4AE2C1F1981195F9904466A39C9948FE30BBFF2660BE1715A4589334C74C7",
      radix: 16);
  final BigInt SM2_ECC_GY = BigInt.parse(
      "BC3736A2F4F6779C59BDCEE36B692153D0A9877CC62A474002DF32E52139F0A0",
      radix: 16);

//
//	 final Int8List DEFAULT_USER_ID = "1234567812345678".getBytes();
//
  ECCurve curve; // ECC曲线
  ECPoint pointG; // 基点
  ECKeyGenerator keyPairGenerator; // 密钥对生成器
  CipherMode cipherMode; // 密文格式
//
  ECPoint alternateKeyPoint;
  Sm3Digest alternateKeyDigest;
  Sm3Digest c3Digest;
  int alternateKeyCount;
  Int8List alternateKey;
  int alternateKeyOff;

//
////	private String randomKeyHex;
//
  Sm2Cipher() {
//		this(CipherMode.C1C2C3);
    cipherMode = CipherMode.C1C2C3;
    SecureRandom secureRandom = new SecureRandom('AES/CTR/PRNG');
    Math.Random r = new Math.Random();
    final keyBytes = [
      r.nextInt(256),
      r.nextInt(256),
      r.nextInt(256),
      r.nextInt(256),
      r.nextInt(256),
      r.nextInt(256),
      r.nextInt(256),
      r.nextInt(256),
      r.nextInt(256),
      r.nextInt(256),
      r.nextInt(256),
      r.nextInt(256),
      r.nextInt(256),
      r.nextInt(256),
      r.nextInt(256),
      r.nextInt(256),
    ];
    secureRandom.seed(new KeyParameter(Uint8List.fromList(keyBytes)));
//		BlockCtrRandom secureRandom = new BlockCtrRandom(new AESFastEngine());
    this.cipherMode = cipherMode;

    // 曲线
    ECFieldElement gxFieldElement = new ECFieldElement(SM2_ECC_P, SM2_ECC_GX);
    ECFieldElement gyFieldElement = new ECFieldElement(SM2_ECC_P, SM2_ECC_GY);
    this.curve = new ECCurve(SM2_ECC_P, SM2_ECC_A, SM2_ECC_B);

    // 密钥对生成器
    this.pointG = new ECPoint(curve, gxFieldElement, gyFieldElement);
    ECDomainParametersImpl domainParams =
        new ECDomainParametersImpl('', curve, pointG, SM2_ECC_N);

//		ECKeyGeneratorParameters keyGenerationParams = ECKeyGeneratorParameters(domainParams);
    ParametersWithRandom keyGenerationParams = new ParametersWithRandom(
        new ECKeyGeneratorParameters(domainParams), secureRandom);
    this.keyPairGenerator = new ECKeyGenerator();
    this.keyPairGenerator.init(keyGenerationParams);
//		secureRandom.seed(keyGenerationParams);
  }

//
//	/**
//	 * 默认椭圆曲线参数的SM2加密器
//	 *
//	 * @param type	密文格式
//	 */
//	 Sm2Cipher(CipherMode cipherMode) {
//		this(new SecureRandom(), cipherMode);
//	}
//
////	/**
////	 * 默认椭圆曲线参数的SM2加密器
////	 *
////	 * @param type	密文格式
////	 */
////	 Sm2Cipher(CipherMode cipherMode, String randomKeyHex) {
////		this(new SecureRandom(), cipherMode);
////		this.randomKeyHex = randomKeyHex;
////	}
//
//	/**
//	 * 默认椭圆曲线参数的SM2加密器
//	 *
//	 * @param secureRandom	秘钥生成随机数
//	 * @param type	密文格式
//	 */
//	private Sm2Cipher(SecureRandom secureRandom, CipherMode cipherMode) {
//		this(secureRandom, cipherMode, SM2_ECC_P, SM2_ECC_A, SM2_ECC_B, SM2_ECC_N, SM2_ECC_GX, SM2_ECC_GY);
//	}
//
//	/**
//	 * 默认椭圆曲线参数的SM2加密器
//	 *
//	 * @param secureRandom	秘钥生成随机数
//	 * @param type	密文格式
//	 * @param eccP	p
//	 * @param eccA	a
//	 * @param eccB	b
//	 * @param eccN	n
//	 * @param eccGx	gx
//	 * @param eccGy	gy
//	 */
//	private Sm2Cipher(SecureRandom secureRandom, CipherMode cipherMode, BigInt eccP, BigInt eccA, BigInt eccB, BigInt eccN, BigInt eccGx, BigInt eccGy) {
//		//if (type == null) {
//		//	throw new InvalidCryptoParamsException("[SM2]type of the SM2Cipher is null");
//		//}
//		if (eccP == null || eccA == null || eccB == null || eccN == null || eccGx == null || eccGy == null) {
//			throw new InvalidCryptoParamsException("[SM2]ecc params of the SM2Cipher is null");
//		}
//		if (secureRandom == null) {
//			secureRandom = new SecureRandom();
//		}
//		this.cipherMode = cipherMode;
//
//		// 曲线
//		ECFieldElement.Fp gxFieldElement = new ECFieldElement.Fp(eccP, eccGx);
//		ECFieldElement.Fp gyFieldElement = new ECFieldElement.Fp(eccP, eccGy);
//		this.curve = new ECCurve.Fp(eccP, eccA, eccB);
//
//		// 密钥对生成器
//		this.pointG = new ECPoint.Fp(curve, gxFieldElement, gyFieldElement);
//		ECDomainParameters domainParams = new ECDomainParameters(curve, pointG, eccN);
//		ECKeyGenerationParameters keyGenerationParams = new ECKeyGenerationParameters(domainParams, secureRandom);
//		this.keyPairGenerator = new ECKeyPairGenerator();
//		this.keyPairGenerator.init(keyGenerationParams);
//
//	}
//
  void resetKey() {
    this.alternateKeyDigest = new Sm3Digest();
    this.c3Digest = new Sm3Digest();
    Int8List x =
        SmCommonUtils.byteConvert32Bytes(alternateKeyPoint.x.toBigInteger());
    Int8List y =
        SmCommonUtils.byteConvert32Bytes(alternateKeyPoint.y.toBigInteger());
    this.c3Digest.update(x, 0, x.length);

    this.alternateKeyDigest.updateFromByteList(x);
    this.alternateKeyDigest.updateFromByteList(y);
    this.alternateKeyCount = 1;
    nextKey();
  }

//
  void nextKey() {
    Sm3Digest digest = new Sm3Digest.oneParam(this.alternateKeyDigest);
    digest.updateSimple((alternateKeyCount >> 24 & 0xff));
    digest.updateSimple((alternateKeyCount >> 16 & 0xff));
    digest.updateSimple((alternateKeyCount >> 8 & 0xff));
    digest.updateSimple((alternateKeyCount & 0xff));
    alternateKey = digest.doFinalWithReturn();
    this.alternateKeyOff = 0;
    this.alternateKeyCount++;
  }

//
//	private final Int8List getZ(Int8List userId, ECPoint userKey) {
//		Sm3Digest digest = new Sm3Digest();
//		if (userId == null) {
//			userId = DEFAULT_USER_ID;
//		}
//
//		int len = userId.length * 8;
//		digest.update((byte) (len >> 8 & 0xFF));
//		digest.update((byte) (len & 0xFF));
//		digest.update(userId);
//
//		Int8List p = CommonUtils.byteConvert32Bytes(SM2_ECC_A);
//		digest.update(p);
//		p = CommonUtils.byteConvert32Bytes(SM2_ECC_B);
//		digest.update(p);
//		p = CommonUtils.byteConvert32Bytes(SM2_ECC_GX);
//		digest.update(p);
//		p = CommonUtils.byteConvert32Bytes(SM2_ECC_GY);
//		digest.update(p);
//		p = CommonUtils.byteConvert32Bytes(userKey.getX().toBigInt());
//		digest.update(p);
//		p = CommonUtils.byteConvert32Bytes(userKey.getY().toBigInt());
//		digest.update(p);
//
//		return digest.doFinal();
//	}
//
//	/**
//	 * @return 产生SM2公私钥对(随机)
//	 */
//	 final Sm2KeyPair generateKeyPair() {
//		AsymmetricCipherKeyPair keyPair = keyPairGenerator.generateKeyPair();
//		ECPrivateKeyParameters privateKeyParams = (ECPrivateKeyParameters) keyPair.getPrivate();
//		ECKeyParameters KeyParams = (ECKeyParameters) keyPair.get();
//		BigInt privateKey = privateKeyParams.getD();
//		ECPoint Key = KeyParams.getQ();
//		return new Sm2KeyPair(privateKey.toByteArray(), Key.getEncoded());
//	}
//
  /// SM2加密, ASN.1编码
  /// @param pubKeyBytes	公钥
  /// @param dataBytes		数据
  /// @throws InvalidKeyException
  /// @throws InvalidCryptoDataException
  Int8List encrypt(Int8List pubKeyBytes, Int8List dataBytes) {
    Sm2EncryptedData encryptedData = encryptInner(pubKeyBytes, dataBytes);
    if (encryptedData == null) {
      return null;
    }
    ECPoint c1 = encryptedData.getC1();
    Int8List c2 = encryptedData.getC2();
    Int8List c3 = encryptedData.getC3();
    // C1 C2 C3拼装成加密字串
    String encHex;
    switch (this.cipherMode) {
      case CipherMode.C1C2C3:
//        Int8List s = Int8List.fromList(c1.getEncoded(false));
//        print(s);
        encHex = ByteUtils.bytesToHex(Int8List.fromList(c1.getEncoded(false))) +
            ByteUtils.bytesToHex(c2) +
            ByteUtils.bytesToHex(c3);
        break;
      case CipherMode.C1C3C2:
        encHex = ByteUtils.bytesToHex(Int8List.fromList(c1.getEncoded())) +
            ByteUtils.bytesToHex(c3) +
            ByteUtils.bytesToHex(c2);
        break;
      default:
//			throw new InvalidCryptoParamsException("[SM2:Encrypt]invalid type(" + String.valueOf(this.cipherMode) + ")");
    }
    return ByteUtils.hexToBytes(encHex);
  }

//
//	/**
//	 * SM2加密, ASN.1编码
//	 * @param pubKeyBytes	公钥
//	 * @param data	数据
//	 * @throws InvalidKeyException
//	 */
//	protected final Int8List encryptToASN1(Int8List pubKeyBytes, Int8List data) throws InvalidKeyException {
//		Sm2EncryptedData encryptedData = encryptInner(pubKeyBytes, data);
//		if (encryptedData == null) {
//			return null;
//		}
//		ECPoint c1 = encryptedData.getC1();
//		Int8List c2 = encryptedData.getC2();
//		Int8List c3 = encryptedData.getC3();
//
//		DERInteger x = new DERInteger(c1.getX().toBigInt());
//		DERInteger y = new DERInteger(c1.getY().toBigInt());
//		DEROctetString derC2 = new DEROctetString(c2);
//		DEROctetString derC3 = new DEROctetString(c3);
//		ASN1EncodableVector vector = new ASN1EncodableVector();
//		vector.add(x);
//		vector.add(y);
//		switch (this.cipherMode) {
//		case C1C2C3:
//			vector.add(derC2);
//			vector.add(derC3);
//			break;
//		case C1C3C2:
//			vector.add(derC3);
//			vector.add(derC2);
//			break;
//		default:
//			throw new InvalidCryptoParamsException("[SM2:EncryptASN1]invalid type(" + String.valueOf(this.cipherMode) + ")");
//		}
//
//		DERSequence seq = new DERSequence(vector);
//		return seq.getDEREncoded();
//	}
//
  Sm2EncryptedData encryptInner(Int8List pubKeyBytes, Int8List data) {
    if (pubKeyBytes == null || pubKeyBytes.length == 0) {
//			throw new InvalidCryptoParamsException("[SM2:Encrypt]key is null");
    }
    if (data == null || data.length == 0) {
      return null;
    }

    // C2位数据域
    Int8List c2 = new Int8List(data.length);
    _arraycopy(data, 0, c2, 0, data.length);

//    print(pubKeyBytes);
    ECPoint keyPoint;

//		try {
    //todo Java BigInteger Dart BigInt 计算结果不一样 暂时无法解决
    keyPoint = curve.decodePoint(pubKeyBytes);
//		} catch (Exception e) {
//			throw new InvalidKeyException("[SM2:Encrypt]invalid key data(format)", e);
//		}
//		AsymmetricCipherKeyPair generatedKey = (this.randomKeyHex == null ?  keyPairGenerator.generateKeyPair() : this.generateKeyPair(this.randomKeyHex));
    AsymmetricKeyPair generatedKey = keyPairGenerator.generateKeyPair();
    ECPrivateKey privateKeyParams = generatedKey.privateKey;
    ECPublicKey keyParams = generatedKey.publicKey;
    BigInt privateKey = privateKeyParams.d;
    ECPoint c1 = keyParams.Q;
    this.alternateKeyPoint = keyPoint * privateKey;
    resetKey();

    this.c3Digest.updateFromByteList(c2);
    for (int i = 0; i < c2.length; i++) {
      if (alternateKeyOff >= alternateKey.length) {
        nextKey();
      }
      c2[i] ^= alternateKey[alternateKeyOff++];
    }
    Int8List p =
        SmCommonUtils.byteConvert32Bytes(alternateKeyPoint.y.toBigInteger());
    this.c3Digest.updateFromByteList(p);
    Int8List c3 = this.c3Digest.doFinalWithReturn();
    resetKey();

    return new Sm2EncryptedData(c1, c2, c3);
  }

//
//	@Deprecated
//	protected AsymmetricCipherKeyPair generateKeyPair(String randomKeyHex) {
//		ECDomainParameters domainParams = new ECDomainParameters(curve, pointG, SM2_ECC_N);
//		BigInt n = domainParams.getN();
//		BigInt d = new BigInt(randomKeyHex, 16);
//		if(d.equals(BigInt.valueOf(0)) || (d.compareTo(n) >= 0)) {
//			throw new InvalidCryptoParamsException("[SM2:generateKeyPair]invalid randomKeyData, random D mast be greater than Param N");
//		}
//		ECPoint Q = domainParams.getG().multiply(d);
//		return new AsymmetricCipherKeyPair(new ECKeyParameters(Q, domainParams), new ECPrivateKeyParameters(d, domainParams));
//	}
//
//	/**
//	 * SM2解密
//	 * @param prvKeyBytes	私钥
//	 * @param dataBytes		数据
//	 * @throws InvalidCryptoDataException
//	 * @throws InvalidKeyException
//	 * @throws UnsupportedEncodingException
//	 */
//	protected final Int8List decrypt(Int8List prvKeyBytes, Int8List dataBytes) throws InvalidKeyException, InvalidCryptoDataException {
//		if (prvKeyBytes == null || prvKeyBytes.length == 0) {
//			return null;
//		}
//
//		if (dataBytes == null || dataBytes.length == 0) {
//			return null;
//		}
//		// 加密字节数组转换为十六进制的字符串 长度变为encryptedData.length * 2
//		String data = ByteUtils.bytesToHex(dataBytes);
//		int datLength = data.length();
//		Int8List c1Bytes = ByteUtils.hexToBytes(data.substring(0, 130));
//		int c2Len = 0;
//		Int8List c2 = null;
//		Int8List c3 = null;
//		switch (this.cipherMode) {
//		case C1C2C3:
//			/**
//			 * 分解加密字串 （C1 = C1标志位2位 + C1实体部分128位 = 130） （C2 = encryptedData.length * 2 - C1长度 - C2长度） （C3 = C3实体部分64位 = 64）
//			 */
//			c2Len = dataBytes.length - 97;
//			c2 = ByteUtils.hexToBytes(data.substring(130, 130 + 2 * c2Len));
//			c3 = ByteUtils.hexToBytes(data.substring(130 + 2 * c2Len, 194 + 2 * c2Len));
//
//			return decryptInner(prvKeyBytes, c1Bytes, c2, c3);
//		case C1C3C2:
//			/**
//			 * 分解加密字串 （C1 = C1标志位2位 + C1实体部分128位 = 130） （C3 = C3实体部分64位 = 64） （C2 = encryptedData.length * 2 - C1长度 - C2长度）
//			 */
//			c3 = ByteUtils.hexToBytes(data.substring(130, 130 + 64));
//			c2 = ByteUtils.hexToBytes(data.substring(130 + 64, datLength));
//
//			return decryptInner(prvKeyBytes, c1Bytes, c2, c3);
//		default:
//			throw new InvalidCryptoParamsException("[SM2:Encrypt]invalid type(" + String.valueOf(this.cipherMode) + ")");
//		}
//
//	}
//
//	/**
//	 * SM2解密, ASN.1编码
//	 * @param prvKeyBytes	私钥
//	 * @param data			数据
//	 */
//	protected final Int8List decryptFromASN1(Int8List prvKeyBytes, Int8List data) throws InvalidKeyException, InvalidCryptoDataException {
//		if (data == null || data.length == 0) {
//			return null;
//		}
//
//		ByteArrayInputStream byteArrayInputStream = new ByteArrayInputStream(data);
//		ASN1InputStream asn1InputStream = new ASN1InputStream(byteArrayInputStream);
//		DERObject derObj;
//		DERObject endObj;
//		try {
//			derObj = asn1InputStream.readObject();
//			endObj = asn1InputStream.readObject();
//			if(endObj != null) {
//				throw new InvalidCryptoDataException("[SM2:decrypt:ASN1]invalid encrypted data");
//			}
//		} catch (IOException e) {
//			throw new InvalidCryptoDataException("[SM2:decrypt:ASN1]invalid encrypted data", e);
//		} finally {
//			IOUtils.closeQuietly(byteArrayInputStream);
//			IOUtils.closeQuietly(asn1InputStream);
//		}
//		ASN1Sequence asn1 = (ASN1Sequence) derObj;
//		DERInteger x = (DERInteger) asn1.getObjectAt(0);
//		DERInteger y = (DERInteger) asn1.getObjectAt(1);
//		ECPoint c1;
//		try {
//			c1 = curve.createPoint(x.getValue(), y.getValue(), true);
//		} catch (Exception e) {
//			throw new InvalidCryptoDataException("[SM2:decrypt:ASN1]invalid encrypted data, c1", e);
//		}
//		Int8List c2;
//		Int8List c3;
//		switch (this.cipherMode) {
//		case C1C2C3:
//			c2 = ((DEROctetString) asn1.getObjectAt(2)).getOctets();
//			c3 = ((DEROctetString) asn1.getObjectAt(3)).getOctets();
//			break;
//		case C1C3C2:
//			c3 = ((DEROctetString) asn1.getObjectAt(2)).getOctets();
//			c2 = ((DEROctetString) asn1.getObjectAt(3)).getOctets();
//			break;
//		default:
//			throw new InvalidCryptoParamsException("[SM2:Decrypt:ASN1]invalid type(" + String.valueOf(this.cipherMode) + ")");
//		}
//
//		return decryptInner(prvKeyBytes, c1.getEncoded(), c2, c3);
//	}
//
//	private final Int8List decryptInner(Int8List prvKeyBytes, Int8List c1, Int8List c2, Int8List c3) throws InvalidKeyException, InvalidCryptoDataException {
//		if (prvKeyBytes == null || prvKeyBytes.length == 0) {
//			throw new InvalidCryptoParamsException("[SM2:Decrypt]key is null");
//		}
//		if (c1 == null || c1.length <= 0 || c2 == null || c2.length <= 0 || c3 == null || c3.length <= 0) {
//			throw new InvalidCryptoDataException("[SM2:Decrypt]invalid encrypt data, c1 / c2 / c3 is null or empty");
//		}
//
//		BigInt decryptKey = new BigInt(1, prvKeyBytes);
//		ECPoint c1Point;
//		try {
//			c1Point = curve.decodePoint(c1);
//		} catch (Exception e) {
//			throw new InvalidCryptoDataException("[SM2:Decrypt]invalid encrypt data, c1 invalid", e);
//		}
//
//		this.alternateKeyPoint = c1Point.multiply(decryptKey);
//		resetKey();
//
//		for (int i = 0; i < c2.length; i++) {
//			if (alternateKeyOff >= alternateKey.length) {
//				nextKey();
//			}
//			c2[i] ^= alternateKey[alternateKeyOff++];
//		}
//		this.c3Digest.update(c2, 0, c2.length);
//		byte p[] = CommonUtils.byteConvert32Bytes(alternateKeyPoint.getY().toBigInt());
//		this.c3Digest.update(p, 0, p.length);
//		Int8List verifyC3 = this.c3Digest.doFinal();
//		if (!Arrays.equals(verifyC3, c3)) {
//			throw new InvalidKeyException("[SM2:Decrypt]invalid key, c3 is not match");
//		}
//		resetKey();
//		// 返回解密结果
//		return c2;
//	}
//
//	/**
//	 * 签名
//	 *
//	 * @param userId		用户ID
//	 * @param prvKeyBytes	私钥
//	 * @param sourceData	数据
//	 * @return 签名数据{r, s}
//	 */
//	private final BigInt[] sign(Int8List userId, Int8List prvKeyBytes, Int8List sourceData) {
//		if (prvKeyBytes == null || prvKeyBytes.length == 0) {
//			throw new InvalidCryptoParamsException("[SM2:sign]prvKeyBytes is null");
//		}
//		if (sourceData == null || sourceData.length == 0) {
//			throw new InvalidCryptoParamsException("[SM2:sign]sourceData is null");
//		}
//		// 私钥, 私钥和基点生成秘钥点
//		BigInt key = new BigInt(prvKeyBytes);
//		ECPoint keyPoint = pointG.multiply(key);
//		// Z
//		Sm3Digest digest = new Sm3Digest();
//		Int8List z = getZ(userId, keyPoint);
//		// 对数据做摘要
//		digest.update(z, 0, z.length);
//		digest.update(sourceData);
//		Int8List digestData = digest.doFinal();
//		// 签名数据{r, s}
//		return signInner(digestData, key, keyPoint);
//	}
//
//	/**
//	 * 签名(ASN.1编码)
//	 *
//	 * @param userId		用户ID
//	 * @param prvKeyBytes	私钥
//	 * @param sourceData	数据
//	 * @return 签名数据 Int8List ASN.1编码
//	 */
//	protected final Int8List signToASN1(Int8List userId, Int8List prvKeyBytes, Int8List sourceData) {
//		if (prvKeyBytes == null || prvKeyBytes.length == 0) {
//			throw new InvalidCryptoParamsException("[SM2:signToASN1]prvKeyBytes is null");
//		}
//		if (sourceData == null || sourceData.length == 0) {
//			throw new InvalidCryptoParamsException("[SM2:signToASN1]sourceData is null");
//		}
//		BigInt[] signData = sign(userId, prvKeyBytes, sourceData);
//		// 签名数据序列化
//		DERInteger derR = new DERInteger(signData[0]);// r
//		DERInteger derS = new DERInteger(signData[1]);// s
//		ASN1EncodableVector vector = new ASN1EncodableVector();
//		vector.add(derR);
//		vector.add(derS);
//		DERObject sign = new DERSequence(vector);
//		return sign.getDEREncoded();
//	}
//
//	/**
//	 * 签名(ASN.1编码)
//	 *
//	 * @param prvKeyBytes	私钥
//	 * @param sourceData	数据
//	 * @return 签名数据 Int8List ASN.1编码
//	 */
//	protected final Int8List signToASN1(Int8List prvKeyBytes, Int8List sourceData) {
//		return signToASN1(DEFAULT_USER_ID, prvKeyBytes, sourceData);
//	}
//
//	private final BigInt[] signInner(Int8List digestData, BigInt key, ECPoint keyPoint) {
//		BigInt e = new BigInt(1, digestData);
//		BigInt k;
//		ECPoint kp;
//		BigInt r;
//		BigInt s;
//		do {
//			do {
//				// 正式环境
//				AsymmetricCipherKeyPair keypair = keyPairGenerator.generateKeyPair();
//				ECPrivateKeyParameters privateKey = (ECPrivateKeyParameters) keypair.getPrivate();
//				ECKeyParameters Key = (ECKeyParameters) keypair.get();
//				k = privateKey.getD();
//				kp = Key.getQ();
//
//				// r
//				r = e.add(kp.getX().toBigInt());
//				r = r.mod(SM2_ECC_N);
//			} while (r.equals(BigInt.ZERO) || r.add(k).equals(SM2_ECC_N));
//			// (1 + dA)~-1
//			BigInt da_1 = key.add(BigInt.ONE);
//			da_1 = da_1.modInverse(SM2_ECC_N);
//			// s
//			s = r.multiply(key);
//			s = k.subtract(s).mod(SM2_ECC_N);
//			s = da_1.multiply(s).mod(SM2_ECC_N);
//		} while (s.equals(BigInt.ZERO));
//
//		return new BigInt[] { r, s };
//	}
//
//	/**
//	 * 验签
//	 *
//	 * @param userId		用户ID
//	 * @param pubKeyBytes		公钥
//	 * @param sourceData	数据
//	 * @param signR			签名数据r
//	 * @param signS			签名数据s
//	 * @return true:签名有效,false:签名无效
//	 */
//	private final boolean verifySign(Int8List userId, Int8List pubKeyBytes, Int8List sourceData, BigInt signR, BigInt signS) throws InvalidKeyException {
//		if (pubKeyBytes == null || pubKeyBytes.length == 0) {
//			throw new InvalidCryptoParamsException("[SM2:verifySign]key is null");
//		}
//		if (sourceData == null || sourceData.length == 0 || signR == null || signS == null) {
//			return false;
//		}
//
//		// 公钥
//		ECPoint key;
//		try {
//			key = curve.decodePoint(pubKeyBytes);
//		} catch (Exception e) {
//			throw new InvalidKeyException("[SM2:verifySign]invalid  key (format)", e);
//		}
//		// Z
//		Sm3Digest digest = new Sm3Digest();
//		Int8List z = getZ(userId, key);
//		// 对数据摘要
//		digest.update(z, 0, z.length);
//		digest.update(sourceData, 0, sourceData.length);
//		Int8List digestData = digest.doFinal();
//		// 验签
//		return signR.equals(verifyInner(digestData, key, signR, signS));
//	}
//
//	/**
//	 * 验签(ASN.1编码签名)
//	 *
//	 * @param userId		用户ID
//	 * @param pubKeyBytes	公钥
//	 * @param sourceData	数据
//	 * @param signData		签名数据(ASN.1编码)
//	 * @return true:签名有效,false:签名无效
//	 * @throws InvalidSignDataException	ASN.1编码无效
//	 * @throws InvalidCryptoDataException
//	 * @throws InvalidKeyException
//	 */
//	@SuppressWarnings("unchecked")
//	protected final boolean verifySignByASN1(Int8List userId, Int8List pubKeyBytes, Int8List sourceData, Int8List signData) throws InvalidSignDataException, InvalidKeyException {
//		Int8List _signData = signData;
//
//		// 过滤头部的0x00
//		int startIndex = 0;
//		for (int i = 0; i < signData.length; i++) {
//			if (signData[i] != 0x00) {
//				break;
//			}
//			startIndex++;
//		}
//		if (startIndex > 0) {
//			_signData = new byte[signData.length - startIndex];
//			_arraycopy(signData, startIndex, _signData, 0, _signData.length);
//		}
//
//		ByteArrayInputStream byteArrayInputStream = new ByteArrayInputStream(_signData);
//		ASN1InputStream asn1InputStream = new ASN1InputStream(byteArrayInputStream);
//
//		Enumeration<DERInteger> signObj;
//		DERObject derObj;
//		DERObject endObj;
//		try {
//			derObj = asn1InputStream.readObject();
//			endObj = asn1InputStream.readObject();
//			if(endObj != null) {
//				throw new InvalidSignDataException("[SM2:decrypt:ASN1]invalid sign data (ASN.1)");
//			}
//			signObj = ((ASN1Sequence) derObj).getObjects();
//		} catch (IOException e) {
//			throw new InvalidSignDataException("[SM2:verifySign]invalid sign data (ASN.1)", e);
//		} finally {
//			IOUtils.closeQuietly(byteArrayInputStream);
//			IOUtils.closeQuietly(asn1InputStream);
//		}
//
//
//		BigInt r = signObj.nextElement().getValue();
//		BigInt s = signObj.nextElement().getValue();
//
//		// 验签
//		return verifySign(userId, pubKeyBytes, sourceData, r, s);
//	}
//
//	/**
//	 * 验签(ASN.1编码签名)
//	 *
//	 * @param userId		 用户ID
//	 * @param pubKeyBytes	公钥
//	 * @param sourceData	数据
//	 * @param signData		签名数据(ASN.1编码)
//	 * @return true:签名有效,false:签名无效
//	 * @throws InvalidKeyException
//	 * @throws InvalidSignDataException	ASN.1编码无效
//	 * @throws InvalidCryptoDataException
//	 */
//	protected final boolean verifySignByASN1(Int8List pubKeyBytes, Int8List sourceData, Int8List signData) throws InvalidSignDataException, InvalidKeyException {
//		return verifySignByASN1(DEFAULT_USER_ID, pubKeyBytes, sourceData, signData);
//	}
//
//	private final BigInt verifyInner(byte digestData[], ECPoint userKey, BigInt r, BigInt s) {
//		BigInt e = new BigInt(1, digestData);
//		BigInt t = r.add(s).mod(SM2_ECC_N);
//		if (t.equals(BigInt.ZERO)) {
//			return null;
//		} else {
//			ECPoint x1y1 = pointG.multiply(s);
//			x1y1 = x1y1.add(userKey.multiply(t));
//			return e.add(x1y1.getX().toBigInt()).mod(SM2_ECC_N);
//		}
//	}

  static Int8List _arraycopy(
      Int8List src, int srcPos, Int8List dest, int destPos, int length) {
    dest.setRange(
        destPos, destPos + length, src.sublist(srcPos, srcPos + length));
    return dest;
  }
}
