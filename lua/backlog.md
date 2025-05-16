# BACKLOG

## Input payload
[x] -  input on column = 0 is not getting undo 
example: person A writes "f" on the col = 0, then does undo, nothing changes in person B buffer meaning the "f" stays 

[x] - first input is doubled
example: person A writes "f", person B receives "ff"

[x] - buffer is doubled (caused by the above)

## Input newline
[] - while in insert mode, clicking enter doubles the line above
