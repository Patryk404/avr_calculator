.PHONY : compile linux   
windows: compile
	avrdude -c usbasp -p m88p -B8 -U flash:w:main.hex
linux: compile
	avrdude -c usbasp -p m88p -B8 -U flash:w:main.hex

compile:
	./gavrasm main.asm

upload: 
	avrdude -c usbasp -p m88p -B8 -U flash:w:main.hex
