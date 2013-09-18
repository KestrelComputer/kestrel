\ ESIZE errors happen when a request is asking too much, or providing too little.
\ For example, on a 16K Kestrel-2 with a 6KB application loaded, attempting to
\ allocate more than 10KB of RAM will produce an ESIZE error.
100 const, ESIZE

\ EBASE errors occur when a data structure hasn't been properly initialized, and a
\ base address holds a provably wrong vaule.  Also known as EINIT in some cases.
101 const, EBASE
101 const, EINIT

\ ENOTFOUND errors occur when a resource cannot be found.
102 const, ENOTFOUND

\ ENAME errors occur when a resource name doesn't follow the expected syntax.
103 const, ENAME

\ EEOF errors occur when attempting I/O outside of allocated boundaries.
104 const, EEOF

