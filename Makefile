USB=dev/sdb
VERSION=V1

build:snake.img

bootloader.bin: bootloader.asm
		nasm -f bin bootloader.asm -o bootloader.bin

snake.bin: snake$(VERSION).asm
		nasm -f bin snake$(VERSION).asm -o snake.bin

snake.img: snake.bin bootloader.bin
		dd if=/dev/zero of=snake.img bs=1024 count=512
		dd if=bootloader.bin of=snake.img conv=notrunc
		dd if=snake.bin of=snake.img bs=512 seek=1 conv=notrunc

runqemu: snake.img
		qemu-system-i386 -fda snake.img

clean:
		rm -f *.bin
		rm -f *.img
		clear

install: snake.img
ifeq ($(USB),"")
		@echo "Error: USB not defined"
else
		sudo dd if=snake.img of=$(USB)
endif

.PHONY = clean snakeWIP.img