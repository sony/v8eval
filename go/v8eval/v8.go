package v8eval

import (
	"encoding/json"
	"errors"
	"runtime"
	"strings"
)

// V8 is a Go interface for JavaScript engine V8
type V8 interface {
	// Eval evaluates the given JavaScript code 'src' and stores the result into 'res'.
	// The result is marshalled/unmarshalled by using JSON.
	// If the result is undefined, 'res' is not changed.
	// If the result cannot be stored into 'res' due to type mismatch, Eval returns the error.
	// If some JavaScript exception happens in runtime, Eval returns the exception as a Go error.
	Eval(src string, res interface{}) error

	// Call calls the JavaScript function specified by 'fun' with the given argument array 'args'
	// and stores the result into 'res'.
	// The arguments and the result are marshalled/unmarshalled by using JSON.
	// If the result is undefined, 'res' is not changed.
	// If the result cannot be stored into 'res' due to type mismatch, Eval returns the error.
	// If some JavaScript exception happens in runtime, Call returns the exception as a Go error.
	Call(fun string, args interface{}, res interface{}) error

	// GetHeapInformation returns back information on the current heap information that v8 is using
	GetHeapInformation() *IsolateHeapInfo

	// EnableDebugger starts a debug server associated with the V8 instance.
	// The server will listen on the given TCP/IP port.
	// If failing to start the server, EnableDebugger returns the error.
	EnableDebugger(port int) error

	// DisableDebugger stops the debug server, if running.
	DisableDebugger()
}

type v8 struct {
	xV8 X_GoV8
}

// NewV8 creates a new V8 instance.
func NewV8() V8 {
	v := new(v8)
	v.xV8 = NewX_GoV8()
	runtime.SetFinalizer(v, deleteV8)
	return v
}

func (v *v8) Eval(src string, res interface{}) error {
	return v.decode(v.xV8.Eval(src), res)
}

func (v *v8) Call(fun string, args interface{}, res interface{}) error {
	as, err := json.Marshal(args)
	if err != nil {
		return err
	}

	return v.decode(v.xV8.Call(fun, string(as)), res)
}

func (v *v8) decode(str string, val interface{}) error {
	if str == "undefined" {
		return nil
	}

	dec := json.NewDecoder(strings.NewReader(str))
	err := dec.Decode(val)
	if err != nil {
		if strings.HasPrefix(err.Error(), "json: ") {
			return err
		}

		return errors.New(str)
	}

	return nil
}

type IsolateHeapInfo struct {
	TotalAvailableSize uint64
	TotalHeapSize      uint64
	UsedHeapSize       uint64
}

func (v *v8) GetHeapInformation() *IsolateHeapInfo {
	infoMap := NewMapStringUint()
	v.xV8.Get_heap_statistics(infoMap)
	return &IsolateHeapInfo{TotalAvailableSize: infoMap.Get("total_available_size"), TotalHeapSize: infoMap.Get("total_heap_size"), UsedHeapSize: infoMap.Get("used_heap_size")}
}

func (v *v8) EnableDebugger(port int) error {
	if !v.xV8.Enable_debugger(port) {
		return errors.New("failed to start debug server")
	}

	return nil
}

func (v *v8) DisableDebugger() {
	v.xV8.Disable_debugger()
}
