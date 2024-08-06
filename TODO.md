# VM

## TODO:

- rename MEM to HEAP
- rename STRINGS to STATICS or CONSTS

- Pointers
    - add from where it was allocated??
        - stack of heap
        - we only care if we are going to de-alloc stack things
    - add NullPointer class??
        - after FREE, put this there
        - current `undef` basically funcions as this


class Pointer {
    field $address = 0x00; # the location of the pointer
    field $bloack  = 0x00; # STACK, HEAP, CONSTS
    field $size    = 0;    # number of contiguious cells
}


- run should accept a number of cycles to perform
    - and because it returns the VM::State
        - this could become a Thread ... hmm

- write more tests
    - for errors in particular

- Instructions for:
    - VECTORS
        - maybe for SIMD instructions



