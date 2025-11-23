import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final _storage = const FlutterSecureStorage();
  static const _keyStorageKey = 'aes_secret_key';

  encrypt.Key? _key;

  Future<void> init() async {
    String? storedKey = await _storage.read(key: _keyStorageKey);
    if (storedKey == null) {
      // Generate new key
      final key = encrypt.Key.fromSecureRandom(32);
      await _storage.write(
        key: _keyStorageKey,
        value: base64Url.encode(key.bytes),
      );
      _key = key;
    } else {
      _key = encrypt.Key(base64Url.decode(storedKey));
    }
  }

  // Check if encryption service is initialized
  bool get isInitialized => _key != null;

  String encryptMessage(String plainText) {
    if (_key == null) throw Exception('Encryption key not initialized');

    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(_key!));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    // Return IV + Ciphertext encoded in base64
    return '${base64.encode(iv.bytes)}:${encrypted.base64}';
  }

  String decryptMessage(String encryptedText) {
    if (_key == null) throw Exception('Encryption key not initialized');

    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) throw Exception('Invalid encrypted format');

      final iv = encrypt.IV(base64.decode(parts[0]));
      final encrypted = encrypt.Encrypted.fromBase64(parts[1]);

      final encrypter = encrypt.Encrypter(encrypt.AES(_key!));
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      // Silently fail for decryption errors
      return '[Encrypted Message]';
    }
  }

  // For exporting key to user
  Future<String?> getSecretKey() async {
    return await _storage.read(key: _keyStorageKey);
  }

  // For importing key (restore on new device)
  Future<void> setSecretKey(String keyBase64) async {
    await _storage.write(key: _keyStorageKey, value: keyBase64);
    _key = encrypt.Key(base64Url.decode(keyBase64));
  }
}
