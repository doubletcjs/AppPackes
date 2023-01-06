import 'dart:convert';
import 'dart:typed_data';

import 'package:ed2x/ed2x.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Curve key', () {
    Uint8List priBytes = Uint8List.fromList(Ed2CurveUtils.toUnitList(
        "78caa5063b50968f520dc2e96864eb83fe49a82fc72ee29f44c49f0ccae09de7"));
    Uint8List pubBytes = Uint8List.fromList(Ed2CurveUtils.toUnitList(
        "32afba12bc53c16359a0f688a6ca64f00d34c45e8ffaab7de8c3803a538162d2"));

    var keyPair = Ed2CurveUtils.convertKeyPairOpt(pubBytes, priBytes);

    expect(Ed2CurveUtils.toHex(keyPair!.publicKey).toLowerCase(),
        "906d1d8fd91bcc1bb3afb5083cb525e24245c21e70f78bc1f111e7ec6c7fc92d");
    expect(Ed2CurveUtils.toHex(keyPair.secretKey).toLowerCase(),
        "6875391bd5f78cf96125af885df7e56ca6d425cc2cf230a85328aa8f69e04153");
  });

  test('Public key', () {
    String salt = "xat64z";
    int index = 6;
    String key =
        "f5040f3d27d24a398974e2f94022f3dc005eeeee612120c22dcaa9f6bfd33f63";

    List<int> keyBytes = Ed2CurveUtils.toUnitList(key);
    Uint8List bytes = Uint8List.fromList(keyBytes);
    final bytesBuilder = BytesBuilder();

    for (var i = 0; i < bytes.length; i++) {
      if (i >= (32 - index)) {
        break;
      }
      bytesBuilder.addByte(bytes[i]);
    }

    List<int> saltBytes = utf8.encode(salt);

    bytesBuilder.add(saltBytes);

    String endKey = Ed2CurveUtils.toHex(bytesBuilder.toBytes());

    expect(endKey.toLowerCase(),
        "f5040f3d27d24a398974e2f94022f3dc005eeeee612120c22dca78617436347a");
  });
}
