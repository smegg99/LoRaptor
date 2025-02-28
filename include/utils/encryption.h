// include/utils/encryption.h
#ifndef ENCRYPTION_H
#define ENCRYPTION_H

#include <string>

// Encrypts the plaintext using AES-128-CBC with the provided key.
// Returns the Base64 encoded ciphertext.
// Note: key should be at least 16 characters long; if not, it will be zero-padded;
// if longer than 16, only the first 16 bytes are used.
std::string encryptMessage(const std::string& key, const std::string& plaintext);

// Decrypts the Base64 encoded ciphertext using AES-128-CBC with the provided key.
// Returns the decrypted plaintext.
std::string decryptMessage(const std::string& key, const std::string& ciphertext);

#endif
