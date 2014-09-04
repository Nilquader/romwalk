.define version	$01
.define revision $02
.define romlist $8000
.define romnum $7ffe
.define listnum $7ffc

.define km_wait_char $bb06
.define kl_rom_select $b90f
.define kl_probe_rom $b915
.define kl_curr_selection $b912
.define txt_output $bb5a
.define txt_set_cursor $bb75 
.define scr_set_mode $bc0e

.define menuflag $ac01  ; basic variable, reset every time basic initializes
;.define menuflag $0030


.MEMORYMAP
DEFAULTSLOT 0
SLOTSIZE $4000
SLOT 0 $0000
SLOT 1 $4000
SLOT 2 $8000
SLOT 3 $c000
.ENDME

.ROMBANKMAP
BANKSTOTAL 1
BANKSIZE $4000
BANKS 1
.ENDRO


.BANK 0 SLOT 3
.ORGA $c000

  .DB $01,version,revision,$00
  .DW commands ; list in bank 3

  jp init
  jp mfmenue

commands:

  .db "MegaFlashMen",'u'+$80
  .db "M",'F'+$80
  .db $00

.section "main" force

mfmenue:
  push hl
  push de
  jp menustart

init:
  push hl
  push de
  push bc

  ;ld a, (menuflag)
  ;cp $55
  ;jr z, exit2 ; check if already running 
  ;ld a, $55 ; set running-flag
  ;ld (menuflag),a ; run only once 

  ld bc, $0423 ; pipe
  call addtobufferfw
  ld bc, $4004 ; m
  call addtobufferfw
  ld bc, $2006 ; f
  call addtobufferfw
  ld bc, $0402 ;ENTER
  call addtobufferfw
  
  pop bc
  pop de
  pop hl
  ret

addtobufferfw:
  push bc
  ld c,0
  call kl_probe_rom
  ld a,h
  pop bc
  di
  cp 0
  jp z, addtobuffer464
  rst $18 ; rst &18
  .dw calladdr664
  ei
  ret
addtobuffer464:
  rst $18 ; rst &18
  .dw calladdr464
  ei
  ret
calladdr464:
  .dw $1cfe
  .db $fe
calladdr664: ; and 6128 
  .dw $1e86
  .db $fe

menustart:
  ld b, 11
  ld hl, inks
  call printn

  ld hl, message
  call print

  xor a
  ld (romlist), a ; clear ROM list
  ld hl, romlist
  ld bc, 32*32
  ld de, romlist+1
  ldir

  ld hl, start ; copy main code to ram
  ld bc, endbin-start
  ld de, $4000
  ldir

  call $4000 ; jump to main code
  ld hl, $4000 ; clear temp area
  ld bc, $5000
  ld de, $4001
  ld (hl),0
  ldir

  jr nc, exit
startprogram:
; hl-6  : rst $18
; hl-5,4: dw (hl-3)
; hl-3,2: db $c009
; hl-1  : (romnumber) 
  pop de
  pop hl
  ld de, $0003
  or a ; clear carry
  sbc hl, de
  ld b, h
  ld c, l ; ld bc, hl
  or a ; clear carry
  sbc hl, de
  push hl
  ld (hl),$df ; ie. rst $18
  inc hl
  ld (hl), c
  inc hl
  ld (hl), b
  inc hl
  ld (hl), $09
  inc hl
  ld (hl), $c0
  inc hl
  ld (hl), a
  pop hl
  jp (hl)

exit:
  ld b, 13
  ld hl, resetscreen ; reset screen attributes
  call printn
exit2:
  pop de
  pop hl
  scf
  ;; ccf ; don't initialize this rom
  ret

start:
  call kl_curr_selection ; get current rom number
  inc a
  ld c, a
romloop:
  ld a, c
  cp 7 ; is this rom 7 (=dos)?
  jr z, romloopend2 ; don't list

  ld (romnum),bc 
  push bc ; save rom number for walking
  call kl_rom_select
  push bc ; save old rom number
  ld a, ($c000)
  cp $01 ; is rom as standard background rom?
  jr nz, romloopend
  ld hl, ($c004)

; get pointer in romlist
  ld ix, romlist 
  ld de, 32
  ld a, (listnum)
  or a
  jr z, romlist_firstelement
  ld b, a
romlist_mulloop:
  add ix, de
  djnz romlist_mulloop
romlist_firstelement:
  inc a
  ld (listnum), a

; store rom number
  ld a,(romnum)
  ld (ix+0), a

; store rom name
  ld hl,($c004)
  ld b, 0 ; zeichenzähler auf 0
loopsromname:
  ld a ,b
  cp 16 ; max. 16 zeichen kopieren
  jr z, romloopend 
  inc b
  inc ix
  ld a,(hl)
  and $7f
  ld (ix+0), a
  ld a, (hl)
  inc hl
  and $80
  jr z, loopsromname

romloopend:
  pop bc
  call kl_rom_select ; restore rom config

  pop bc
romloopend2:
  inc c
  ld a,c 
  cp 32 ; 32. ROM reached? Stop scanning
  jr nz, romloop

; print rom list
  ld b, 0 ; index in rom list
printromlistloop:
  push bc
  ld hl, romlist ; pointer to rom list
  ld a, b
  or a
  jr z, printromlistnomul
printromlistmul:
  ld de, 32
  add hl,de
  djnz printromlistmul
printromlistnomul:
  ld a,(hl)
  or a
  jr z, printromlistloop9 ; end of list reached?
  inc hl; advance to name
  pop bc  ; get rom number
  push hl
  ld h, 1
  ld l, b
  ld a, b
  cp 11
  jp m, firstcol - start + $4000
  ld h, 21
  sub 11
  ld l, a
firstcol:
  inc l
  sll l
  inc l
  call txt_set_cursor ; cursor positionieren
  pop hl
  ld a, 24
  call txt_output
  ld a, ' '
  call txt_output
  ld  a, b 
  add a, 'A'
  call txt_output
  ld a, ' '
  call txt_output
  ld a, 24
  call txt_output
  ld a, ' '
  call txt_output
  call print
  ld hl, newline
  call print
  inc b
  jr printromlistloop
printromlistloop9:
  pop bc ; adjust stack 

; choose a rom
  ld b, 0 ; count number of esc presses
chooserom:
 ; ld a, b
 ; or a
 ; jr z, chooserom1
;chooserom1:
  call km_wait_char
  cp $ef
  jr z, chooserom 
  cp 252
  jr nz, chooserom2
  inc b
  ld a, b
  cp 2
  scf 
  ccf  ; clear carry without affecting z
  ret z
  jp chooserom - start + $4000 ; if esc pressed less than max return to menu

chooserom2:
  ld b,0 ; reset esc counter
  sub 'a'
  jp m, chooserom - start + $4000 ; if less that 'a' return to menu
  ld hl, listnum
  cp (hl)
  jp p,  chooserom - start + $4000 ; if more than roms avail, return to menu

chooserommul:
  ld hl, romlist
  or a
  jr z, chooseromnomul
  ld de, 32
  ld b, a
chooserommulloop:
  add hl,de
  djnz chooserommulloop
chooseromnomul:
  ld a, (hl) ; get rom number

scf
ret 

  ld (callromnum - start + $4000), a
  rst $18
  .dw calladdr - start + $4000
  ret

calladdr:
  .dw $c009 ; execution address
callromnum:
  .db $02 ; rom config = 2
print:
  ld a,(hl)
  or a
  ret z
  call $bb5a
  inc hl
  jr print

printn: ; prints b characters at hl
  ld a,(hl)
  call $bb5a
  inc hl
  djnz printn
  ret

inks:
  .db $1c, 0, 0, 0 ;  INK 0,0,0
  .db $1c, 1, 24, 24 ;  INK 1,25,24 
  .db $1D, 0, 0 ; BORDER 0,0 
resetscreen:
  .db $1c, 0, 1, 1 ; INK 0,1
  .db $1c, 1, 24, 24 ; INK 1,24
  .db $1d, 1, 1 ; BORDER 24
  .db $04, 1 ; mode 1
message:
  .db $0c, " MegaFlash QuickStart by SPRING!",13,10
  .db $9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,0
newline:
  .db 13,10,13,10,0
endbin:
.ends


