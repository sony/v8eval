# v8eval

[![Build Status](https://travis-ci.org/sony/v8eval.svg)](https://travis-ci.org/sony/v8eval)
[![PyPI version](https://badge.fury.io/py/v8eval.svg)](http://badge.fury.io/py/v8eval)
[![GoDoc](https://godoc.org/github.com/sony/v8eval/go/v8eval?status.png)](http://godoc.org/github.com/sony/v8eval/go/v8eval)

Multi-language bindings to JavaScript engine V8.

Currently v8eval provides Go and Python bindings to the latest V8 4.7 and supports Linux and Mac OS X.
v8eval uses SWIG and can be extended easily for other languages.

## Pre-installation

#### Linux

See [Dockerfile](https://github.com/sony/v8eval/blob/master/Dockerfile).

#### Mac

See [.travis.yml](https://github.com/sony/v8eval/blob/master/.travis.yml).

## Installation

The installation takes several tens of minutes due to V8 build.

#### Go

```
git clone https://github.com/sony/v8eval.git $GOPATH/src/github.com/sony/v8eval
$GOPATH/src/github.com/sony/v8eval/go/build.sh install
```

#### Python

```
pip install v8eval
```

## Documentation

#### Go

See [godoc.org](http://godoc.org/github.com/sony/v8eval/go/v8eval).

#### Python

You can create the Sphinx documentation under python/docs.

```
python/build.sh docs
```

## Examples

#### Go

```go
import "github.com/sony/v8eval/go/v8eval"

func Add(x, y int) int {
    var v8 = v8eval.NewV8()
    v8.Eval("var add = (x, y) => x + y;", nil)

    var sum int;
    v8.Call("add", []int{x, y}, &sum)
    return sum
}
```

#### Python

```python
import v8eval

def add(x, y):
    v8 = v8eval.V8()
    v8.eval('var add = (x, y) => x + y;')
    return v8.call('add', [x, y])
```

## License

The MIT License (MIT)

See [LICENSE](https://github.com/sony/v8eval/blob/master/LICENSE) for details.
