```
ANY  = could be any one of the values below

NUM  = integer literal
STR  = pointer to static table
PTR  = pointer to heap
NULL = null pointer
BOOL = one of the fixed bool values
ADDR = code address

fixed values:
    - #NIL
    - #TRUE
    - #FALSE

+===============+======================+========================+====================+
|   Instruction |          Opcode args |             Stack Args |       Stack Return |
+===============+======================+========================+====================+
| NOOP          |                      |                        |                    |
+---------------+----------------------+------------------------+--------------------+
| CONST_NIL     |                      |                        |             (#NIL) |
+---------------+----------------------+------------------------+--------------------+
| CONST_TRUE    |                      |                        |            (#TRUE) |
| CONST_FALSE   |                      |                        |           (#FALSE) |
+---------------+----------------------+------------------------+--------------------+
| CONST_NUM     | (NUM)                |                        |              (NUM) |
| CONST_STR     | (STR)                |                        |              (STR) |
+---------------+----------------------+------------------------+--------------------+
| ADD_NUM       |                      | (NUM, NUM)             |              (NUM) |
| SUB_NUM       |                      | (NUM, NUM)             |              (NUM) |
| MUL_NUM       |                      | (NUM, NUM)             |              (NUM) |
| DIV_NUM       |                      | (NUM, NUM)             |              (NUM) |
| MOD_NUM       |                      | (NUM, NUM)             |              (NUM) |
+---------------+----------------------+------------------------+--------------------+
| CONCAT_STR    |                      | (STR, STR)             |              (STR) |
| FORMAT_STR    | (fmt:STR, argc:NUM)  | (...ANY)               |              (STR) |
+---------------+----------------------+------------------------+--------------------+
| LT_NUM        |                      | (NUM, NUM)             |             (BOOL) |
| GT_NUM        |                      | (NUM, NUM)             |             (BOOL) |
| EQ_NUM        |                      | (NUM, NUM)             |             (BOOL) |
+---------------+----------------------+------------------------+--------------------+
| JUMP          | (ADDR)               |                        |                    |
| JUMP_IF_TRUE  | (ADDR)               | (BOOL)                 |                    |
| JUMP_IF_FALSE | (ADDR)               | (BOOL)                 |                    |
+---------------+----------------------+------------------------+--------------------+
| LOAD          | (offset:NUM)         |                        |              (ANY) |
| STORE         | (offset:NUM)         | (ANY)                  |                    |
+---------------+----------------------+------------------------+--------------------+
| ALLOC_MEM     | (size:NUM)           |                        |              (PTR) |
| LOAD_MEM      |                      | (PTR, offset:NUM)      |              (ANY) |
| STORE_MEM     |                      | (PTR, offset:NUM, ANY) |                    |
| FREE_MEM      |                      | (PTR)                  |                    |
| CLEAR_MEM     |                      | (PTR)                  |                    |
| COPY_MEM      |                      | (from:PTR, to:PTR)     |                    |
| COPY_MEM_FROM | (start:NUM, end:NUM) | (from:PTR, to:PTR)     |                    |
+---------------+----------------------+------------------------+--------------------+
| LOAD_ARG      | (offset:NUM)         |                        |              (ANY) |
| CALL          | (f:ADDR, argc:NUM)   |                        |                    |
| RETURN        |                      |                        | (return_value:ANY) |
+---------------+----------------------+------------------------+--------------------+
| DUP           |                      |                        |                    |
| POP           |                      |                        |                    |
| SWAP          |                      |                        |                    |
+---------------+----------------------+------------------------+--------------------+
| PRINT         |                      | (ANY)                  |                    |
| WARN          |                      | (ANY)                  |                    |
| PRINTF        | (fmt:STR, argc:NUM)  | (...ANY)               |                    |
| WARNF         | (fmt:STR, argc:NUM)  | (...ANY)               |                    |
+---------------+----------------------+------------------------+--------------------+
| HALT          |                      |                        |                    |
+---------------+----------------------+------------------------+--------------------+
```




