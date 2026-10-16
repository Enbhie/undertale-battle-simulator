TARGET = ubs.nes

$(TARGET): src/main.o nes.cfg
	ld65 -C nes.cfg -o $@ src/main.o

src/main.o: src/main.s
	ca65 -o $@ $<

clean:
	rm -f src/*.o $(TARGET)
