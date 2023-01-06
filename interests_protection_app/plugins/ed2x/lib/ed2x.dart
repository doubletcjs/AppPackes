library ed2x;

import 'package:pinenacl/ed25519.dart';
import 'package:pinenacl/tweetnacl.dart';

typedef Curve25519Key = Uint8List;

typedef Ed25519Key = Uint8List;

class Curve25519KeyPair {
  Curve25519Key publicKey;
  Curve25519Key secretKey;

  Curve25519KeyPair(this.publicKey, this.secretKey);
}

class Ed2CurveUtils {
  static Curve25519KeyPair convertKeyPair(
      Uint8List publicKey, Uint8List secretKey) {
    var newPk = Uint8List(TweetNaCl.publicKeyLength);
    var newSk = Uint8List(TweetNaCl.secretKeyLength);
    newPk = convertPublicKey(publicKey);
    newSk = convertPrivateKey(secretKey);
    return Curve25519KeyPair(newPk, newSk);
  }

  static Curve25519KeyPair? convertKeyPairOpt(
      Uint8List publicKey, Uint8List secretKey) {
    try {
      return convertKeyPair(publicKey, secretKey);
    } catch (e) {
      return null;
    }
  }

  static Curve25519Key convertPrivateKey(Ed25519Key secretKey) {
    var newSk = Uint8List(TweetNaCl.secretKeyLength);
    var oldSk = Uint8List.fromList(secretKey);
    var skResult =
        TweetNaClExt.crypto_sign_ed25519_sk_to_x25519_sk(newSk, oldSk);
    if (skResult == -1) {
      throw Exception('Failed to convert secret key');
    }
    return newSk;
  }

  static Curve25519Key convertPublicKey(Ed25519Key publicKey) {
    var newPk = Uint8List(TweetNaCl.publicKeyLength);
    var oldPk = Uint8List.fromList(publicKey);
    var pkResult =
        TweetNaClExt.crypto_sign_ed25519_pk_to_x25519_pk(newPk, oldPk);
    if (pkResult == -1) {
      throw Exception('Failed to convert public key');
    }
    return newPk;
  }

  static Curve25519Key? convertPublicKeyOpt(Ed25519Key publicKey) {
    try {
      return convertPublicKey(publicKey);
    } catch (e) {
      return null;
    }
  }

  static toHex(Uint8List bArr) {
    int length;
    if ((length = bArr.length) <= 0) {
      return "";
    }
    Uint8List cArr = Uint8List(length << 1);
    int i = 0;
    for (int i2 = 0; i2 < length; i2++) {
      int i3 = i + 1;
      var cArr2 = [
        '0',
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9',
        'A',
        'B',
        'C',
        'D',
        'E',
        'F'
      ];

      var index = (bArr[i2] >> 4) & 15;
      cArr[i] = cArr2[index].codeUnitAt(0);
      i = i3 + 1;
      cArr[i3] = cArr2[bArr[i2] & 15].codeUnitAt(0);
    }
    return String.fromCharCodes(cArr);
  }

  static hex(int c) {
    if (c >= '0'.codeUnitAt(0) && c <= '9'.codeUnitAt(0)) {
      return c - '0'.codeUnitAt(0);
    }
    if (c >= 'A'.codeUnitAt(0) && c <= 'F'.codeUnitAt(0)) {
      return (c - 'A'.codeUnitAt(0)) + 10;
    }
  }

  static toUnitList(String str) {
    int length = str.length;
    if (length % 2 != 0) {
      str = "0$str";
      length++;
    }
    List<int> s = str.toUpperCase().codeUnits;
    Uint8List bArr = Uint8List(length >> 1);
    for (int i = 0; i < length; i += 2) {
      bArr[i >> 1] = ((hex(s[i]) << 4) | hex(s[i + 1]));
    }
    return bArr;
  }
}
