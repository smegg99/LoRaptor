// include/encryption.h
#ifndef ENCRYPTION_H
#define ENCRYPTION_H

#include <Arduino.h>

// Encrypts the plaintext using AES-128-CBC with the provided key.
// Returns the Base64 encoded ciphertext.
// Note: key should be at least 16 characters long; if not, it will be zero-padded;
// if longer than 16, only the first 16 bytes are used.
String encryptMessage(const String& key, const String& plaintext);

// Decrypts the Base64 encoded ciphertext using AES-128-CBC with the provided key.
// Returns the decrypted plaintext.
String decryptMessage(const String& key, const String& ciphertext);

#endif
