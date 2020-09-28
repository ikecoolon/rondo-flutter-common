//
//import 'dart:typed_data';
//
//
//
import 'dart:typed_data';

import 'SmCommonUtils.dart';


class Sm3Algorithm {
//
//	/**
//	 * 默认初始化向量
//	 */
  static final List<int> DEFAULT_IV = [
    0x73,
    0x80,
    0x16,
    0x6f,
    0x49,
    0x14,
    0xb2,
    0xb9,
    0x17,
    0x24,
    0x42,
    0xd7,
    0xda,
    0x8a,
    0x06,
    0x00,
    0xa9,
    0x6f,
    0x30,
    0xbc,
    0x16,
    0x31,
    0x38,
    0xaa,
    0xe3,
    0x8d,
    0xee,
    0x4d,
    0xb0,
    0xfb,
    0x0e,
    0x4e
  ];

//
  static List Tj = new Int64List(64);

  static void tjInit() {
    for (int i = 0; i < 16; i++) {
      Tj[i] = 0x79cc4519;
    }

    for (int i = 16; i < 64; i++) {
      Tj[i] = 0x7a879d8a;
    }
  }

//
  static Int8List digestBlock(Int8List V, Int8List B) {
    Int32List v, b;
    v = convert(V);
    b = convert(B);
    return convert2(digestBlock2(v, b));
  }

//
  static Int32List convert(Int8List arr) {
    Int32List out = new Int32List(arr.length ~/ 4);
    Int8List tmp = new Int8List(4);
    for (int i = 0; i < arr.length; i += 4) {
      _arraycopy(arr, i, tmp, 0, 4);
      out[i ~/ 4] = bigEndianByteToInt(tmp);
    }
    return out;
  }

//
  static Int8List convert2(Int32List arr) {
    Int8List out = new Int8List(arr.length * 4);
    Int8List tmp;
    for (int i = 0; i < arr.length; i++) {
      tmp = bigEndianIntToByte(arr[i]);
      _arraycopy(tmp, 0, out, i * 4, 4);
    }
    return out;
  }

//
  static Int32List digestBlock2(Int32List V, Int32List B) {
    int a, b, c, d, e, f, g, h;
    int ss1, ss2, tt1, tt2;
    a = V[0];
    b = V[1];
    c = V[2];
    d = V[3];
    e = V[4];
    f = V[5];
    g = V[6];
    h = V[7];

    List<Int32List> arr = expand(B);
    Int32List w = arr[0];
    Int32List w1 = arr[1];

    //初始化Tj
    tjInit();

    for (int j = 0; j < 64; j++) {
      ss1 = (bitCycleLeft(a, 12) + e + bitCycleLeft(Tj[j], j));

      ss1 = bitCycleLeft(ss1, 7);
      ss2 = ss1 ^ bitCycleLeft(a, 12);
      tt1 = FFj(a, b, c, j) + d + ss2 + w1[j];
      tt2 = GGj(e, f, g, j) + h + ss1 + w[j];
      d = c;
      c = bitCycleLeft(b, 9);
      b = a;
      a = tt1;
      h = g;
      g = bitCycleLeft(f, 19);
      f = e;
      e = P0(tt2);
    }

    Int32List out = new Int32List(8);
    out[0] = a ^ V[0];
    out[1] = b ^ V[1];
    out[2] = c ^ V[2];
    out[3] = d ^ V[3];
    out[4] = e ^ V[4];
    out[5] = f ^ V[5];
    out[6] = g ^ V[6];
    out[7] = h ^ V[7];

    return out;
  }

//
  static List<Int32List> expand(Int32List B) {
    Int32List W = new Int32List(68);
    Int32List W1 = new Int32List(64);
    for (int i = 0; i < B.length; i++) {
      W[i] = B[i];
    }

    for (int i = 16; i < 68; i++) {
      W[i] = P1(W[i - 16] ^ W[i - 9] ^ bitCycleLeft(W[i - 3], 15)) ^
          bitCycleLeft(W[i - 13], 7) ^
          W[i - 6];
    }

    for (int i = 0; i < 64; i++) {
      W1[i] = W[i] ^ W[i + 4];
    }

    var arr = [W, W1];
//    Int32List arr= Int32List.fromList(W)
    return arr;
  }

//
  static Int8List bigEndianIntToByte(int num) {
    return back(SmCommonUtils.intToBytes(num));
  }

//
  static int bigEndianByteToInt(Int8List bytes) {
    return SmCommonUtils.byteToInt(back(bytes));
  }

//
  static int FFj(int X, int Y, int Z, int j) {
    if (j >= 0 && j <= 15) {
      return FF1j(X, Y, Z);
    } else {
      return FF2j(X, Y, Z);
    }
  }

//
  static int GGj(int X, int Y, int Z, int j) {
    if (j >= 0 && j <= 15) {
      return GG1j(X, Y, Z);
    } else {
      return GG2j(X, Y, Z);
    }
  }

//
  // 逻辑位运算函数
  static int FF1j(int X, int Y, int Z) {
    int tmp = X ^ Y ^ Z;
    return tmp;
  }

  static int FF2j(int X, int Y, int Z) {
    int tmp = ((X & Y) | (X & Z) | (Y & Z));
    return tmp;
  }

//
  static int GG1j(int X, int Y, int Z) {
    int tmp = X ^ Y ^ Z;
    return tmp;
  }

  static int GG2j(int X, int Y, int Z) {
    int tmp = (X & Y) | (~X & Z);
    return tmp;
  }

//
  static int P0(int X) {
    rotateLeft(X, 9);
    int y = bitCycleLeft(X, 9);
    rotateLeft(X, 17);
    int z = bitCycleLeft(X, 17);
    int t = X ^ y ^ z;
    return t;
  }

  static int P1(int X) {
    int t = X ^ bitCycleLeft(X, 15) ^ bitCycleLeft(X, 23);
    return t;
  }

//
  /**
   * 对最后一个分组字节数据padding
   *
   * @param in
   * @param bLen	分组个数
   * @return
   */
  static Int8List paddingBlock(Int8List ins, int bLen) {
    int k = 448 - (8 * ins.length + 1) % 512;
    if (k < 0) {
      k = 960 - (8 * ins.length + 1) % 512;
    }
    k += 1;
    Int8List padd = new Int8List(k ~/ 8);
    padd[0] = 0x80;
    var n = ins.length * 8 + bLen * 512;
    Int8List out = new Int8List((ins.length + k / 8 + 64 / 8).toInt());
    int pos = 0;
    _arraycopy(ins, 0, out, 0, ins.length);
    pos += ins.length;
    _arraycopy(padd, 0, out, pos, padd.length);
    pos += padd.length;
    Int8List tmp = back(SmCommonUtils.longToBytes(n));
    _arraycopy(tmp, 0, out, pos, tmp.length);
    return out;
  }

//
  /**
   * 字节数组逆序
   *
   * @param in
   * @return
   */
  static Int8List back(Int8List ins) {
    Int8List out = new Int8List(ins.length);
    for (int i = 0; i < out.length; i++) {
      out[i] = ins[out.length - i - 1];
    }

    return out;
  }

//
  static int rotateLeft(int x, int n) {
    return (x << n) | (x >> (32 - n));
  }

//
  static int bitCycleLeft(int n, int bitLen) {
    bitLen %= 32;
    Int8List tmp = bigEndianIntToByte(n);
    int byteLen = bitLen ~/ 8;
    int len = bitLen % 8;
    if (byteLen > 0) {
      tmp = byteCycleLeft(tmp, byteLen);
    }

    if (len > 0) {
      tmp = bitSmall8CycleLeft(tmp, len);
    }

    return bigEndianByteToInt(tmp);
  }

//
  static Int8List bitSmall8CycleLeft(Int8List ins, int len) {
    Int8List tmp = new Int8List(ins.length);
    int t1, t2, t3;
    for (int i = 0; i < tmp.length; i++) {
      t1 = ((ins[i] & 0x000000ff) << len);
      t2 = ((ins[(i + 1) % tmp.length] & 0x000000ff) >> (8 - len));
      t3 = (t1 | t2);
      tmp[i] = t3;
    }

    return tmp;
  }

//
  static Int8List byteCycleLeft(Int8List ins, int byteLen) {
    Int8List tmp = new Int8List(ins.length);
    _arraycopy(ins, byteLen, tmp, 0, ins.length - byteLen);
    _arraycopy(ins, 0, tmp, ins.length - byteLen, byteLen);
    return tmp;
  }

  static Int8List _arraycopy(
      Int8List src, int srcPos, Int8List dest, int destPos, int length) {
    dest.setRange(
        destPos, destPos + length, src.sublist(srcPos, srcPos + length));
    return dest;
  }
}
