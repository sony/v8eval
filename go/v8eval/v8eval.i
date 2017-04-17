%module v8eval
%include "std_string.i"
%include "std_map.i"

%{
#define SWIG_FILE_WITH_INIT
#include "v8eval_go.h"
%}

%rename(SetFlags) set_flags;

namespace std {
    %template(MapStringUint) map<string,unsigned long long>;
}

%include "v8eval.h"
%include "v8eval_go.h"
