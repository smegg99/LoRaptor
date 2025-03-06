// src/objects/payload.cpp
#ifdef __cplusplus
extern "C" {
#endif
#include "smaz2.h"
#ifdef __cplusplus
}
#endif
#include "objects/payload.h"
#include <sstream>
#include <string>
#include <chrono>
#include <cstdint>
#include <cstring>
#include <vector>
#include "config.h"
#include "mbedtls/aes.h"
#include "mbedtls/base64.h"

Payload::Payload(std::string publicWord, uint32_t epoch, std::string content, PayloadType type)
	: publicWord(publicWord), epoch(epoch), content(content), type(type) {
}

// Compress the input string using Smaz2.
// A 4-byte header (big-endian) is prepended to store the original uncompressed size.
std::string Payload::compressWithHeader(const std::string& input) {
	uint32_t origSize = input.size();

	// Smaz2 is optimized for very short strings. For safety, allocate an output buffer
	// that is twice the size of the input
	size_t out_buf_size = input.size() * 2;
	std::vector<char> out_buf(out_buf_size, 0);

	std::vector<char> input_copy(input.begin(), input.end());
	size_t compressedSize = smaz2_compress(
		reinterpret_cast<unsigned char*>(out_buf.data()), out_buf_size,
		reinterpret_cast<unsigned char*>(input_copy.data()), input.size());
	if (compressedSize == 0) {
		return "";
	}

	// Build the final string: first 4 bytes = original size (big-endian), then the compressed data.
	std::string compressed;
	compressed.resize(4 + compressedSize);
	compressed[0] = (origSize >> 24) & 0xFF;
	compressed[1] = (origSize >> 16) & 0xFF;
	compressed[2] = (origSize >> 8) & 0xFF;
	compressed[3] = origSize & 0xFF;
	memcpy(&compressed[4], out_buf.data(), compressedSize);

	return compressed;
}

// Decompress the data using Smaz2.
// Reads the 4-byte header to determine the expected uncompressed size.
std::string Payload::decompressWithHeader(const std::string& input) {
	if (input.size() < 4) {
		return "";
	}
	uint32_t origSize = ((unsigned char)input[0] << 24) |
		((unsigned char)input[1] << 16) |
		((unsigned char)input[2] << 8) |
		((unsigned char)input[3]);
	size_t compressed_len = input.size() - 4;

	std::vector<char> compressed_data(input.begin() + 4, input.end());
	std::vector<char> out_buf(origSize + 1, 0);
	size_t decompressedSize = smaz2_decompress(
		reinterpret_cast<unsigned char*>(out_buf.data()), out_buf.size(),
		reinterpret_cast<unsigned char*>(compressed_data.data()), compressed_len);
	if (decompressedSize == 0) {
		return "";
	}
	std::string decompressed(out_buf.data(), decompressedSize);
	return decompressed;
}

static void prepareAESKey(const std::string& key, unsigned char outputKey[16]) {
	memset(outputKey, 0, 16);
	int len = key.length();
	if (len > 16) {
		len = 16;
	}
	memcpy(outputKey, key.c_str(), len);
}

std::string Payload::encryptMessageInternal(const std::string& key, const std::string& plaintext) {
	if (key.empty()) {
		return plaintext;
	}
	unsigned char aesKey[16];
	prepareAESKey(key, aesKey);

	mbedtls_aes_context aes;
	mbedtls_aes_init(&aes);
	if (mbedtls_aes_setkey_enc(&aes, aesKey, 128) != 0) {
		mbedtls_aes_free(&aes);
		return "";
	}
	unsigned char iv[16] = { 0 };

	const char* pt = plaintext.c_str();
	size_t ptLen = plaintext.length();

	// Apply PKCS#7 padding.
	size_t pad = 16 - (ptLen % 16);
	size_t paddedLen = ptLen + pad;
	unsigned char* paddedInput = new unsigned char[paddedLen];
	memcpy(paddedInput, pt, ptLen);
	for (size_t i = ptLen; i < paddedLen; i++) {
		paddedInput[i] = pad;
	}

	unsigned char* outputBuf = new unsigned char[paddedLen];
	memset(outputBuf, 0, paddedLen);

	if (mbedtls_aes_crypt_cbc(&aes, MBEDTLS_AES_ENCRYPT, paddedLen, iv, paddedInput, outputBuf) != 0) {
		mbedtls_aes_free(&aes);
		delete[] paddedInput;
		delete[] outputBuf;
		return "";
	}
	mbedtls_aes_free(&aes);
	delete[] paddedInput;

	size_t olen = 0;
	size_t b64Len = ((paddedLen + 2) / 3) * 4 + 1;
	unsigned char* b64Buf = new unsigned char[b64Len];
	if (mbedtls_base64_encode(b64Buf, b64Len, &olen, outputBuf, paddedLen) != 0) {
		delete[] outputBuf;
		delete[] b64Buf;
		return "";
	}
	delete[] outputBuf;
	std::string cipherText(reinterpret_cast<char*>(b64Buf), olen);
	delete[] b64Buf;

	DEBUG_PRINTLN(("Encrypted message: " + cipherText).c_str());

	return cipherText;
}

std::string Payload::decryptMessageInternal(const std::string& key, const std::string& ciphertext) {
	if (key.empty()) {
		return ciphertext;
	}
	unsigned char aesKey[16];
	prepareAESKey(key, aesKey);

	mbedtls_aes_context aes;
	mbedtls_aes_init(&aes);
	if (mbedtls_aes_setkey_dec(&aes, aesKey, 128) != 0) {
		mbedtls_aes_free(&aes);
		return "";
	}
	unsigned char iv[16] = { 0 };

	size_t decodedLen = 0;
	size_t b64MaxLen = ciphertext.length();
	unsigned char* decodedBuf = new unsigned char[b64MaxLen];
	if (mbedtls_base64_decode(decodedBuf, b64MaxLen, &decodedLen,
		reinterpret_cast<const unsigned char*>(ciphertext.c_str()),
		ciphertext.length()) != 0) {
		mbedtls_aes_free(&aes);
		delete[] decodedBuf;
		return "";
	}

	unsigned char* outputBuf = new unsigned char[decodedLen];
	memset(outputBuf, 0, decodedLen);

	if (mbedtls_aes_crypt_cbc(&aes, MBEDTLS_AES_DECRYPT, decodedLen, iv, decodedBuf, outputBuf) != 0) {
		mbedtls_aes_free(&aes);
		delete[] decodedBuf;
		delete[] outputBuf;
		return "";
	}
	mbedtls_aes_free(&aes);
	delete[] decodedBuf;

	// Remove PKCS#7 padding.
	size_t unpaddedLen = decodedLen;
	if (decodedLen > 0) {
		uint8_t pad = outputBuf[decodedLen - 1];
		if (pad <= 16) {
			unpaddedLen = decodedLen - pad;
		}
	}
	std::string plainText(reinterpret_cast<char*>(outputBuf), unpaddedLen);
	delete[] outputBuf;
	return plainText;
}

bool Payload::encode(const std::string& encryptionKey, std::string& encodedOut) const {
	// Build the payload string in the format: "publicWord|epoch|type|content"
	std::ostringstream oss;
	oss << publicWord << "|" << epoch << "|" << toUint(type) << "|" << content;
	std::string payloadStr = oss.str();

	DEBUG_PRINTLN(("Encoding payload: " + payloadStr).c_str());

	std::string compressed = compressWithHeader(payloadStr);
	if (compressed.empty()) {
		return false;
	}

	DEBUG_PRINTLN(("Compressed payload: " + compressed).c_str());

	size_t originalSize = payloadStr.size();
	size_t compressedSize = compressed.size() - 4; // Subtract the 4-byte header
	float compressionRatio = 100.0f * (1.0f - static_cast<float>(compressedSize) / originalSize);
	DEBUG_PRINTLN(("Compression: Original size=" + std::to_string(originalSize) + 
				  " bytes, Compressed size=" + std::to_string(compressedSize) + 
				  " bytes, Saved " + std::to_string(compressionRatio) + "%").c_str());
	
	encodedOut = encryptMessageInternal(encryptionKey, compressed);
	return !encodedOut.empty();
}

bool Payload::decode(const std::string& encryptedCompressedData, const std::string& encryptionKey, Payload& pOut) {
	std::string decryptedCompressed = decryptMessageInternal(encryptionKey, encryptedCompressedData);
	if (decryptedCompressed.empty()) {
		return false;
	}
	std::string decompressedPayload = decompressWithHeader(decryptedCompressed);
	if (decompressedPayload.empty()) {
		return false;
	}
	// Expected format: "publicWord|epoch|type|message"
	size_t pos1 = decompressedPayload.find('|');
	if (pos1 == std::string::npos) {
		return false;
	}
	std::string pubWord = decompressedPayload.substr(0, pos1);
	size_t pos2 = decompressedPayload.find('|', pos1 + 1);
	if (pos2 == std::string::npos) {
		return false;
	}
	std::string epochStr = decompressedPayload.substr(pos1 + 1, pos2 - pos1 - 1);
	
	size_t pos3 = decompressedPayload.find('|', pos2 + 1);
	if (pos3 == std::string::npos) {
		return false;
	}
	std::string typeStr = decompressedPayload.substr(pos2 + 1, pos3 - pos2 - 1);
	std::string msg = decompressedPayload.substr(pos3 + 1);

	std::istringstream issEpoch(epochStr);
	uint32_t ep;
	if (!(issEpoch >> ep)) {
		return false;
	}
	
	std::istringstream issType(typeStr);
	uint8_t typeVal;
	if (!(issType >> typeVal)) {
		return false;
	}

	pOut.publicWord = pubWord;
	pOut.epoch = ep;
	pOut.type = toPayloadType(typeVal);
	pOut.content = msg;
	
	DEBUG_PRINTLN(("Decoded payload: " + pubWord + "|" + epochStr + "|" + typeStr + "|" + msg).c_str());
	return true;
}