#include "v8eval.h"

#include <thread>

#include "gtest/gtest.h"

namespace {

class V8Eval {
 public:
  V8Eval() {
    v8eval::initialize();
  }

  ~V8Eval() {
    v8eval::dispose();
  }
};

V8Eval v8eval;

}  // namespace

void test_eval() {
  v8eval::_V8 v8;

  ASSERT_STREQ("undefined", v8.eval("").c_str());
  ASSERT_STREQ("3", v8.eval("1 + 2").c_str());
  ASSERT_STREQ("\"𩸽\"", v8.eval("'\\ud867\\ude3d'").c_str());
  ASSERT_STREQ("undefined", v8.eval("function inc(x) { return x + 1; }").c_str());
  ASSERT_STREQ("8", v8.eval("inc(7)").c_str());
  ASSERT_STREQ("{\"a\":1,\"b\":2}", v8.eval("var x = { a: 1 }; x['b'] = 2; x").c_str());

  ASSERT_STREQ("ReferenceError: foo is not defined\n    at v8eval:1:1", v8.eval("foo").c_str());
  ASSERT_STREQ("SyntaxError: Invalid or unexpected token", v8.eval("@").c_str());
}

void test_call() {
  v8eval::_V8 v8;

  ASSERT_STREQ("undefined", v8.eval("function inc(x) { return x + 1; }").c_str());
  ASSERT_STREQ("9", v8.call("inc", "[8]").c_str());

  ASSERT_STREQ("TypeError: '[' is not an array", v8.call("inc", "[").c_str());
  ASSERT_STREQ("TypeError: 'foo' is not a function", v8.call("foo", "[]").c_str());

  ASSERT_STREQ("undefined", v8.eval("function fail() { return foo; }").c_str());
  ASSERT_STREQ("ReferenceError: foo is not defined", v8.call("fail", "[]").c_str());
}

void test_debugger() {
  v8eval::_V8 v8;

  ASSERT_FALSE(v8.enable_debugger(-1));

  int port = 12345;
  ASSERT_TRUE(v8.enable_debugger(port));
  ASSERT_FALSE(v8.enable_debugger(port));
  v8.disable_debugger();
}

TEST(V8EvalTest, Eval) {
  test_eval();
}

TEST(V8EvalTest, Call) {
  test_call();
}

TEST(V8EvalTest, Debugger) {
  test_debugger();
  test_debugger();
}

void test_eval_repeatedly() {
  for (int i = 0; i < 20; i++) {
    test_eval();
    std::cout << "." << std::flush;
    std::this_thread::sleep_for(std::chrono::milliseconds(10));
  }
}

void test_call_repeatedly() {
  for (int i = 0; i < 20; i++) {
    test_call();
    std::cout << "." << std::flush;
    std::this_thread::sleep_for(std::chrono::milliseconds(10));
  }
}

TEST(V8EvalTest, Multithreading) {
  std::thread eval(test_eval_repeatedly);
  std::thread call(test_call_repeatedly);
  eval.join();
  call.join();
  std::cout << std::endl;
}
