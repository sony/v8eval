#ifndef V8EVAL_PYTHON_H_
#define V8EVAL_PYTHON_H_

#include "v8eval.h"

namespace v8eval {

class _PythonV8 : public _V8 {
 public:
  _PythonV8();
  virtual ~_PythonV8();
};

}  // namespace v8eval

#endif  // V8EVAL_PYTHON_H_
