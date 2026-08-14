//go:build darwin && cgo

package main

import (
	"bytes"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestUpstreamVoiceManifestIsComplete(t *testing.T) {
	manifest, err := loadVoiceManifest()
	if err != nil {
		t.Fatalf("loadVoiceManifest() error = %v", err)
	}
	if manifest.KernelRelease != "3.18.44" || manifest.Helper == "" {
		t.Fatalf("unexpected manifest: %+v", manifest)
	}
	if len(manifest.Files) != len(upstreamVoiceFiles) || len(manifest.Modules) != 2 {
		t.Fatalf("manifest files/modules = %d/%d", len(manifest.Files), len(manifest.Modules))
	}
	for _, file := range upstreamVoiceFiles {
		if len(file.SHA256) != 64 {
			t.Fatalf("%s has invalid SHA-256", file.Name)
		}
		if file.Mode == 0 {
			t.Fatalf("%s has no file mode", file.Name)
		}
	}
}

func TestMatchesSHA256(t *testing.T) {
	data := []byte("DJOneHub upstream runtime validation")
	if !matchesSHA256(data, "16c24e97c3b040c2397d38e6bbb89be3fd67cb6b45c84236db741ea4fd452008") {
		t.Fatal("known SHA-256 did not match")
	}
	if matchesSHA256(data, "0000000000000000000000000000000000000000000000000000000000000000") {
		t.Fatal("incorrect SHA-256 matched")
	}
}

func TestVoiceProvisionRequiresConfirmation(t *testing.T) {
	instance := &app{}
	recorder := httptest.NewRecorder()
	request := httptest.NewRequest(http.MethodPost, "/api/voice/provision", bytes.NewBufferString(`{"confirm":false}`))
	instance.voiceProvisionAPI(recorder, request)
	if recorder.Code != http.StatusBadRequest {
		t.Fatalf("voiceProvisionAPI() status = %d, want %d", recorder.Code, http.StatusBadRequest)
	}
}

func TestVoiceStatusNeverClaimsBundledRuntime(t *testing.T) {
	status := (&app{}).voiceStatus()
	if status["runtime_included"] != false {
		t.Fatalf("runtime_included = %#v, want false", status["runtime_included"])
	}
	if status["runtime_source"] != upstreamVoiceRuntimeSource {
		t.Fatalf("runtime_source = %#v, want %q", status["runtime_source"], upstreamVoiceRuntimeSource)
	}
}
