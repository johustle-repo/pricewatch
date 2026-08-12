import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class PasswordHasher {
  const PasswordHasher._();

  static const String _pepper = 'pricewatch-local-app';
  static const int _iterations = 20000;

  static String hashPassword(String password, {required String email}) {
    final random = Random.secure();
    final saltBytes = List<int>.generate(24, (_) => random.nextInt(256));
    final salt = base64UrlEncode(saltBytes);
    final digest = _derive(password, email, salt);
    return 'v2\$$salt\$$digest';
  }

  static bool verify({
    required String password,
    required String email,
    required String hash,
  }) {
    if (hash.startsWith('v2\$')) {
      final parts = hash.split('\$');
      if (parts.length != 3) return false;
      return _constantTimeEquals(_derive(password, email, parts[1]), parts[2]);
    }
    final legacy = sha256
        .convert(
          utf8.encode('${email.trim().toLowerCase()}|$password|$_pepper'),
        )
        .toString();
    return _constantTimeEquals(legacy, hash);
  }

  static bool needsUpgrade(String hash) => !hash.startsWith('v2\$');

  static String _derive(String password, String email, String salt) {
    var bytes = utf8.encode(
      '${email.trim().toLowerCase()}|$password|$salt|$_pepper',
    );
    Digest digest = sha256.convert(bytes);
    for (var round = 1; round < _iterations; round++) {
      digest = sha256.convert([...digest.bytes, ...bytes]);
    }
    return base64UrlEncode(digest.bytes);
  }

  static bool _constantTimeEquals(String left, String right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var index = 0; index < left.length; index++) {
      difference |= left.codeUnitAt(index) ^ right.codeUnitAt(index);
    }
    return difference == 0;
  }
}
