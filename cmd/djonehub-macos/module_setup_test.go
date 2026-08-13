package main

import "testing"

func TestParseUSBCompositionAndClassification(t *testing.T) {
	factory, err := parseUSBComposition(`+QCFG: "usbcfg",0x2CA3,0x4006,1,1,1,1,1,0,0`)
	if err != nil || !factory.isFactoryDJI() || factory.hasUAC() {
		t.Fatalf("factory parse = %#v, %v", factory, err)
	}
	uac, err := parseUSBComposition("AT+QCFG=\"USBCFG\"\r\n+QCFG: \"usbcfg\",0x2C7C,0x125,1,1,1,1,1,1,1\r\nOK")
	if err != nil || !uac.hasUAC() || !uac.hasADB() || !uac.isUACTarget() {
		t.Fatalf("UAC parse = %#v, %v", uac, err)
	}
	legacyUAC, err := parseUSBComposition(`+QCFG: "usbcfg",0x2C7C,0x125,1,1,1,1,1,0,1`)
	if err != nil || !legacyUAC.isLegacyUACTarget() || legacyUAC.hasADB() {
		t.Fatalf("legacy UAC parse = %#v, %v", legacyUAC, err)
	}
	if got := factory.command(); got != `AT+QCFG="USBCFG",0x2CA3,0x4006,1,1,1,1,1,0,0` {
		t.Fatalf("command = %q", got)
	}
}

func TestParseIMSConfiguration(t *testing.T) {
	configuration, capability, err := parseIMSConfiguration("AT+QCFG=\"ims\"\r\n+QCFG: \"ims\",1,1\r\nOK")
	if err != nil || configuration != 1 || capability != 1 {
		t.Fatalf("IMS parse = %d,%d err=%v", configuration, capability, err)
	}
	configuration, capability, err = parseIMSConfiguration(`+QCFG: "ims",2,0`)
	if err != nil || configuration != 2 || capability != 0 {
		t.Fatalf("disabled IMS parse = %d,%d err=%v", configuration, capability, err)
	}
}
