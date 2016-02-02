import sketches

def get_sketch(sketch_type, hash_length, columns, rows, xi_func, 
                avg_func, hash_func):
    if sketch_type=='AGMS':
        if xi_func == "default": xi_func = "eh3"
        if hash_length==8:
            sketch = sketches.AGMS8(columns, rows, xi_func, avg_func)
        elif hash_length==16:
            sketch = sketches.AGMS16(columns, rows, xi_func, avg_func)
        elif hash_length==32:
            sketch = sketches.AGMS32(columns, rows, xi_func, avg_func)
        elif hash_length==64:
            sketch = sketches.AGMS64(columns, rows, xi_func, avg_func)
        elif hash_length==128:
            sketch = sketches.AGMS128(columns, rows, xi_func, avg_func)
        else:
            raise AttributeError('Hash length not valid: %i' % hash_length)
    elif sketch_type=='FAGMS':
        if hash_func == "default": hash_func = "cw2"
        if xi_func == "default": xi_func = "eh3"
        if hash_length==8:
            sketch = sketches.FAGMS8(columns, rows, xi_func, avg_func, 
                        hash_function=hash_func)
        elif hash_length==16:
            sketch = sketches.FAGMS16(columns, rows, xi_func, avg_func, 
                        hash_function=hash_func)
        elif hash_length==32:
            sketch = sketches.FAGMS32(columns, rows, xi_func, avg_func, 
                        hash_function=hash_func)
        elif hash_length==64:
            sketch = sketches.FAGMS64(columns, rows, xi_func, avg_func, 
                        hash_function=hash_func)
        elif hash_length==128:
            sketch = sketches.FAGMS128(columns, rows, xi_func, avg_func, 
                        hash_function=hash_func)
        else:
            raise AttributeError('Hash length not valid: %i' % hash_length)
    elif sketch_type=='FastCount':
        if hash_func == "default": hash_func = "cw4"
        if hash_length==8:
            sketch = sketches.FastCount8(columns, rows, hash_func, avg_func)
        elif hash_length==16:
            sketch = sketches.FastCount16(columns, rows, hash_func, avg_func)
        elif hash_length==32:
            sketch = sketches.FastCount32(columns, rows, hash_func, avg_func)
        elif hash_length==64:
            sketch = sketches.FastCount64(columns, rows, hash_func, avg_func)
        elif hash_length==128:
            sketch = sketches.FastCount128(columns, rows, hash_func, avg_func)
        else:
            raise AttributeError('Hash length not valid: %i' % hash_length)
    else:
        raise AttributeError('Sketch type not valid: %s' % sketch_type)
    return sketch

