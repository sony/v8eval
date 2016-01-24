#ifndef V8EVAL_RUBY_H_
#define V8EVAL_RUBY_H_

#include "v8eval.h"

namespace v8eval {

class _RubyV8 : public _V8 {
 public:
  _RubyV8();
  virtual ~_RubyV8();
};

}  // namespace v8eval

#endif  // V8EVAL_RUBY_H_
