# the following is appended to swig-generated file including _PythonV8
import json, sys


PY3 = sys.version_info[0] == 3
if PY3:
    string_type = str
else:
    string_type = basestring


class V8Error(Exception):
    """Represents a V8 exception.

    Args:
        message (str): The message of a V8 exception.
    """
    def __init__(self, message):
        self.message = message

    def __str__(self):
        return self.message


class V8:
    """Represents a V8 instance."""
    def __init__(self):
        self._v8 = _PythonV8()

    def eval(self, src):
        """Evaluates JavaScript code.

        Args:
            src (str): JavaScript code.

        Returns:
            The result of the JavaScript code.
            The result is marshalled/unmarshalled by using JSON.

        Raises:
            TypeError: If src is not a string.

            V8Error: If some JavaScript exception happens.
        """
        if not isinstance(src, string_type):
            raise TypeError('source code not string')

        res = self._v8.eval(src)
        if res == 'undefined':
            return None
        else:
            try:
                return json.loads(res)
            except ValueError:
                raise V8Error(res)

    def call(self, func, args):
        """Calls a JavaScript function.

        Args:
            func (str): Name of a JavaScript function.

            args (list): Argument list to pass.

        Returns:
            The result of the JavaScript function.
            The result is marshalled/unmarshalled by using JSON.

        Raises:
            TypeError: If either func is not a string or args is not a list.

            V8Error: If some JavaScript exception happens.
        """
        if not isinstance(func, string_type):
            raise TypeError('function name not string')
        if not isinstance(args, list):
            raise TypeError('arguments not list')

        args_str = json.dumps(args)
        res = self._v8.call(func, args_str)
        if res == 'undefined':
            return None
        else:
            try:
                return json.loads(res)
            except ValueError:
                raise V8Error(res)


# initialize the V8 runtime environment
initialize()
