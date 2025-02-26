#ifndef BLE_OUTPUT_H
#define BLE_OUTPUT_H

#include <string>
#include "ble_comm.h"
#include "clioutput.h"

class BLECLIOutput : public CLIOutput {
public:
	BLECLIOutput(BLEComm* bleComm) : bleComm(bleComm) {}

	virtual void print(const std::string& s) override {
		bleComm->send(s);
	}

	virtual void println(const std::string& s) override {
		bleComm->send(s + "\n");
	}

	virtual void println() override {
		bleComm->send("\n");
	}

private:
	BLEComm* bleComm;
};

#endif
