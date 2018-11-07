require 'v8eval'

RSpec.describe V8Eval, '#eval' do
  context 'with vaild source code' do
    it 'should evaluate the source code' do
      v8 = V8Eval::V8.new
      expect(v8.eval('1+2')).to eq 3
      expect(v8.eval('var p = { x: 1.1, y: 2.2 }; p')).to eq('x' => 1.1,
                                                             'y' => 2.2)
      expect(v8.eval('')).to eq nil

      expect { v8.eval(nil) }.to raise_exception(TypeError)
      expect { v8.eval('foo') }.to raise_exception(V8Eval::V8Error)
    end
  end
end

RSpec.describe V8Eval, '#call' do
  context 'with valid function and arguments' do
    it 'should evaluate the given function' do
      v8 = V8Eval::V8.new
      v8.eval('function inc(x) { return x + 1; }')
      expect(v8.call('inc', [7])).to eq 8

      expect { v8.call(nil, [7]) }.to raise_exception(TypeError)
      expect { v8.call('inc', nil) }.to raise_exception(TypeError)
      expect { v8.call('i', [7]) }.to raise_exception(V8Eval::V8Error)
    end
  end
end

RSpec.describe V8Eval, '#multithreading' do
  context 'with multithread execution' do
    it 'should execute concurrently' do
      def v8_thread(num_repeat)
        v8 = V8Eval::V8.new
        counter = 0
        thread = Thread.new do
          v8.eval('function inc(x) { return x + 1; }')
          num_repeat.times do
            counter = v8.call('inc', [counter])
          end
          expect(counter).to eq(num_repeat)
        end
        thread
      end

      num_repeat = 10_000

      thread1 = v8_thread(num_repeat)
      thread2 = v8_thread(num_repeat)

      thread1.join
      thread2.join
    end
  end
end
