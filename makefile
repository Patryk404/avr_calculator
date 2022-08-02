windows:
	./gavrasm.exe main.asm
	cp ./main.hex C:\avrdude-6.4-mingw32
linux:
	compile
	avrdude -c usbasp -p m88p -B8 -U flash:w:main.hex

compile:
	./gavrasm main.asm