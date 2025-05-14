# BACKLOG

## Input payload
[x] -  input on column = 0 is not getting undo 
example: person A writes "f" on the col = 0, then does undo, nothing changes in person B buffer meaning the "f" stays 

[] - first input is doubled
example: person A writes "f", person B receives "ff"

## Input newline
[] - need to create line buffer changes for newlines in client.lua
