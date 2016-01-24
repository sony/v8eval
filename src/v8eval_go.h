#ifndef V8EVAL_GO_H_
#define V8EVAL_GO_H_

#include "v8eval.h"

namespace v8eval {

class _GoV8 : public _V8 {
 public:
  _GoV8();
  virtual ~_GoV8();
};

}  // namespace v8eval

#endif  // V8EVAL_GO_H_
