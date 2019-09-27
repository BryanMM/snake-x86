# snake-x86
Segunda tarea corta para el curso de Sistemas Operativos.

Requisitos:
    - Instalar nasm
    - Instalar qemu

Indicar el nombre del USB en el Makefile en la variable "USB", el nombre debe tener la estructura 'dev/sXX'.
Para ver el nombre se puede utilizar el siguiente comando:
> lsblk

Indicar el nombre de la versión de snake que desea ejecutar en el Makefile en la variable "VERSION".

Para generar los archivos 
> make build 

Para correr el juego en qemu:
> make runqemu

Para instalar el juego en el dispositivo USB:
> make install 