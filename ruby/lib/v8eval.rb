# require 'v8eval/v8eval' loads the V8eval module built by swig-generated extension
require 'v8eval/v8eval'

require 'json'

module V8Eval
  # Represents a V8 exception.
  class V8Error < StandardError; end

  # Represents a V8 instance.
  class V8
    def initialize
      @v8 = V8eval::V8.new
    end

    # Evaluates JavaScript code.
    # @param [String] src JavaScript code.
    # @return
    #   The result of the JavaScript code. The result is marshalled/unmarshalled by using JSON.
    # @raise [TypeError] If src is not a string.
    # @raise [V8Error] If some JavaScript exception happens.
    def eval(src)
      fail TypeError unless src.is_a?(String)
      res = @v8.eval(src)
      if res == 'undefined'
        return nil
      else
        begin
          return JSON.load(res)
        rescue
          raise V8Error, res
        end
      end
    end

    # Calls a JavaScript function.
    # @param [String] func Name of a JavaScript function.
    # @param [Array] args Argument list to pass.
    # @return
    #   The result of the JavaScript code. The result is marshalled/unmarshalled by using JSON.
    # @raise [TypeError] If either func is not a string or args is not a array.
    # @raise [V8Error] If some JavaScript exception happens.
    def call(func, args)
      fail TypeError unless func.is_a?(String)
      fail TypeError unless args.is_a?(Array)

      args_str = JSON.dump(args)
      res = @v8.call(func, args_str)
      if res == 'undefined'
        return nil
      else
        begin
          return JSON.load(res)
        rescue
          raise V8Error, res
        end
      end
    end
  end
end

# initialize the V8 runtime environment
V8eval.initialize
