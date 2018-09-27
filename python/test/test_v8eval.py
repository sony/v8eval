import threading
import unittest
import v8eval


class V8Thread(threading.Thread):
    def __init__(self, test, num_repeat):
        threading.Thread.__init__(self)
        self.v8 = v8eval.V8()
        self.test = test
        self.num_repeat = num_repeat

    def run(self):
        n = 0
        self.v8.eval('function inc(x) { return x + 1; }')
        for i in range(self.num_repeat):
            n = self.v8.call('inc', [n])
        self.test.assertEqual(n, self.num_repeat)


class V8TestCase(unittest.TestCase):
    def test_eval(self):
        v8 = v8eval.V8()
        self.assertEqual(v8.eval('1 + 2'), 3)
        self.assertEqual(v8.eval('var p = { x: 1.1, y: 2.2 }; p'),
                         {'x': 1.1,
                          'y': 2.2})
        self.assertEqual(v8.eval(''), None)
        self.assertEqual(v8.eval('function inc(x) { return x + 1; }'), None)

        with self.assertRaises(TypeError):
            v8.eval(None)
        with self.assertRaises(v8eval.V8Error):
            v8.eval("foo")

    def test_call(self):
        v8 = v8eval.V8()
        v8.eval('function inc(x) { return x + 1; }')
        self.assertEqual(v8.call('inc', [7]), 8)

        with self.assertRaises(TypeError):
            v8.call(None, [7])
        with self.assertRaises(TypeError):
            v8.call('inc', None)
        with self.assertRaises(v8eval.V8Error):
            v8.call('i', [7])

    def test_multithreading(self):
        thread1 = V8Thread(self, 10000)
        thread2 = V8Thread(self, 10000)

        thread1.start()
        thread2.start()

        thread1.join()
        thread2.join()

if __name__ == '__main__':
    unittest.main()
