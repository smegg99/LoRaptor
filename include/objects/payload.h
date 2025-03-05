// include/objects/payload.h
#ifndef PAYLOAD_H
#define PAYLOAD_H

#include <string>
#include <cstdint>

class Payload {
public:
	Payload() = default;
	Payload(std::string publicWord, uint32_t epoch = 0, std::string message = "");

	// Encodes this payload into a single encrypted and compressed string.
	// Returns true on success and fills encodedOut; false on any failure.
	bool encode(const std::string& encryptionKey, std::string& encodedOut) const;

	// Decodes the given encrypted and compressed data into a Payload instance.
	// Returns true if successful and if the decrypted public word matches PUBLIC_WORD 
	// (defined in config.h); false otherwise.
	static bool decode(const std::string& encryptedCompressedData, const std::string& encryptionKey, Payload& pOut);

	std::string getPublicWord() const { return publicWord; }
	uint32_t getEpoch() const { return epoch; }
	std::string getMessage() const { return message; }
private:
	std::string publicWord;  // The public word, one which identifies the connection to which the message belongs
	uint32_t epoch;
	std::string message;
	// Compresses the input string using LZ4 and prepends a 4-byte header (big-endian)
	// that encodes the original (uncompressed) size.
	// Returns an empty string on failure.
	static std::string compressWithHeader(const std::string& input);
	static std::string decompressWithHeader(const std::string& input);
	static std::string encryptMessageInternal(const std::string& key, const std::string& plaintext);
	static std::string decryptMessageInternal(const std::string& key, const std::string& ciphertext);
};

#endif