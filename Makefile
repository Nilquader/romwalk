ASM=wla-z80 -iov 
ASMLINK=wlalink -Sirv
CPCXFS=cpcxfs
TESTFILES=0
EXECNAME=romwalk

all: $(EXECNAME).rom $(EXECNAME).dsk $(EXECNAME).hfe

test: $(EXECNAME).rom $(EXECNAME).dsk
	arnold -kbdtype=1 -doublesize -drivea $(EXECNAME).dsk

clean:
	rm -rf $(EXECNAME).hfe
	rm -rf $(EXECNAME).dsk
	rm -rf $(EXECNAME).rom
	rm -rf $(EXECNAME).o
	rm -rf $(EXECNAME).sym
	rm -rf rom.lst
	rm -rf *~

$(EXECNAME).o: rom.asm
	$(ASM) rom.asm $(EXECNAME).o

$(EXECNAME).rom: $(EXECNAME).o
	$(ASMLINK) $(EXECNAME).l $(EXECNAME).rom
	
$(EXECNAME).dsk: $(EXECNAME).rom
	rm -rf $(EXECNAME).dsk
	$(CPCXFS) -nd $(EXECNAME).dsk 
	$(CPCXFS) $(EXECNAME).dsk -pb $(EXECNAME).rom
	$(CPCXFS) $(EXECNAME).dsk -pb '/home/johannes/Schreibtisch/game roms/arkanoid.rom'
	$(CPCXFS) $(EXECNAME).dsk -pb '/home/johannes/Schreibtisch/game roms/PACMAN.ROM' 
	$(CPCXFS) $(EXECNAME).dsk -pb '/home/johannes/Schreibtisch/game roms/Tempest.rom' 
	$(CPCXFS) $(EXECNAME).dsk -pb '/home/johannes/Schreibtisch/game roms/Oh-mummy.rom' 
	$(CPCXFS) $(EXECNAME).dsk -pb '/home/johannes/Schreibtisch/game roms/FRUITY.ROM'


$(EXECNAME).hfe: $(EXECNAME).dsk
	hxcfe -finput:$(EXECNAME).dsk -foutput:$(EXECNAME).hfe -conv

	
