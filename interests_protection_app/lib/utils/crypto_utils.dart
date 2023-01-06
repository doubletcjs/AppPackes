import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:aes_crypt_null_safe/aes_crypt_null_safe.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:ed2x/ed2x.dart';
import 'package:encrypt/encrypt.dart'; // MD5
import 'package:flutter/material.dart' hide Key;
import 'package:flutter/services.dart';
import 'package:interests_protection_app/config/environment_config.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:password_dart/password_dart.dart';
import 'package:pointycastle/asymmetric/api.dart';

EnvironmentConfig kCryptoKeyConfig = kAppConfig;

class CryptoUtils {
  // 本地存储：自己的 curve25519 私钥、服务器的 curve25519 公钥*、服务器 RSA 公钥*、好友的 curve25519 公钥
  /// 生成密钥
  static Future<Map<String, String>> cryptotion() async {
    Completer<Map<String, String>> completer = Completer();

    debugPrint("生成密钥开始:${DateTime.now()}");
    // 生成 私钥
    final edKeyPair = await Ed25519().newKeyPair();
    final edPrivateKeyBytes = await edKeyPair.extractPrivateKeyBytes(); // 私钥
    final edPublicKey = await edKeyPair.extractPublicKey();
    final edPublicKeyBytes = edPublicKey.bytes; // 公钥

    final edPublicHex = bytesToHex(edPublicKeyBytes);
    final edPrivateHex = bytesToHex(edPrivateKeyBytes); // 返回用于登录

    // 私钥 HEX 字符串
    debugPrint(
        "ed25519私钥 HEX 字符串:$edPrivateHex$edPublicHex -- 长度:${edPrivateKeyBytes.length + edPublicKeyBytes.length}");

    var xPrivateHex = "";
    Future.wait([
      Future(() async {
        // X25519密钥转换
        var xKeyPair = Ed2CurveUtils.convertKeyPairOpt(
          Ed2CurveUtils.toUnitList(edPublicHex),
          Ed2CurveUtils.toUnitList(edPrivateHex),
        );

        var xPrivateKeyBytes = xKeyPair!.secretKey;
        xPrivateHex = bytesToHex(xPrivateKeyBytes); // 返回用于登录
        debugPrint(
            "X25519私钥HEX:$xPrivateHex  -- 长度:${xPrivateKeyBytes.length}");

        // X25519公钥
        // {
        //   final xPublicKey = await xKeyPair.extractPublicKey();
        //   final xPublicKeyBytes = xPublicKey.bytes;

        //   debugPrint(
        //       "X25519公钥HEX:${bytesToHex(xPublicKeyBytes)}  -- 长度:${xPublicKeyBytes.length}");
        // }
      })
    ]).then((value) {
      kCryptoKeyConfig.curvePrivateKey = xPrivateHex;
      completer.complete({
        "ed": edPrivateHex + edPublicHex,
        "edPri": edPrivateHex,
        "edPub": edPublicHex,
        "x": xPrivateHex
      });
      debugPrint("生成密钥结束:${DateTime.now()}");
    });

    return completer.future;
  }

  /// 解密服务器salt
  static Future<String> serverDecryptSalt({required String base64Salt}) async {
    Completer<String> completer = Completer();

    try {
      var xPrivateHex = kCryptoKeyConfig.curvePrivateKey;
      // 使用 AesGCM 加密算法，key 为登录时候接口返回的“salt字段（需要 curve25519 私钥 作为 KEY AesGCM 解密）”，按上面的加密密钥生成方式生成。
      var cipherText = base64Decode(base64Salt);
      // Choose the cipher
      final algorithm = AesGcm.with256bits();

      final secretBox = SecretBox.fromConcatenation(
        cipherText,
        nonceLength: algorithm.nonceLength,
        macLength: algorithm.macAlgorithm.macLength,
      );

      // Generate a random secret key.
      final secretKey = await algorithm.newSecretKeyFromBytes(
        hexToBytes(xPrivateHex),
      );

      // Decrypt
      final clearText = await algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );

      final salt = utf8.decode(clearText);
      completer.complete(salt);
    } catch (e) {
      completer.complete("");
    }

    return completer.future;
  }

  /// 服务器公共密钥
  static Future<String> serverEncryptionKey() async {
    Completer<String> completer = Completer();
    final salt =
        await serverDecryptSalt(base64Salt: kCryptoKeyConfig.serverSalt);

    if (salt.length == 0) {
      completer.complete("");
    } else {
      final publicKey = await encryptionKey(
        kCryptoKeyConfig.serverCurvePublicKey,
        salt: salt,
      );

      completer.complete(publicKey);
    }
    return completer.future;
  }

  /// 解密salt
  static Future<String> decryptSalt({required String base64Salt}) async {
    Completer<String> completer = Completer();
    if (base64Salt.length > 0) {
      try {
        String encryptionKey = await CryptoUtils.serverEncryptionKey();
        var cipherText = base64Decode(base64Salt);
        // Choose the cipher
        final algorithm = AesGcm.with256bits();

        // Generate a random secret key.
        final secretKey = await algorithm.newSecretKeyFromBytes(
          hexToBytes(encryptionKey),
        );

        final secretBox = SecretBox.fromConcatenation(
          cipherText,
          nonceLength: algorithm.nonceLength,
          macLength: algorithm.macAlgorithm.macLength,
        );

        // Decrypt
        final clearText = await algorithm.decrypt(
          secretBox,
          secretKey: secretKey,
        );

        final salt = utf8.decode(clearText);
        completer.complete(salt);
      } catch (e) {
        completer.complete("");
      }
    } else {
      completer.complete("");
    }

    return completer.future;
  }

  static Future<String> decrypFilename({
    required String base64Text,
    required String salt, // 解密后
  }) async {
    Completer<String> completer = Completer();
    try {
      String _salt = salt;
      for (var i = 0; i < 16 - salt.length; i++) {
        _salt += " ";
      }

      final key = Key.fromUtf8(_salt);
      final iv = IV.fromUtf8(_salt);

      final crypt = Encrypter(AES(key, mode: AESMode.cbc));
      String text = crypt.decrypt(Encrypted.from64(base64Text), iv: iv);

      completer.complete(text);
    } catch (e) {
      completer.complete("");
    }

    return completer.future;
  }

  /// 解密消息文本(base64) publicKey(好友curve25519 公钥)
  static Future<String> decryptText({
    required String publicKey,
    required String base64Text,
    required String salt, // 解密后
    String? encryptionKey, // 计算后共享密钥
  }) async {
    Completer<String> completer = Completer();
    if (base64Text.length > 0) {
      // 共享密钥
      String hexEncryptionKey = "";
      if ((encryptionKey ?? "").length > 0) {
        hexEncryptionKey = encryptionKey ?? "";
      } else {
        hexEncryptionKey = await CryptoUtils.encryptionKey(
          publicKey,
          salt: salt,
        );
      }

      if (hexEncryptionKey.length == 0) {
        completer.complete("");
      } else {
        try {
          var cipherText = base64Decode(base64Text);
          // Choose the cipher
          final algorithm = AesGcm.with256bits();

          // Generate a random secret key.
          final secretKey = await algorithm
              .newSecretKeyFromBytes(hexToBytes(hexEncryptionKey));

          final secretBox = SecretBox.fromConcatenation(
            cipherText,
            nonceLength: algorithm.nonceLength,
            macLength: algorithm.macAlgorithm.macLength,
          );

          // Decrypt
          final clearText = await algorithm.decrypt(
            secretBox,
            secretKey: secretKey,
          );

          final text = utf8.decode(clearText);
          completer.complete(text);
        } catch (e) {
          completer.complete("");
        }
      }
    } else {
      completer.complete("");
    }

    return completer.future;
  }

  /// 加密消息文本(base64) publicKey(好友curve25519 公钥)
  static Future<String> encryptText({
    required String publicKey,
    required String text,
    String? encryptionKey, // 计算后共享密钥
    String? salt,
  }) async {
    Completer<String> completer = Completer();
    if (text.length > 0) {
      // 生成共享密钥
      String hexEncryptionKey = "";
      if ((encryptionKey ?? "").length > 0) {
        hexEncryptionKey = encryptionKey ?? "";
      } else {
        hexEncryptionKey = await CryptoUtils.encryptionKey(
          publicKey,
          salt: salt,
        );
      }

      if (hexEncryptionKey.length == 0) {
        completer.complete("");
      } else {
        try {
          var clearText = utf8.encode(text);
          // Choose the cipher
          final algorithm = AesGcm.with256bits();

          // Generate a random secret key.
          final secretKey = await algorithm
              .newSecretKeyFromBytes(hexToBytes(hexEncryptionKey));

          // Encrypt
          final secretBox = await algorithm.encrypt(
            clearText,
            secretKey: secretKey,
          );

          final cipherText = base64Encode(secretBox.concatenation());
          completer.complete(cipherText);
        } catch (e) {
          completer.completeError(e);
        }
      }
    } else {
      completer.complete("");
    }

    return completer.future;
  }

  /// 解密紧急PIN码
  static Future<String> decryptXPIN(String base64XPIN, String password) async {
    Completer<String> completer = Completer();
    if (password.length == 0 || base64XPIN.length == 0) {
      completer.complete("");
    } else {
      try {
        var cipherText = base64Decode(base64XPIN);
        // Choose the cipher
        final algorithm = AesGcm.with256bits();

        // Generate a random secret key.
        String _password = password;
        for (var i = 0; i < 32 - password.length; i++) {
          _password += "a";
        }

        final secretKey =
            await algorithm.newSecretKeyFromBytes(utf8.encode(_password));

        final secretBox = SecretBox.fromConcatenation(
          cipherText,
          nonceLength: algorithm.nonceLength,
          macLength: algorithm.macAlgorithm.macLength,
        );

        // Decrypt
        final clearText = await algorithm.decrypt(
          secretBox,
          secretKey: secretKey,
        );

        final text = utf8.decode(clearText);
        completer.complete(text);
      } catch (e) {
        completer.completeError(e);
      }
    }

    return completer.future;
  }

  /// 加密紧急PIN码
  static Future<String> encryptXPIN(String xpin, String password) async {
    Completer<String> completer = Completer();

    if (password.length == 0 || xpin.length == 0) {
      completer.complete("");
    } else {
      try {
        var clearText = utf8.encode(xpin);
        // Choose the cipher
        final algorithm = AesGcm.with256bits();

        // Generate a random secret key.
        String _password = password;
        for (var i = 0; i < 32 - password.length; i++) {
          _password += "a";
        }

        final secretKey =
            await algorithm.newSecretKeyFromBytes(utf8.encode(_password));

        // Encrypt
        final secretBox = await algorithm.encrypt(
          clearText,
          secretKey: secretKey,
        );

        final cipherText = base64Encode(secretBox.concatenation());
        completer.complete(cipherText);
      } catch (e) {
        completer.completeError(e);
      }
    }

    return completer.future;
  }

  /// 解密单文件(data) publicKey(好友curve25519 公钥)
  static Future<Uint8List> decryptFile({
    required String filePath,
    required String password, // 计算后共享密钥
  }) async {
    Completer<Uint8List> completer = Completer();
    if (filePath.length > 0) {
      try {
        var crypt = AesCrypt(password);
        AesMode mode = AesMode.cbc;
        crypt.aesSetMode(mode);
        var fileData = await crypt.decryptDataFromFile(filePath);
        completer.complete(fileData);
      } catch (e) {
        completer.complete(Uint8List(0));
      }
    } else {
      completer.complete(Uint8List(0));
    }

    return completer.future;
  }

  /// 加密单文件(data) publicKey(好友curve25519 公钥)
  static Future<Uint8List> encryptFile({
    required Uint8List fileData,
    required String password, // 计算后共享密钥
    required String fileName,
    required String cryptFilePath,
  }) async {
    Completer<Uint8List> completer = Completer();
    if (fileData.length > 0) {
      try {
        debugPrint("文件加密开始:${DateTime.now()}");
        var crypt = AesCrypt(password);
        AesMode mode = AesMode.cbc;
        crypt.aesSetMode(mode);
        crypt.setOverwriteMode(AesCryptOwMode.on);

        String _tempPath = cryptFilePath +
            "/${fileName}_${DateTime.now().millisecondsSinceEpoch}.encrypt.bin";
        await crypt.encryptDataToFile(fileData, _tempPath);
        var encryptData = await File(_tempPath).readAsBytes();

        File(_tempPath).deleteSync();
        debugPrint("文件加密结束:${DateTime.now()}");

        completer.complete(encryptData);
      } catch (e) {
        completer.complete(Uint8List(0));
      }
    } else {
      completer.complete(Uint8List(0));
    }

    return completer.future;
  }

  /// 加密密钥 (公共密钥/共享密钥)
  static Future<String> encryptionKey(
    String? publicKey, {
    String? salt = "",
  }) async {
    Completer<String> completer = Completer();

    String randomChar = "";
    if ((salt ?? "").length > 0) {
      randomChar = salt ?? generateRandomString(10);
    } else {
      randomChar = generateRandomString(10);
    }

    if (publicKey?.length == 0 ||
        kCryptoKeyConfig.curvePrivateKey.length == 0) {
      completer.complete("");
      return completer.future;
    }

    // 生成共享密钥 公钥加用户curve25519私钥
    final algorithm = Cryptography.instance.x25519();
    // Let's generate two keypairs.
    final priKeyPair = await algorithm
        .newKeyPairFromSeed(hexToBytes(kCryptoKeyConfig.curvePrivateKey));
    final remotePublicKey =
        SimplePublicKey(hexToBytes(publicKey), type: KeyPairType.x25519);

    // We can now calculate the shared secret key
    final sharedSecretKey = await algorithm.sharedSecretKey(
      keyPair: priKeyPair,
      remotePublicKey: remotePublicKey,
    );

    final sharedKeyBytes = await sharedSecretKey.extractBytes();
    String sharedKey = bytesToHex(sharedKeyBytes);

    // 关键数
    String keyValue = randomChar.split("").firstWhere((element) {
      return int.tryParse(element) != null;
    }, orElse: () {
      return "";
    });

    String newKey = "";
    if (keyValue.length > 0) {
      int baseKeyLength = int.tryParse(keyValue)!;

      // 基础密钥
      String baseKey = randomChar.substring(0, baseKeyLength);
      String baseKeyHex = bytesToHex(utf8.encode(baseKey));
      if (baseKeyLength % 2 == 0) {
        // 偶数 从头部填充
        newKey = sharedKey.substring(0, sharedKey.length - baseKeyHex.length) +
            baseKeyHex;
      } else {
        // 奇数 从尾部填充
        newKey = baseKeyHex +
            sharedKey.substring(baseKeyHex.length, sharedKey.length);
      }
    } else {
      newKey = sharedKey;
    }

    completer.complete(newKey);

    return completer.future;
  }

  /// pincode加密
  static Future<String> encryptPinCode(String? pincode) async {
    Completer<String> completer = Completer();
    String? encryptPincode = "";

    debugPrint("pincode加密开始:${DateTime.now()}");
    Future.wait([
      Future(() {
        encryptPincode = Password.hash(
          md5(pincode ?? "", lowerCase: false),
          PBKDF2(iterationCount: 1000),
        );
      })
    ]).then((value) {
      completer.complete(encryptPincode ?? "");
      debugPrint("pincode加密结束:${DateTime.now()} -- $encryptPincode");
    });

    return completer.future;
  }

  /// MD5加密
  static String md5(String? text, {bool lowerCase = true}) {
    if (lowerCase == true) {
      return crypto.md5
          .convert(utf8.encode(text ?? ""))
          .toString()
          .toLowerCase();
    }

    return crypto.md5.convert(utf8.encode(text ?? "")).toString();
  }

  /// RSA加密
  static Future<String> rsa(String? text) async {
    Completer<String> completer = Completer();

    final parser = RSAKeyParser();
    // 服务器RSA公钥
    String publicKeyString =
        await rootBundle.loadString("assets/rsa_public.pem");
    RSAPublicKey publicKey = parser.parse(publicKeyString) as RSAPublicKey;
    final encrypter = Encrypter(RSA(publicKey: publicKey));
    var rsaBase64 = base64Encode(encrypter.encrypt(text ?? "").bytes);
    completer.complete(rsaBase64);

    return completer.future;
  }

  /// 请求body加密 base64后，在第三位随机插入["bnm", "cvb"]
  static Future<String> encryptRequest(dynamic params) async {
    Completer<String> completer = Completer();
    List<String> _randkeyList = ["bnm", "cvb"];
    var base64Params = base64Encode(utf8.encode(json.encode(params ?? {})));
    base64Params = base64Params.substring(0, 3) +
        _randkeyList[Random().nextInt(_randkeyList.length)] +
        base64Params.substring(3, base64Params.length);

    completer.complete(base64Params);

    return completer.future;
  }

  static Future<String> publicKeyEncryptRequest(String paramsJson) async {
    var clearText = utf8.encode(paramsJson);
    // Choose the cipher
    final algorithm = AesGcm.with256bits();

    // Generate a random secret key.
    final secretKey = await algorithm.newSecretKeyFromBytes(
        hexToBytes(kCryptoKeyConfig.serverCurvePublicKey));

    // Encrypt
    final secretBox = await algorithm.encrypt(
      clearText,
      secretKey: secretKey,
    );

    final cipherText = base64Encode(secretBox.concatenation());

    Completer<String> completer = Completer();
    List<String> _randkeyList = ["bnm", "cvb"];
    var base64Params = cipherText;
    base64Params = base64Params.substring(0, 3) +
        _randkeyList[Random().nextInt(_randkeyList.length)] +
        base64Params.substring(3, base64Params.length);

    completer.complete(base64Params);

    return completer.future;
  }
}

String generateRandomString(int length) {
  final _random = Random();
  const _availableChars =
      'qwertyuioplkjhgfdsazxcvbnm1234567890'; //QWERTYUIOPLKJHGFDSAZXCVBNM
  final randomString = List.generate(length,
          (index) => _availableChars[_random.nextInt(_availableChars.length)])
      .join();

  return randomString;
}

String bytesToHex(List<int> b) =>
    b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();

Uint8List hexToBytes(String? hex) {
  if (hex == null) throw new ArgumentError("hex is null");

  var result = new Uint8List(hex.length ~/ 2);
  for (var i = 0; i < hex.length; i += 2) {
    var num = hex.substring(i, i + 2);
    var byte = int.parse(num, radix: 16);
    result[i ~/ 2] = byte;
  }

  return result;
}
