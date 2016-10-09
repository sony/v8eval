%module v8eval
%include "std_string.i"

%{
#define SWIG_FILE_WITH_INIT
#include "v8eval_go.h"
%}

%rename(SetFlags) set_flags;

%include "v8eval.h"
%include "v8eval_go.h"
