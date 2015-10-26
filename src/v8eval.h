#ifndef V8EVAL_H_
#define V8EVAL_H_

#include <string>

#include "v8.h"
#include "v8-debug.h"

/// \file
namespace v8eval {

class DbgSrv;

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

 typedef void (*debugger_cb)(std::string&, void *opq);

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

  /// \brief Start a debug server associated with the V8 instance
  /// \param port The TCP/IP port the debugger will listen, at localhost
  /// \return success or not as boolean
  ///
  /// After the debugger is successfully started, it will be possible to
  /// send commands and receive events at the specified port. When the
  /// debugger is started, the Javascript's "debugger" statement will
  /// cause the V8 instance to halt and wait for instructions through
  /// the debugger port.
  bool debugger_enable(int port);

  /// \brief Stop the debug server, if running.
  ///
  /// The debug server, if currently running, will be stopped, causing
  /// connections to remote debuggers to be dropped.
  void debugger_disable();

 private:
  static void debugger_message_handler(const v8::Debug::Message& message);
  v8::Local<v8::Context> new_context();
  v8::Local<v8::String> new_string(const char* str);
  v8::Local<v8::Value> json_parse(v8::Local<v8::Context> context, v8::Local<v8::String> str);
  v8::Local<v8::String> json_stringify(v8::Local<v8::Context> context, v8::Local<v8::Value> value);

  bool debugger_init(debugger_cb cb, void *cbopq);
  bool debugger_send(const std::string& cmd);
  void debugger_process();
  void debugger_stop();

 private:
  v8::Isolate* isolate_;
  v8::Persistent<v8::Context> context_;
  class DbgSrv *dbg_server_;
  v8::Isolate* dbg_isolate_;
  debugger_cb callback_;
  void *callbackopq_;

  friend class DbgSrv;
};

}  // namespace v8eval

#endif  // V8EVAL_H_
