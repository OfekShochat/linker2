# linker
hello, I'm taking an approach different to the linker repo (my other implementation, not finished at all though). it uses the structs of the different file types as drivers, and calls a set of functions from there that are standard to those structs.
the main thought is to give the drivers the thread pool and they will decide what to do. in src/Elf.zig I plan that every function that executes concurrently will have its thread-safe structures and it will copy the data to the ro data in the structure itself (preferably not really copy).
note that the structures are inspiried by zld and the thread pool and wait group is taken from the zig compiler, Im not sure if I need to copy their licenses.
