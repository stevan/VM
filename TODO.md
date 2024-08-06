# VM

## TODO:

- add ALLOC_FUNCTION_PTR
- add CALL_DYNAMIC which accepts a function pointer

- Pointers
    - add code pointers
        - need instruction to get a function pointer
        - also need instruction to call a function from a pointer
        - QUESTIONS
            - should we store the function airty as the size???

    - MAYBE add stack pointers
        - need instruction to make a stack pointer
        - need a way to deref one of these
        - this might not be a good idea
            - and get complicated with knowing when it is allocated, etc.


- run should accept a number of cycles to perform
    - and because it returns the VM::State
        - this could become a Thread ... hmm

- write more tests
    - for errors in particular

- Instructions for:
    - VECTORS
        - maybe for SIMD instructions



