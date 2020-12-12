import pyximport; 
pyximport.install(setup_args = {"script_args" : ["--force"]},
                  language_level=3)

import unittest
import uttemplate
import cymapinterfacetester as cyt
from cykhash import Int64toInt64Map, Int32toInt32Map, Float64toInt64Map, Float32toInt32Map, PyObjectMap

AS_LIST   = {'int64'   : cyt.as_py_list_int64, 
             'int32'   : cyt.as_py_list_int32, 
             'float64' : cyt.as_py_list_int64_float64,
             'float32' : cyt.as_py_list_int32_float32,
             'object'  : cyt.as_py_list_pyobject,
            } 
USE_INT   = {'int64'   : cyt.use_int64,
             'int32'   : cyt.use_int32,
             'float64' : cyt.use_int64_float64,
             'float32' : cyt.use_int32_float32,
             'object'  : cyt.use_pyobject,
            } 
USE_FLOAT = {'int64'   : cyt.use_float64,
             'int32'   : cyt.use_float32,
             'float64' : cyt.use_float64_float64,
             'float32' : cyt.use_float32_float32,
             'object'  : cyt.use_pyobject,
            } 
MAP       = {'int64'   : Int64toInt64Map,
             'int32'   : Int32toInt32Map,
             'float64' : Float64toInt64Map,
             'float32' : Float32toInt32Map,
             'object' :  PyObjectMap,
            }
#just making sure the interface can be accessed:

@uttemplate.from_templates(['int64', 
                            'int32', 
                            'float64',
                            'float32',
                           ])
class CyMypInterfaceTester(unittest.TestCase): 

   def template_cimport_use_int(self, map_type):
      received=USE_INT[map_type]([1,2,3,4], [5,6,7,8], [2,3])
      expected=[6,7]
      self.assertEqual(received, expected)

   def template_cimport_use_float(self, map_type):
      received=USE_FLOAT[map_type]([1,2,3,4], [5.5,6.5,7.5,8.5], [2,3])
      expected=[6.5,7.5]
      self.assertEqual(received, expected)

   def template_as_py_list(self, map_type):
      cy_map = MAP[map_type]()
      cy_map[3] = 20
      lst = AS_LIST[map_type](cy_map)
      self.assertEqual(lst, [3,20])

   def template_as_py_list_2(self, map_type):
      cy_map = MAP[map_type]()
      cy_map[3] = 5
      cy_map[4] = 6
      lst = AS_LIST[map_type](cy_map)
      self.assertEqual(set(lst), set([3,4,5,6]))


