import pytest
from unittestmock import UnitTestMock

import pyximport; 
pyximport.install(setup_args = {"script_args" : ["--force"]},
                  language_level=3)

from cykhash import unique_int64, unique_int32, unique_float64, unique_float32
from cykhash import unique_stable_int64, unique_stable_int32, unique_stable_float64, unique_stable_float32
from uniqueinterfacetester import use_unique_int64, use_unique_int32, use_unique_float64, use_unique_float32
from uniqueinterfacetester import use_unique_stable_int64, use_unique_stable_int32, use_unique_stable_float64, use_unique_stable_float32

UNIQUE={'int64': unique_int64,
        'int32': unique_int32,
        'float64': unique_float64,
        'float32': unique_float32,
       }

STABLE={'int64': unique_stable_int64,
        'int32': unique_stable_int32,
        'float64': unique_stable_float64,
        'float32': unique_stable_float32,
       }

CY_UNIQUE={'int64': use_unique_int64,
           'int32': use_unique_int32,
           'float64': use_unique_float64,
           'float32': use_unique_float32,
       }

CY_STABLE={'int64': use_unique_stable_int64,
           'int32': use_unique_stable_int32,
           'float64': use_unique_stable_float64,
           'float32': use_unique_stable_float32,
       }


BUFFER_SIZE = {'int32': 'i', 'int64': 'q', 'float64' : 'd', 'float32' : 'f'}


import array

@pytest.mark.parametrize(
    "value_type",
    ['int64', 'int32', 'float64', 'float32']
)
class TestUniqueTester(UnitTestMock): 
    def test_unique(self, value_type):
        a = array.array(BUFFER_SIZE[value_type], [1,1,1,1,1,2,3,4,5])
        result = UNIQUE[value_type](a)
        as_set = set(memoryview(result))
        expected = set(array.array(BUFFER_SIZE[value_type], [1,2,3,4,5]))
        self.assertTrue(expected==as_set, msg = "received: "+str(as_set))


    def test_unique_stable(self, value_type):
        a = array.array(BUFFER_SIZE[value_type], [2,1,4,1,3,1,2,3,4,5])
        result = list(memoryview(STABLE[value_type](a)))
        expected = list([2,1,4,3,5])
        self.assertTrue(expected==result, msg = "received: "+str(result))


    def test_unique2(self, value_type):
        a = array.array(BUFFER_SIZE[value_type], list(range(100))+list(range(200))+list(range(100)))
        result = UNIQUE[value_type](a)
        as_set = set(memoryview(result))
        expected = set(array.array(BUFFER_SIZE[value_type], range(200)))
        self.assertTrue(expected==as_set, msg = "received: "+str(as_set))


    def test_cyunique(self, value_type):
        a = array.array(BUFFER_SIZE[value_type], list(range(100))+list(range(200))+list(range(100)))
        result = CY_UNIQUE[value_type](a)
        as_set = set(memoryview(result))
        expected = set(array.array(BUFFER_SIZE[value_type], range(200)))
        self.assertTrue(expected==as_set, msg = "received: "+str(as_set))


    def test_cyunique_stable(self, value_type):
        a = array.array(BUFFER_SIZE[value_type], [2,1,4,1,3,1,2,3,4,5])
        result = list(memoryview(CY_STABLE[value_type](a)))
        expected = list([2,1,4,3,5])
        self.assertTrue(expected==result, msg = "received: "+str(result))


    def test_ctypeslib_as_array(self, value_type):
        try:
            import numpy as np
        except:
            return
        a = array.array(BUFFER_SIZE[value_type], list(range(100))+list(range(200))+list(range(100)))
        result = CY_UNIQUE[value_type](a)
        as_set = set(np.ctypeslib.as_array(result))
        expected = set(array.array(BUFFER_SIZE[value_type], range(200)))
        self.assertTrue(expected==as_set, msg = "received: "+str(as_set))


    def test_frombuffer(self, value_type):
        try:
            import numpy as np
        except:
            return
        a = array.array(BUFFER_SIZE[value_type], list(range(100))+list(range(200))+list(range(100)))
        result = CY_UNIQUE[value_type](a)
        as_set = set(np.frombuffer(result, dtype=BUFFER_SIZE[value_type]))
        expected = set(array.array(BUFFER_SIZE[value_type], range(200)))
        self.assertTrue(expected==as_set, msg = "received: "+str(as_set))
        


 
