#
#
# Don't edit it, unless this is I_n_t_6_4_to_6_4_m_a_p implementation
#
# run sh all_from_XXX.sh to create it from blueprint - I_n_t_6_4_to_6_4_m_a_p
#
#

cdef class Float32to32Map:

    def __cinit__(self, iterable=None, *, number_of_elements_hint=None, for_int=True):
        """
        number_of_elements_hint - number of elements without the need of reallocation.
        for_int  if True, __setitem__/__getitem__ sets/gets a in32-object, otherwise a float32-object
        """
        self.for_int = for_int
        self.table = kh_init_float32to32map()
        if number_of_elements_hint is not None:
            kh_resize_float32to32map(self.table, element_n_to_bucket_n(number_of_elements_hint))
        cdef key_float32_t key
        cdef int32_t val_as_int
        cdef float32_t val_as_float
        if iterable is not None:
            if for_int:
                for key, val_as_int in iterable:
                    self.put_int32(key, val_as_int)
            else:
                for key, val_as_float in iterable:
                    self.put_float32(key, val_as_float)

    def __len__(self):
        return self.size()
  
    cdef khint_t size(self):
        return self.table.size
        

    def __dealloc__(self):
        if self.table is not NULL:
            kh_destroy_float32to32map(self.table)
            self.table = NULL

    def __contains__(self, key_float32_t key):
        return self.contains(key)


    cdef bint contains(self, key_float32_t key) except *:
        cdef khint_t k
        k = kh_get_float32to32map(self.table, key)
        return k != self.table.n_buckets


    cpdef void put_int32(self, key_float32_t key, int32_t val) except *:
        cdef:
            khint_t k
            int ret = 0

        k = kh_put_float32to32map(self.table, key, &ret)
        self.table.keys[k] = key
        self.table.vals[k] = val

    cpdef void put_float32(self, key_float32_t key, float32_t val) except *:
        self.put_int32(key, f32_to_i32(val));

    
    def __setitem__(self, key, val):
        if self.for_int:
            self.put_int32(key, val)
        else:
            self.put_float32(key, val)

    cpdef int32_t get_int32(self, key_float32_t key) except *:
        k = kh_get_float32to32map(self.table, key)
        if k != self.table.n_buckets:
            return self.table.vals[k]
        else:
            raise KeyError(key)

    cpdef float32_t get_float32(self, key_float32_t key) except *:
        return i32_to_f32(self.get_int32(key))
  
    cpdef void discard(self, key_float32_t key) except *:
        cdef khint_t k
        k = kh_get_float32to32map(self.table, key)
        if k != self.table.n_buckets:
            kh_del_float32to32map(self.table, k)

    cdef Float32to32MapIterator get_iter(self, int view_type):
        return Float32to32MapIterator(self, view_type)

    def clear(self):
        cdef Float32to32Map tmp=Float32to32Map()
        swap_float32map(self, tmp)

    def copy(self):
        return copy_float32map(self)

    def get(self, *args, **kwargs):
        if len(args)==0:
            raise TypeError("get() expected at least 1 arguments, got 0")
        if len(args)>2:
            raise TypeError("get() expected at most 2 arguments, got {0}".format(len(args)))
        if kwargs:
            raise TypeError("get() takes no keyword arguments")
        key = args[0]
        try:
            return self[key]
        except KeyError:
            if len(args)==1:
                return None
            return args[1]


    def keys(self):
        return Float32to32MapView(self, 0)

    def values(self):
        return Float32to32MapView(self, 1)

    def items(self):
        return Float32to32MapView(self, 2)

    def __iter__(self):
        return iter(self.keys())

    def __getitem__(self, key):
        if self.for_int:
            return self.get_int32(key)
        else:
            return self.get_float32(key)

    def __delitem__(self, key):
        cdef size_t old=self.size()
        self.discard(key)
        if old==self.size():
            raise KeyError(key)

    def __eq__(self, other):
        return are_equal_float32map(self,other)


### Iterator:
cdef class Float32to32MapIterator:

    cdef void __move(self) except *:
        while self.it<self.parent.table.n_buckets and not kh_exist_float32to32map(self.parent.table, self.it):
              self.it+=1       

    cdef bint has_next(self) except *:
        self.__move()
        return self.it < self.parent.table.n_buckets
      
    # doesn't work if there was change between last has_next() and next()       
    cdef float32to32_key_val_pair next(self) except *:
        cdef float32to32_key_val_pair result 
        result.key = self.parent.table.keys[self.it]
        result.val = self.parent.table.vals[self.it]
        self.it+=1#ensure at least one move!
        return result

    def __cinit__(self, Float32to32Map parent, view_type):
        self.parent = parent
        self.view_type = view_type
        #search the start:
        self.it = 0
        self.__move()

    def __next__(self):
        cdef float32to32_key_val_pair pair
        if self.has_next():
            pair=self.next()
            if self.view_type == 0:           # keys
                return pair.key
            if self.view_type == 1:           # vals
                if self.parent.for_int:
                    return pair.val
                else:
                    i32_to_f32(pair.val)
            else:                        # items
                if self.parent.for_int:
                    return (pair.key, pair.val)
                else:
                    return (pair.key, i32_to_f32(pair.val))
        else:
            raise StopIteration


cdef class Float32to32MapView:
    cdef Float32to32MapIterator get_iter(self):
        return Float32to32MapIterator(self.parent, self.view_type)  

    def __cinit__(self, Float32to32Map parent, view_type):
        self.parent = parent
        self.view_type = view_type

    def __iter__(self):
        return self.get_iter()

    def __len__(self):
        return self.parent.size()

    def __contains__(self, x):
        for y in self:
            if x==y:
                return True
        return False



### Utils:

def Float32to32Map_from_int32_buffer(key_float32_t[:] keys, int32_t[:] vals, double size_hint=0.0):
    cdef Py_ssize_t n = len(keys)
    cdef Py_ssize_t b = len(vals)
    if b < n:
        n = b
    cdef Py_ssize_t at_least_needed = element_n_from_size_hint(<khint_t>n, size_hint)
    res=Float32to32Map(number_of_elements_hint=at_least_needed, for_int=True)
    cdef Py_ssize_t i
    for i in range(n):
        res.put_int32(keys[i], vals[i])
    return res

def Float32to32Map_from_float32_buffer(key_float32_t[:] keys, float32_t[:] vals,double size_hint=0.0):
    cdef Py_ssize_t n = len(keys)
    cdef Py_ssize_t b = len(vals)
    if b < n:
        n = b
    cdef Py_ssize_t at_least_needed = element_n_from_size_hint(<khint_t>n, size_hint)
    res=Float32to32Map(number_of_elements_hint=at_least_needed, for_int=False)
    cdef Py_ssize_t i
    for i in range(n):
        res.put_float32(keys[i], vals[i])
    return res
    

cpdef void swap_float32map(Float32to32Map a, Float32to32Map b) except *:
    if a is None or b is None:
        raise TypeError("'NoneType' object is not iterable")

    cdef kh_float32to32map_t *tmp=a.table
    a.table=b.table
    b.table=tmp

    cdef bint tmp_for_int=a.for_int
    a.for_int=b.for_int
    b.for_int=tmp_for_int


cpdef Float32to32Map copy_float32map(Float32to32Map s):
    if s is None:
        return None
    cdef Float32to32Map result = Float32to32Map(number_of_elements_hint=s.size(), for_int=s.for_int)
    cdef Float32to32MapIterator it=s.get_iter(2)
    cdef float32to32_key_val_pair p
    while it.has_next():
        p = it.next()
        result.put_int32(p.key, p.val)
    return result

cpdef bint are_equal_float32map(Float32to32Map a, Float32to32Map b) except *:
    if a is None or b is None:
        raise TypeError("'NoneType' object is not iterable")
    if a.for_int!=b.for_int:
        return False
    if a.size()!=b.size():
        return False
    cdef Float32to32MapIterator it=a.get_iter(2)
    cdef float32to32_key_val_pair p
    while it.has_next():
        p = it.next()
        if not b.contains(p.key):
            return False
    return True



