// include/ble_output.h
#include "config.h"

#ifndef USE_SERIAL_COMM

#include "RaptorCLI.h"
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

class BLECLIOutput : public CLIOutput {
public:
	BLECLIOutput(BLEComm* bleComm) : bleComm(bleComm) {}

	void print(const std::string& s) override {
		bleComm->send(String(s.c_str()));
	}

	void println(const std::string& s) override {
		bleComm->send(String(s.c_str()) + '\n');
	}

	void println() override {
		bleComm->send(String('\n'));
	}

private:
	BLEComm* bleComm;
};

#endif