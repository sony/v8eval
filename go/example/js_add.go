package main

import (
	"fmt"

	"github.com/sony/v8eval/go/v8eval"
)

func Add(x, y int) int {
	var v8 = v8eval.NewV8()
	v8.Eval("var add = (x, y) => x + y;", nil)

	var sum int
	v8.Call("add", []int{x, y}, &sum)
	return sum
}

func main() {
	v8eval.Initialize()
	fmt.Println(Add(1, 2))
	v8eval.Dispose()
}
