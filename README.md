# AVR CALCULATOR

Hi! My first approach to program hardware!
Fully coded in assembly.
Code uploaded by isp programmer.
Target device: Atmega88PA


RUN:

make
./avrdude.exe -c usbasp -p m88p -B8 -U flash:w:main.hex