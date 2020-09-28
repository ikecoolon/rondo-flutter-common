import 'dart:typed_data';

import 'package:pointycastle/ecc/ecc_fp.dart';

class Sm2EncryptedData {
  ECPoint c1;

  Int8List c2;

  Int8List c3;

  Sm2EncryptedData(ECPoint c1, Int8List c2, Int8List c3) {
    this.c1 = c1;
    this.c2 = c2;
    this.c3 = c3;
  }

  ECPoint getC1() {
    return c1;
  }

  void setC1(ECPoint c1) {
    this.c1 = c1;
  }

  Int8List getC2() {
    return c2;
  }

  void setC2(Int8List c2) {
    this.c2 = c2;
  }

  Int8List getC3() {
    return c3;
  }

  void setC3(Int8List c3) {
    this.c3 = c3;
  }
}
