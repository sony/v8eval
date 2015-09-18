import v8eval

def add(x, y):
    v8 = v8eval.V8()
    v8.eval('function add(x, y) { return x + y; }')
    return v8.call('add', [x, y])

print add(1, 2)
