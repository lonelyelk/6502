default:
	@./vasm6502 src/prog.s -o out/prog.bin -Fbin -dotdir

write:
	@minipro -p AT28C256 -w out/prog.bin
