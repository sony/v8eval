# the following is appended to swig-generated file including _V8
import json


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
        self._v8 = _V8()

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
        if not isinstance(src, basestring):
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
        if not isinstance(func, basestring):
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

    def debugger_enable(self, port):
        """"Starts a debug server associated with the V8 instance.

        Args:
            port (int): The TCP/IP port the server will listen, at localhost.

        Return:
            Success or not as a boolean.

        Raises:
            TypeError: If port is not an int.
        """
        if not isinstance(port, int):
            raise TypeError('port is not integer')

        return self._v8.debugger_enable(port)

    def debugger_disable(self):
        """"Stop the debug server, if running.

        Args:
            None.

        Returns:
            None.

        Raises:
            None.
        """
	self._v8.debugger_disable()

# initialize the V8 runtime environment
initialize()
