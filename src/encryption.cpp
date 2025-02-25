#include "encryption.h"
#include "mbedtls/aes.h"
#include "mbedtls/base64.h"

// Helper: Prepare a 16-byte AES key from the provided key string.
static void prepareAESKey(const String& key, unsigned char outputKey[16]) {
	memset(outputKey, 0, 16);
	int len = key.length();
	if (len > 16) len = 16;
	memcpy(outputKey, key.c_str(), len);
}

// Helper: Apply PKCS#7 padding. Returns a pointer to a new buffer with padded data (caller must free).
static unsigned char* pkcs7_pad(const unsigned char* input, size_t inputLen, size_t& paddedLen) {
	size_t pad = 16 - (inputLen % 16);
	paddedLen = inputLen + pad;
	unsigned char* buffer = new unsigned char[paddedLen];
	memcpy(buffer, input, inputLen);
	// Fill the padding bytes with the pad value.
	for (size_t i = inputLen; i < paddedLen; i++) {
		buffer[i] = pad;
	}
	return buffer;
}

// Helper: Remove PKCS#7 padding. Returns the length of the unpadded data.
static size_t pkcs7_unpad(unsigned char* input, size_t inputLen) {
	if (inputLen == 0) return 0;
	uint8_t pad = input[inputLen - 1];
	if (pad > 16) return inputLen; // Invalid padding.
	return inputLen - pad;
}

String encryptMessage(const String& key, const String& plaintext) {
	if (key.length() == 0) return plaintext;

	// Prepare AES key (16 bytes).
	unsigned char aesKey[16];
	prepareAESKey(key, aesKey);

	// Initialize AES context.
	mbedtls_aes_context aes;
	mbedtls_aes_init(&aes);
	if (mbedtls_aes_setkey_enc(&aes, aesKey, 128) != 0) {
		mbedtls_aes_free(&aes);
		return "";
	}

	// Use a fixed IV (all zeros). In production, use a random IV.
	unsigned char iv[16] = { 0 };

	// Get plaintext bytes.
	const char* pt = plaintext.c_str();
	size_t ptLen = plaintext.length();

	// Apply PKCS#7 padding.
	size_t paddedLen;
	unsigned char* paddedInput = pkcs7_pad((const unsigned char*)pt, ptLen, paddedLen);

	// Allocate output buffer.
	unsigned char* outputBuf = new unsigned char[paddedLen];
	memset(outputBuf, 0, paddedLen);

	// Encrypt using CBC mode.
	if (mbedtls_aes_crypt_cbc(&aes, MBEDTLS_AES_ENCRYPT, paddedLen, iv, paddedInput, outputBuf) != 0) {
		mbedtls_aes_free(&aes);
		delete[] paddedInput;
		delete[] outputBuf;
		return "";
	}
	mbedtls_aes_free(&aes);
	delete[] paddedInput;

	// Encode the ciphertext in Base64.
	size_t olen = 0;
	// Base64 output size: ((paddedLen+2)/3)*4 + 1
	size_t b64Len = ((paddedLen + 2) / 3) * 4 + 1;
	unsigned char* b64Buf = new unsigned char[b64Len];
	if (mbedtls_base64_encode(b64Buf, b64Len, &olen, outputBuf, paddedLen) != 0) {
		delete[] outputBuf;
		delete[] b64Buf;
		return "";
	}
	delete[] outputBuf;

	String cipherText = String((const char*)b64Buf);
	delete[] b64Buf;
	return cipherText;
}

String decryptMessage(const String& key, const String& ciphertext) {
	if (key.length() == 0) return ciphertext;

	// Prepare AES key.
	unsigned char aesKey[16];
	prepareAESKey(key, aesKey);

	// Initialize AES context.
	mbedtls_aes_context aes;
	mbedtls_aes_init(&aes);
	if (mbedtls_aes_setkey_dec(&aes, aesKey, 128) != 0) {
		mbedtls_aes_free(&aes);
		return "";
	}

	// Use the same fixed IV.
	unsigned char iv[16] = { 0 };

	// Decode the Base64 ciphertext.
	size_t decodedLen = 0;
	// Allocate buffer large enough.
	size_t b64MaxLen = ciphertext.length();
	unsigned char* decodedBuf = new unsigned char[b64MaxLen];
	if (mbedtls_base64_decode(decodedBuf, b64MaxLen, &decodedLen, (const unsigned char*)ciphertext.c_str(), ciphertext.length()) != 0) {
		mbedtls_aes_free(&aes);
		delete[] decodedBuf;
		return "";
	}

	// Allocate buffer for plaintext.
	unsigned char* outputBuf = new unsigned char[decodedLen];
	memset(outputBuf, 0, decodedLen);

	// Decrypt using CBC.
	if (mbedtls_aes_crypt_cbc(&aes, MBEDTLS_AES_DECRYPT, decodedLen, iv, decodedBuf, outputBuf) != 0) {
		mbedtls_aes_free(&aes);
		delete[] decodedBuf;
		delete[] outputBuf;
		return "";
	}
	mbedtls_aes_free(&aes);
	delete[] decodedBuf;

	// Remove PKCS#7 padding.
	size_t unpaddedLen = pkcs7_unpad(outputBuf, decodedLen);
	String plainText = "";
	for (size_t i = 0; i < unpaddedLen; i++) {
		plainText += (char)outputBuf[i];
	}
	delete[] outputBuf;
	return plainText;
}
