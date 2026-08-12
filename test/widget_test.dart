import 'package:flutter_test/flutter_test.dart';
import 'package:pricewatch_apk/core/utils/password_hasher.dart';
import 'package:pricewatch_apk/core/utils/validators.dart';
import 'package:pricewatch_apk/shared/models/user_model.dart';

void main() {
  test('password hashing uses unique salts and verifies securely', () {
    final hashA = PasswordHasher.hashPassword(
      'Password123',
      email: 'user@pricewatch.app',
    );
    final hashB = PasswordHasher.hashPassword(
      'Password123',
      email: 'user@pricewatch.app',
    );

    expect(hashA, isNot(hashB));
    expect(
      PasswordHasher.verify(
        password: 'Password123',
        email: 'user@pricewatch.app',
        hash: hashA,
      ),
      isTrue,
    );
    expect(
      PasswordHasher.verify(
        password: 'Password123',
        email: 'user@pricewatch.app',
        hash: hashB,
      ),
      isTrue,
    );
  });

  test('email validator rejects bad input', () {
    expect(Validators.email('invalid-email'), isNotNull);
    expect(Validators.email('valid@example.com'), isNull);
  });

  test('user profiles never serialize legacy password hashes', () {
    const user = UserModel(
      id: 1,
      fullName: 'Community User',
      email: 'user@example.com',
      passwordHash: 'legacy-secret-hash',
      authUid: 'firebase-uid',
      role: 'user',
      createdAt: '2026-08-10T00:00:00.000Z',
    );

    expect(user.toMap(), isNot(contains('password_hash')));
  });
}
