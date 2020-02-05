#
#
# Don't edit it, unless this is I_n_t_6_4_to_6_4_m_a_p implementation
#
# run sh all_from_XXX.sh to create it from blueprint - I_n_t_6_4_to_6_4_m_a_p
#
#

cdef class Int32to32Map:

    def __cinit__(self, size_hint=1, for_int32 = True):
        self.for_int32 = for_int32
        self.table = kh_init_int32to32map()
        if size_hint is not None:
            kh_resize_int32to32map(self.table, size_hint)

    def __len__(self):
        return self.size()
  
    cdef khint_t size(self):
        return self.table.size
        

    def __dealloc__(self):
        if self.table is not NULL:
            kh_destroy_int32to32map(self.table)
            self.table = NULL

    def __contains__(self, int32_t key):
        return self.contains(key)


    cdef bint contains(self, int32_t key) except *:
        cdef khint_t k
        k = kh_get_int32to32map(self.table, key)
        return k != self.table.n_buckets


    cpdef void put_int32(self, int32_t key, int32_t val) except *:
        cdef:
            khint_t k
            int ret = 0

        k = kh_put_int32to32map(self.table, key, &ret)
        self.table.keys[k] = key
        self.table.vals[k] = val

    cpdef void put_float32(self, int32_t key, float32_t val) except *:
        self.put_int32(key, f32_to_i32(val));

    
    def __setitem__(self, key, val):
        if self.for_int32:
            self.put_int32(key, val)
        else:
            self.put_float32(key, val)

    cpdef int32_t get_int32(self, int32_t key) except *:
        k = kh_get_int32to32map(self.table, key)
        if k != self.table.n_buckets:
            return self.table.vals[k]
        else:
            raise KeyError("No such key: "+str(key))

    cpdef float32_t get_float32(self, int32_t key) except *:
        return i32_to_f32(self.get_int32(key))

    def __getitem__(self, key):
        if self.for_int32:
            return self.get_int32(key)
        else:
            return self.get_float32(key)

    
    cpdef void discard(self, int32_t key) except *:
        cdef khint_t k
        k = kh_get_int32to32map(self.table, key)
        if k != self.table.n_buckets:
            kh_del_int32to32map(self.table, k)


    cdef Int32to32MapIterator get_iter(self):
        return Int32to32MapIterator(self)

    def __iter__(self):
        return self.get_iter()


### Iterator:
cdef class Int32to32MapIterator:

    cdef void __move(self) except *:
        while self.it<self.size and not kh_exist_int32to32map(self.parent.table, self.it):
              self.it+=1       

    cdef bint has_next(self) except *:
        return self.it != self.parent.table.n_buckets
        
    cdef int32to32_key_val_pair next(self) except *:
        cdef int32to32_key_val_pair result 
        result.key = self.parent.table.keys[self.it]
        result.val = self.parent.table.vals[self.it]
        self.it+=1#ensure at least one move!
        self.__move()
        return result


    def __cinit__(self, Int32to32Map parent):
        self.parent = parent
        self.size = parent.table.n_buckets
        #search the start:
        self.it = 0
        self.__move()

    def __next__(self):
        if self.has_next():
            return self.next()
        else:
            raise StopIteration

### Utils:

def Int32to32Map_from_int32_buffer(int32_t[:] keys, int32_t[:] vals, double size_hint = 1.25):
    cdef Py_ssize_t n = len(keys)
    cdef Py_ssize_t b = len(vals)
    if b < n:
        n = b
    cdef Py_ssize_t start_size = <Py_ssize_t>(n*size_hint)+1
    res=Int32to32Map(start_size)
    cdef Py_ssize_t i
    for i in range(n):
        res.put_int32(keys[i], vals[i])
    return res

def Int32to32Map_from_float32_buffer(int32_t[:] keys, float32_t[:] vals,double size_hint = 1.25):
    cdef Py_ssize_t n = len(keys)
    cdef Py_ssize_t b = len(vals)
    if b < n:
        n = b
    cdef Py_ssize_t start_size = <Py_ssize_t>(n*size_hint)+1
    res=Int32to32Map(start_size, False)
    cdef Py_ssize_t i
    for i in range(n):
        res.put_float32(keys[i], vals[i])
    return res
    


