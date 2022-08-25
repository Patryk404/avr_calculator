.PHONY : compile upload   
main: compile upload
compile:
	avrasm2 -fI -o "main.hex" -W+ie -I"C:/Program Files (x86)\Atmel\Studio\7.0\Packs\atmel\ATmega_DFP\1.7.374\avrasm\inc"  -im88PAdef.inc -d "C:\Users\patry\Documents\Atmel Studio\7.0\avr_calc\avr_calc\Debug\avr_calc.obj"  main.asm  -I "C:\Program Files (x86)\Atmel\Studio\7.0\toolchain\avr8\avrassembler\Include" 

upload: 
	avrdude -c usbasp -p m88p -B8 -U flash:w:main.hex

clear_memory:
	avrdude -p m88p -c usbasp -B8 -e 
