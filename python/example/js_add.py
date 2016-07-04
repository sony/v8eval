import v8eval

def add(x, y):
    v8 = v8eval.V8()
    v8.eval('var add = (x, y) => x + y;')
    return v8.call('add', [x, y])

print(add(1, 2))
