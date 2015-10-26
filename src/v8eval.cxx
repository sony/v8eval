#include "v8eval.h"
#include "dbgsrv.h"

#include <stdlib.h>
#include <string.h>

#include "libplatform/libplatform.h"

namespace v8eval {

static v8::Platform* platform = nullptr;

bool initialize() {
  if (platform) {
    return false;
  }

  if (!v8::V8::InitializeICU()) {
    return false;
  }

  platform = v8::platform::CreateDefaultPlatform();
  v8::V8::InitializePlatform(platform);

  return v8::V8::Initialize();
}

bool dispose() {
  if (!platform) {
    return false;
  }

  v8::V8::Dispose();

  v8::V8::ShutdownPlatform();
  delete platform;
  platform = nullptr;

  return true;
}

class ArrayBufferAllocator : public v8::ArrayBuffer::Allocator {
 public:
  virtual void* Allocate(size_t length) {
    void* data = AllocateUninitialized(length);
    return data == NULL ? data : memset(data, 0, length);
  }

  virtual void* AllocateUninitialized(size_t length) {
    return malloc(length);
  }

  virtual void Free(void* data, size_t) {
    free(data);
  }
};

static ArrayBufferAllocator allocator;

_V8::_V8() {
  v8::Isolate::CreateParams create_params;
  create_params.array_buffer_allocator = &allocator;
  isolate_ = v8::Isolate::New(create_params);

  dbg_server_ = nullptr;
  dbg_isolate_ = nullptr;
  callback_ = nullptr;
  callbackopq_ = nullptr;

  // Use Isolate's local storage to store a pointer to the associated
  // V8 instance. This is retrieved in the V8 debugger's callback, as
  // the instance pointer is the only context we get from the caller.
  isolate_->SetData(0, this);

  v8::Locker locker(isolate_);

  v8::Isolate::Scope isolate_scope(isolate_);
  v8::HandleScope handle_scope(isolate_);
  context_.Reset(isolate_, new_context());
}

_V8::~_V8() {
  if (dbg_server_ != nullptr) {
    delete dbg_server_;
  }

  context_.Reset();
  isolate_->Dispose();
}

v8::Local<v8::Context> _V8::new_context() {
  if (context_.IsEmpty()) {
    v8::Local<v8::ObjectTemplate> global = v8::ObjectTemplate::New(isolate_);
    return v8::Context::New(isolate_, nullptr, global);
  } else {
    return v8::Local<v8::Context>::New(isolate_, context_);
  }
}

v8::Local<v8::String> _V8::new_string(const char* str) {
  return v8::String::NewFromUtf8(isolate_, str ? str : "", v8::NewStringType::kNormal).ToLocalChecked();
}

static std::string to_std_string(v8::Local<v8::Value> value) {
  v8::String::Utf8Value str(value);
  return *str ? *str : "Error: Cannot convert to string";
}

v8::Local<v8::Value> _V8::json_parse(v8::Local<v8::Context> context, v8::Local<v8::String> str) {
  v8::Local<v8::Object> global = context->Global();
  v8::Local<v8::Object> json = global->Get(context, new_string("JSON")).ToLocalChecked()->ToObject();
  v8::Local<v8::Function> parse = v8::Local<v8::Function>::Cast(json->Get(context, new_string("parse")).ToLocalChecked());

  v8::Local<v8::Value> result;
  v8::Local<v8::Value> value = str;
  if (!parse->Call(context, json, 1, &value).ToLocal(&result)) {
    return v8::Local<v8::Value>();  // empty
  } else {
    return result;
  }
}

v8::Local<v8::String> _V8::json_stringify(v8::Local<v8::Context> context, v8::Local<v8::Value> value) {
  v8::Local<v8::Object> global = context->Global();
  v8::Local<v8::Object> json = global->Get(context, new_string("JSON")).ToLocalChecked()->ToObject();
  v8::Local<v8::Function> stringify = v8::Local<v8::Function>::Cast(json->Get(context, new_string("stringify")).ToLocalChecked());

  v8::Local<v8::Value> result;
  if (!stringify->Call(context, json, 1, &value).ToLocal(&result)) {
    return new_string("");
  } else {
    return result->ToString();
  }
}

std::string _V8::eval(const std::string& src) {
  v8::Locker locker(isolate_);

  v8::Isolate::Scope isolate_scope(isolate_);
  v8::HandleScope handle_scope(isolate_);

  v8::Local<v8::Context> context = new_context();
  v8::Context::Scope context_scope(context);

  v8::TryCatch try_catch(isolate_);

  v8::Local<v8::String> source = new_string(src.c_str());

  v8::Local<v8::String> name = new_string("v8eval");
  v8::ScriptOrigin origin(name);

  v8::Local<v8::Script> script;
  if (!v8::Script::Compile(context, source, &origin).ToLocal(&script)) {
    return to_std_string(try_catch.Exception());
  } else {
    v8::Local<v8::Value> result;
    if (!script->Run(context).ToLocal(&result)) {
      return to_std_string(try_catch.Exception());
    } else {
      return to_std_string(json_stringify(context, result));
    }
  }
}

std::string _V8::call(const std::string& func, const std::string& args) {
  v8::Locker locker(isolate_);

  v8::Isolate::Scope isolate_scope(isolate_);
  v8::HandleScope handle_scope(isolate_);

  v8::Local<v8::Context> context = new_context();
  v8::Context::Scope context_scope(context);

  v8::TryCatch try_catch(isolate_);

  v8::Local<v8::Object> global = context->Global();
  v8::Local<v8::Value> result;
  if (!global->Get(context, new_string(func.c_str())).ToLocal(&result)) {
    return to_std_string(try_catch.Exception());
  } else if (!result->IsFunction()) {
    return "TypeError: '" + func + "' is not a function";
  }

  v8::Local<v8::Function> function = v8::Handle<v8::Function>::Cast(result);
  v8::Local<v8::Function> apply = v8::Handle<v8::Function>::Cast(function->Get(context, new_string("apply")).ToLocalChecked());
  v8::Local<v8::Value> arguments = json_parse(context, new_string(args.c_str()));
  if (arguments.IsEmpty() || !arguments->IsArray()) {
    return "TypeError: '" + args + "' is not an array";
  }

  v8::Local<v8::Value> values[] = { function, arguments };
  if (!apply->Call(context, function, 2, values).ToLocal(&result)) {
    return to_std_string(try_catch.Exception());
  } else {
    return to_std_string(json_stringify(context, result));
  }
}

bool _V8::debugger_enable(int port) {
  if (dbg_server_ != nullptr) {
    return false;
  }
  dbg_server_ = new DbgSrv(*this);
  if (!dbg_server_->start(port)) {
    delete dbg_server_;
    dbg_server_ = nullptr;
    return false;
  }
  return true;
}

void _V8::debugger_disable() {
  if (dbg_server_ != nullptr) {
    delete dbg_server_;
    dbg_server_ = nullptr;
  }
}

void _V8::debugger_message_handler(const v8::Debug::Message& message) {
  v8::Isolate* isolate = message.GetIsolate();
  _V8 *_v8 = (v8eval::_V8*)isolate->GetData(0);
  std::string string = *v8::String::Utf8Value(message.GetJSON());

  if (_v8->callback_ != nullptr) {
    _v8->callback_(string, _v8->callbackopq_);
  }
}

bool _V8::debugger_init(debugger_cb cb, void *cbopq) {
  v8::Isolate::CreateParams create_params;
  create_params.array_buffer_allocator = &allocator;
  dbg_isolate_ = v8::Isolate::New(create_params);

  if (callback_ != nullptr) {
    return false;
  }
  callback_ = cb;
  callbackopq_ = cbopq;

  // Set Debuger callback.
  v8::Locker locker(isolate_);
  v8::Isolate::Scope isolate_scope(isolate_);
  v8::HandleScope handle_scope(isolate_);
  v8::Debug::SetMessageHandler(debugger_message_handler);

  return true;
}

void _V8::debugger_process() {
  // Process debug messages on behalf of the V8 instance.
  v8::Locker locker(isolate_);
  v8::Isolate::Scope isolate_scope(isolate_);
  v8::HandleScope handle_scope(isolate_);

  v8::Debug::ProcessDebugMessages();
}

bool _V8::debugger_send(const std::string& cmd) {
  v8::Locker locker(dbg_isolate_);
  v8::Isolate::Scope isolate_scope(dbg_isolate_);
  v8::HandleScope handle_scope(dbg_isolate_);

  if (callback_ == nullptr) {
    return false;
  }

  v8::Local<v8::String> vstr = v8::String::NewFromUtf8(dbg_isolate_, cmd.c_str(), v8::NewStringType::kNormal).ToLocalChecked();
  v8::String::Value v(vstr);
  v8::Debug::SendCommand(isolate_, *v, v.length());
  return true;
}

void _V8::debugger_stop() {
  v8::Locker locker(isolate_);
  v8::Isolate::Scope isolate_scope(isolate_);
  v8::HandleScope handle_scope(isolate_);
  v8::Debug::SetMessageHandler(nullptr);

  callback_ = nullptr;
  callbackopq_ = nullptr;
  dbg_isolate_->Dispose();
  dbg_isolate_ = nullptr;
}

}  // namespace v8eval
