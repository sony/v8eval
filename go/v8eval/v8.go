package v8eval

import (
	"encoding/json"
	"errors"
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
}

type v8 struct {
	xV8 X_V8
}

// NewV8 creates a new V8 instance.
func NewV8() V8 {
	v := new(v8)
	v.xV8 = NewX_V8()
	return v
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
		} else {
			return errors.New(str)
		}
	}

	return nil
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
