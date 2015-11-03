require 'v8eval'

def add(x, y)
  v8 = V8Eval::V8.new
  v8.eval('var add = (x, y) => x + y;')
  v8.call('add', [x, y])
end

puts add(1, 2)
