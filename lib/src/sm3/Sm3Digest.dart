import 'dart:typed_data';

import 'Sm3Algorithm.dart';


/**
 * SM3摘要器
 * 注意:由于对象内存在buffer, 请勿多线程同时操作一个实例, 每次new一个Cipher使用, 或使用ThreadLocal保持每个线程一个Cipher实例.
 *
 * @author S.Violet
 */
class Sm3Digest {
  // SM3值的长度
  static final int BYTE_LENGTH = 32;

  // SM3分组长度
  static final int BLOCK_LENGTH = 64;

  // 缓冲区长度
  static final int BUFFER_LENGTH = BLOCK_LENGTH;

  // 缓冲区
  Int8List buff = new Int8List(BUFFER_LENGTH);

  // 缓冲区偏移量
  int buffOffset = 0;

  // 块计数
  int blockCounter = 0;

  // 摘要值(暂存)
  Int8List digestValue = Int8List.fromList(Sm3Algorithm.DEFAULT_IV);

  Sm3Digest();

  Sm3Digest.oneParam(Sm3Digest digest) {
    _arraycopy(digest.buff, 0, this.buff, 0, digest.buff.length);
    this.buffOffset = digest.buffOffset;
    this.blockCounter = digest.blockCounter;
    _arraycopy(
        digest.digestValue, 0, this.digestValue, 0, digest.digestValue.length);
  }

  /**
   * 重置
   */
  void reset() {
    buff = new Int8List(BUFFER_LENGTH);
    buffOffset = 0;
    blockCounter = 0;
    digestValue = Int8List.fromList(Sm3Algorithm.DEFAULT_IV);
  }

  void updateSimple(int input) {
    update(Int8List.fromList([input]), 0, 1);
  }

  /**
   * 输入
   *
   * @param input	输入数据
   */
  void updateFromByteList(Int8List input) {
    update(input, 0, input.length);
  }

  /**
   * 输入
   *
   * @param input	输入数据
   * @param inputOffset	输入偏移量
   * @param len	输入长度
   */
  void update(Int8List input, int inputOffset, int len) {
    if (input == null) {
      return;
    }
    int partLen = BUFFER_LENGTH - buffOffset; // buff剩余长度
    int inputLen = len; // 输入长度
    int dPos = inputOffset; // 运算偏移量

    // 输入数据大于缓冲时, 进行摘要运算
    if (partLen < inputLen) {
      // 填满缓冲
      _arraycopy(input, dPos, buff, buffOffset, partLen);
      inputLen -= partLen;
      dPos += partLen;
      // 将缓冲的数据进行摘要计算
      doUpdate();
      // 继续, 直到缓冲能存下剩余数据
      while (inputLen > BUFFER_LENGTH) {
        _arraycopy(input, dPos, buff, 0, BUFFER_LENGTH);
        inputLen -= BUFFER_LENGTH;
        dPos += BUFFER_LENGTH;
        doUpdate();
      }
    }

    // 将剩余数据存入缓冲
    _arraycopy(input, dPos, buff, buffOffset, inputLen);
    buffOffset += inputLen;
  }

  void doUpdate() {
    // 将缓冲区数据按块为单位划分, 进行摘要计算
    Int8List bytes = new Int8List(BLOCK_LENGTH);
    for (int i = 0; i < BUFFER_LENGTH; i += BLOCK_LENGTH) {
      _arraycopy(buff, i, bytes, 0, bytes.length);
      doHash(bytes);
    }
    buffOffset = 0;
  }

  void doHash(Int8List bytes) {
    // 将暂存的摘要值与新数据送入, 进行摘要计算
    Int8List tmp = Sm3Algorithm.digestBlock(digestValue, bytes);
    // 记录摘要值
    _arraycopy(tmp, 0, digestValue, 0, digestValue.length);
    blockCounter++;
  }

  void doFinal(Int8List output, int offset) {
    try {
      // 获取缓冲的剩余数据
      Int8List bytes = new Int8List(BLOCK_LENGTH);
      Int8List buffer = new Int8List(buffOffset);
      _arraycopy(buff, 0, buffer, 0, buffer.length);
      // 填充
      Int8List tmp = Sm3Algorithm.paddingBlock(buffer, blockCounter);
      // 划分为块做摘要计算
      for (int i = 0; i < tmp.length; i += BLOCK_LENGTH) {
        _arraycopy(tmp, i, bytes, 0, bytes.length);
        doHash(bytes);
      }
      _arraycopy(digestValue, 0, output, offset, BYTE_LENGTH);
    } finally {
      reset();
    }
  }

  /**
   * SM3结果输出
   */
  Int8List doFinalWithReturn() {
    Int8List result = new Int8List(BYTE_LENGTH);
    doFinal(result, 0);
    return result;
  }

  Int8List getEncrypted(Int8List password) {
    Int8List md = new Int8List(32);
    Sm3Digest sm3 = new Sm3Digest();
    sm3.update(password, 0, password.length);
    sm3.doFinal(md, 0);
    return md;
  }

  Int8List _arraycopy(
      Int8List src, int srcPos, Int8List dest, int destPos, int length) {
    dest.setRange(
        destPos, destPos + length, src.sublist(srcPos, srcPos + length));
    return dest;
  }
}
