from libc.stdint cimport  uint32_t,  int64_t,  int32_t
from cpython.object cimport PyObject

from .floatdef cimport float64_t, float32_t

### Common definitions:
ctypedef PyObject* pyobject_t

include "khash.pxi"
include "murmurhash.pxi"


#utilities for int<->float
include "float_utils.pxi"
include "pyobject_utils.pxi"

# different implementation
include "maps/map_header.pxi"

