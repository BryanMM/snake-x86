# snake-x86
Segunda tarea corta para el curso de Sistemas Operativos.

Require de qemu para poder correrlo desde ubuntu, una vez instalado este software:

> nasm snake.asm -f bin -o snake.bin

y para correrlo 

> qemu-system-x86_64 -fda snake.bin
