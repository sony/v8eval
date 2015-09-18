#ifndef V8EVAL_H_
#define V8EVAL_H_

#include <string>

#include "v8.h"

/// \file
namespace v8eval {

/// \brief Initialize the V8 runtime environment
/// \return success or not as boolean
///
/// This method initializes the V8 runtime environment. It must be called before creating any V8 instance.
bool initialize();

/// \brief Dispose the V8 runtime environment
/// \return success or not as boolean
///
/// This method disposes the V8 runtime environment.
bool dispose();

/// \class _V8
///
/// _V8 instances can be used in multiple threads.
/// But each _V8 instance can be used in only one thread at a time.
class _V8 {
 public:
  _V8();
  virtual ~_V8();

  /// \brief Evaluate JavaScript code
  /// \param src JavaScript code
  /// \return JSON-encoded result or exception message
  ///
  /// This method evaluates the given JavaScript code 'src' and returns the result in JSON.
  /// If some JavaScript exception happens in runtime, the exception message is returned.
  std::string eval(const std::string& src);

  /// \brief Call a JavaScript function
  /// \param func Name of a JavaScript function
  /// \param args JSON-encoded argument array
  /// \return JSON-encoded result or exception message
  ///
  /// This method calls the JavaScript function specified by 'func'
  /// with the JSON-encoded argument array 'args'
  /// and returns the result in JSON.
  /// If some JavaScript exception happens in runtime, the exception message is returned.
  std::string call(const std::string& func, const std::string& args);

 private:
  v8::Local<v8::Context> new_context();
  v8::Local<v8::String> new_string(const char* str);
  v8::Local<v8::Value> json_parse(v8::Local<v8::Context> context, v8::Local<v8::String> str);
  v8::Local<v8::String> json_stringify(v8::Local<v8::Context> context, v8::Local<v8::Value> value);

 private:
  v8::Isolate* isolate_;
  v8::Persistent<v8::Context> context_;
};

}  // namespace v8eval

#endif  // V8EVAL_H_
