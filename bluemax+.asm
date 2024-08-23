!to "bluemax+.prg", cbm
; By Tonny Roger Holm - dotBtty 2024 v10.0

; This program makes the SNES PETSCII robot interface work on Bluemax for Commodore 64 by merging original code with modified.
; This is NOT the full game, only the modifications. You will need C64Studio, Vice and the original game to be able to build this.
; There are some extra modifications including:
; - Rudder control
; - Speed up/down (Y axis)
; - Bomb shoot + down disable
; - Gun sway on rudder control

; SNES controller adapter can be bought from https://texelec.com/product/snes-adapter-commodore/
; Get a good SNES controller. Those cheap ones tend NOT to work. I know!
; Also consider bying "Attack of the PETSCII Robots" from The 8-Bit Guy https://www.the8bitguy.com/product/petscii-robots/
; Also thanks to Robin from 8-bit show and tell, you are a great inspiration.

;This is my very first 6502 assembly programming, a dream I have had for 40 years (!) :-)

; 
; Known issues:
; 1. Theme song is made shorter for fitting more code. This ommits "MUSIC PROGRAMMED BY STEPHEN C BIGGS" :-(
; 2. The Gun sway works well on ground targets, but on planes not so much.
; 3. The demo does not seem to drop bombs, quite possibly because of my shoot + down disabling.



; SNES Controls overview
;+------------------+-----------------------------------+--------------------------------------------------+
;| Button           | Function in Bluemax (In-Game)     | Function in Bluemax (Menu/Combo)                 |
;+------------------+-----------------------------------+--------------------------------------------------+
;| Button 2         | Downspeed                         |                                                  |
;| Button 0         | Fire / Unpause                    |                                                  |
;| Select           |                                   | Enter options (F3) / Change options (F5) / Pause |
;| Start            | Start / Reset (F7)                |                                                  |
;| Up               | Up                                |                                                  |
;| Down             | Down                              |                                                  |
;| Left             | Left                              |                                                  |
;| Right            | Right                             |                                                  |
;| Button 1         | Bomb                              |                                                  |
;| Snes X           | Upspeed                           | Pause (Select + X)                               |
;| Left Select      | Rudder Left                       | Enter options (F3) with Select                   |
;| Right Select     | Rudder Right                      | Change options (F5) with Select                  |
;+------------------+-----------------------------------+--------------------------------------------------+


;Support for cheats and enabling/disabling features can be done by a poke to address 30 before "run":
;0x01 (1):  Disables bomb drop when Down + Fire is pressed.
;0x02 (2):  Enables unlimited bombs.
;0x04 (4):  Enables unlimited fuel.
;0x08 (8):  Enables unlimited damage (invulnerability).
;0x10 (16): Disables plane lowscreen adjust limit

;Examples:
;Poke 30,0 (or not set) only keeps disable bomb drop when Down + Fire
;Poke 30,14 All cheats + disable bomb drop when Down + Fire
;Poke 30,17 Disable all ekstra functions



;Building instructions
;1. Use C64Studio and copy this code.
;2. Set up Vice 32 bit emulator as debugger tool in C64Studio
;3. Create a %folder% to gather all the files.
;4. Get hold of bluemax.prg original and copy to bluemaxorg.prg in the %folder% above
; My example sets the folder to G:\My Drive\C64\C64projects\BlueMax\bluemax\v6.0
; We do this in two main activities. Dumping and loading.
; In dumping we simply compile and take snips of the code into files.
; In loading we start the original game, intercept it and inject the pieces of code
; I use snappyrom-5.34-pal.crt to generate a loadable file after mixing all together.
; Make sure Vice is not configured with host/monitor/enable remote monitor 
; or the monitor will not display. Vice tends to enable this option when run + debug.


;5. Compile & run the code.
;6. You can exit test mode with escape "esc"
;7. Enter monitor Alt + H

;Dumping in Monitor, just paste the below text:

;Mkdir G:\My Drive\C64\C64projects\BlueMax\bluemax\v9.0
;Cd G:\My Drive\C64\C64projects\BlueMax\bluemax\v9.0
;bsave "Soundmem1" 0 $788a $7927
;bsave "Soundmem2" 0 $797c $7a2d
;bsave "Soundmem3" 0 $7a90 $7b61
;bsave "Intercept joystick inflight" 0 $5934 $5936
;bsave "Intercept bomb drop" 0 $63d7 $63d9
;Bsave "Intercept exit pause" 0 $438e $4390
;Bsave "intercept xmovement" 0 $5a04 $5a06 
;Bsave "Intercept enter pause v2" 0 $5d94 $5d96
;Bsave "Intercept in Menu" 0 $7173 $7175
;Bsave "Intercept in Game" 0 $4617 $4619
;Bsave "Intercept Functionkey v2" 0 $5d41 $5d43
;Bsave "Intercept bullet xmovement" 0 $6540 $6541
;bsave "Replace Text Startscreen" 0 $7339 $73b0


;Dumping done, now we can load and import
; Here you might want to load snappyrom, prepeare for snap (F1. Setup for snapshot  ), 
; And go to prompt (F7)
; Also prepeare a Virtual disk or folder for the resulting program file in Vice.

;Load "bluemaxorg.prg" 0
;w $D016
;X

;8. You need to run the program, and Monitor will pop back

;9. Importing in Monitor

;bload "Soundmem1" 0 $788a
;bload "Soundmem2" 0 $797c
;bload "Soundmem3" 0 $7a90
;Bload "Intercept Functionkey v2" 0 $5d41
;bload "Intercept joystick inflight" 0 5934
;bload "Intercept bomb drop" 0 63d7
;Bload "intercept xmovement" 0 $5a04
;Bload "Intercept in Menu" 0 $7173
;Bload "Intercept in Game" 0 $4617
;Bload "Intercept exit pause" 0 $438e
;Bload "Intercept enter pause v2" 0 $5d94 
;Bload "Intercept bullet xmovement" 0 $6540
;Bload "Replace Text Startscreen" 0 $7339



;10. To just test the code write x to exit montitor or
; cartfreeze to enter and save image.



;++++++++++++++++++++ Bluemax important memory locations +++++++++++++++++++++++++


addr_Bluemax_Joystick = $4016 ; This is where Bluemax stores movement.

addr_bomb_enable = $4046 ;If 1 go ahead, if 0 no drop. Shoot key?
addr_bomb_busy = $4047 ; If 0 go ahead. If FF then a bomb already on its way.
addr_bomb_dec_counter = $63f0  ;This needs to be removed to get infinite bombs NOP NOP NOP. Also jumpto for dropping bomb.
addr_bomb_and_logic = $63da ; Logic for checking fire button on bombing.
addr_bomb_and_logic_value = $63db ; #$10 will drop bomb on Down + Fire. #$00 drops bombs on downstick, and #$FF will not drop any bombs.

addr_fuel_dec_counter = $4605  ;This needs to be removed to get infinite bombs NOP NOP NOP. Also jumpto for dropping bomb.
addr_damage_dec_counter = $6998 ; This seems to be a combined damage enabler .C:6998  9D B9 40    STA $40B9,X. NOP NOP NOP should drop damage.

addr_altitude = $40DA ;1 is ground level.
addr_speed = $405a ; Max 200. Does not change screen speed.
addr_damage_Fuel = $40b9 ; 1 damage 0 ok
addr_damage_Bomb = $40ba ; 1 damage 0 ok
addr_damage_Manuver = $40bb ; 1 damage 0 ok
addr_damage_Gun = $40bc ; 1 damage 0 ok
addr_movementx = $40CA ; Start 39, MaxLeft 1e, MaxRight 87. Autocorrected if outside in routine at 5a04
addr_movementy = $40D2 ; Movement y axis - Bottom Screen (default and lowest) b4. Top screen 7e. Game resets to default under landing. 
;addr_post_enter_pause = $5DA2 ;Calling this with A=1 sets pause ingame.



;addr_bomb_and_logic_value:
; Set to #$00 and no bomb will be dropped.
; Set to #$FF and bomb will be dropped when joy down
; Set to #$10 and bomb will be dropped when joy down and fire at the same time.

addr_movementy_treshold = $5a4A; Org is .C:5a49  C9 B5       CMP #$B5 and detect the lowest (with highest number) possibly
addr_movementy_treshold_reset = $5a4e; .C:5a4d  A9 B4       LDA #$B4 and detect the lowest (with highest number) possibly reset value

addr_bullet_x = $40c7


; Zero Page addresses
SNES_LOW = $BE ;Holds SNES buttons organized to math a standard Joystick byte return from DC00 or DC01
SNES_HIGH = SNES_LOW + 1 ; This holds the status of SNES buttons that don't fit in SNES_LOW
SNES_TEMPAND = $C0 ; Temporary storage of A register before the method.
SNESJOY = $C1 ; A combined register for Joystick 2 AND SNES_LOW
LastFunctionKey = $20 ; Storing SNES last Function Key pressed for toggling function.
addr_ingame_or_menu = $21 ; Ingame 08, in menu 00
addr_functionkeys = $1F ;$4086 is where Bluemax stored Function keys pressed.


addr_settings_done = $1D  ; If #$01 Settings run
addr_settings = $1E  ; Decimal 30 This is where we set cutsom settings. 
addr_bullet_x_ratio = $1C ; The ratio for the bullet's x movement. Used during movementy (rudder)





* = $0801 "0801 - 080C Start of BASIC SYS line"          ; 
!basic 10, start   ; BASIC loader line SYS 2061 (decimal $0801)

* = $0810 "Start of actual machine code after the BASIC loader"

start:
    SEI                   ; Disable interrupts
    LDX #$FF              ; Clear stack
    TXS
    JSR $E544             ; Clear the screen using ROM routine
main_loop:
    JSR snes_read         ; Read and process SNES controller inputs into SNES_LOW and SNES_HIGH
    JSR display_snes_new  ; Display SNES states in new fashion
    JSR intercept_functionkey_v2; Testing function Key
    JSR display_functionkey
    JSR $F6ED ; Check runstop and exit if pressed.
    BNE main_loop
    RTS ;Return to prompt 



;Breakpoints we have found and set




* = $7339 "$7339 $73b0: Replace Text Startscreen"
;Three Lines 40 characters
;!text "            BY PETER ADAMS              " ;2
;!text "   COPYRIGHT 1983 SYNAPSE SOFTWARE      " ;3
;!text "          B O B     P O L I N / S       " ;1
;@7565 : "  MUSIC PROGRAMMED BY STEPHEN C BIGGS   ";4

 !text " BY PETER ADAMS    MODIFIED BY DOTBTTY  " ;2
 !text "   COPYRIGHT 1983 SYNAPSE SOFTWARE      " ;3
 !text "          B O B     P O L I N / S       " ;1




* = $5934 "$5934 $5936: Intercept joystick inflight"
JSR intercept_joystick ; Org is LDA $DC00 We capture here


* = $438e "$438e $4390: Intercept exit pause"  
;JSR intercept_exit_pause ; Org is LDA $DC00.
JSR intercept_joystick ; Org is LDA $DC00.

* = $63d7  "$63d7 $63d9: Intercept bomb drop"
JSR intercept_bomb ; Org is LDA $4016 

* = $5d41 "$5d41 $5d43: Intercept Functionkey v2"
JSR intercept_functionkey_v2 ;Org is LDA $DC01. This is also called by IRQ Vector

* = $5a04 "$5a04 $5a06: intercept_xmovement"
JSR intercept_xmovement ;Org is LDA $40CA

* = $5d94 "$5d94 $5d96: Intercept enter pause v2" 
JSR intercept_enter_pause_v2 ; Org is LDA $DC01

* = $7173 "$7173 $7175: Intercept in Menu" 
JSR intercept_in_menu ; Org is JSR $759C


* = $4617 "$4617 $4619: Intercept in Game" 
JMP intercept_in_game ; Org is JMP $4624


* = $6540 "$6540 $6541: Intercept bullet xmovement" 
ADC addr_bullet_x_ratio
; Org is: .C:6540  69 04       ADC #$04




   
* = $788a "$788a $7927: Soundmem #1"

brk ;Breaks before my code is important to stop the music...
brk


snes_read: ; This actually reads the SNES adapter into SNES_LOW and SNES_HIGH. 
           ; This should be called once before polling inputs from SNES_LOW (and SNES_HIGH)
           ; Avoid polling it more than once for each loop
    ;INIT Userport. For some reason seems (?) BlueMax has a routine here we need to make sure overrides, thus run each time. 
    ;               f488  A9 06       LDA #$06
    ;               f48a  8D 03 DD    STA $DD03
    
    
    LDA #$28            ; Set pins 3 and 5 as output
    STA $DD03
    ;INIT Userport end
    LDA #$20              ; Pulse the latch to read button states
    STA $DD01
    LDA #$00
    STA $DD01
    LDA #$FF              ; Default value LOW
    STA SNES_HIGH
    STA SNES_LOW
    LDX #$00 ; Bit counter
    LDY #$00 ; 0=SNES_LOW, 1=SNES_HIGH

read_buttons:
    LDA bit_masks_real, X      ; Load the bit mask for SNES hardware
    JSR read_data
    INX
    CPX #$02              ; Check if 2 bits are read SNES_HIGH
    BEQ swap_high
    CPX #$04              ; Check if 4 bits are read SNES_LOW
    BEQ swap_low
    CPX #$09              ; Check if 9 bits are read SNES_HIGH
    BEQ swap_high
    CPX #$0C              ; Check if all buttons are read 12 bit register 0-11
    BNE read_buttons
    
    RTS

swap_high:
    LDY #1                ; 0=SNES_LOW, 1=SNES_HIGH 
    JMP read_buttons

swap_low:
    LDY #0                ; 0=SNES_LOW, 1=SNES_HIGH 
    JMP read_buttons




intercept_enter_pause_v2: ; 
    ;LDA addr_ingame_or_menu ; Ingame 08, in menu 00
    ;BEQ intercept_enter_pause_exit:
    LDA $DC01 ; Start loading original code statement @ 5d94
    LDY SNES_HIGH
    CPY #%11111010 ; SELECT + SNES_X
    BNE intercept_enter_pause_exit:
    LDA #$EF ; Set Pause flag. $20 XOR is $EF, which sets the correct flag in $DC00.
intercept_enter_pause_exit:
    RTS



  
intercept_in_game ;
  PHA
  LDA #$08
  STA addr_ingame_or_menu ; Ingame 08, in menu 00
  PLA
  JMP $4624



intercept_joystick: ; Org is LDA $DC00 We capture here
  PHA
  JSR snes_read ;Read SNES data
  PLA
  LDA $DC00     ;Read joystick data
  AND SNES_LOW  ;We just combine those two inputs
  STA SNESJOY ; A combined register for Joystick 2 AND SNES_LOW / might be deleted later.
  RTS





* = $797c "$797c $7a2d: Soundmem #2"

BRK
BRK

read_data:
    STA SNES_TEMPAND      ; A register should hold the value to be applied, storing in a temp variable.
    LDA $DD01
    AND #$40
    BEQ data_is_zero      ; Data is zero is actually a positive hit
    JMP pulse_clock       ; Hit go to pulse clock

data_is_zero:             ; low means active
    LDA SNES_LOW, Y       ; Loading previously stored value
    AND SNES_TEMPAND      ; Combine
    STA SNES_LOW, Y       ; Store value

pulse_clock:
    LDA $DD01             ; Pulse clock
    ORA #$08
    STA $DD01
    AND #$F7
    STA $DD01
    RTS


;This flag for ingame inmenu could probably be much improved rather than poking each iteration
;But life is short and some trials and errors already. Feel free to spend time for a better code if you want :-)

 
; Bit masks for each button
; SNES input register
; Mind that the logic for using SNES_LOW and SNES_HIGH bytes are in the code, so this needs to be
; Altered if you want to change between LOW and HIGH
; Specially the Button (Firebutton) mappings might be changed for your liking. 
; I noticed the standard fire button mapping in Vice emulator for the Useport SNES pad seems a bit unlogic...

bit_masks_real: ; Mappings for real hardware.
    !byte %10111111  ; Bit0-SNES_B: SNES_LOW, Button 2
    !byte %11101111  ; Bit1-SNES_Y: SNES_LOW, Button 0
    !byte %11111110  ; Bit2-SNES_SELECT: SNES_HIGH, Snes Select
    !byte %11111101  ; Bit3-SNES_START: SNES_HIGH, Snes Start
    !byte %11111110  ; Bit4-SNES_UP: SNES_LOW, Up
    !byte %11111101  ; Bit5-SNES_DOWN: SNES_LOW, Down
    !byte %11111011  ; Bit6-SNES_LEFT: SNES_LOW, Left
    !byte %11110111  ; Bit7-SNES_RIGHT: SNES_LOW, Right
    !byte %11011111  ; Bit8-SNES_A: SNES_LOW, Button 1
    !byte %11111011  ; Bit9-SNES_X: SNES_HIGH, Snes X
    !byte %11110111  ; Bit10-SNES_LS: SNES_HIGH, Snes Left Select
    !byte %11101111  ; Bit11-SNES_RS: SNES_HIGH, Snes Right Select






intercept_xmovement: ;Org is LDA $40CA
    ;!byte %11110111  ; Bit10-SNES_LS: SNES_HIGH, Snes Left Select
    ;!byte %11101111  ; Bit11-SNES_RS: SNES_HIGH, Snes Right Select
    
  LDA #$04 ;Default ratio
  STA addr_bullet_x_ratio 
    
  LDA addr_ingame_or_menu ; If in menu $00, exit.
  BEQ intercept_xmovement_end
  LDA addr_altitude       ; if on ground $01 , exit.
  CMP #$01
  BEQ intercept_xmovement_end
  JSR inject_ymovement
  LDA SNES_HIGH
  AND #%00011000  ; Bit10-SNES_LS: SNES_HIGH, Snes Left Select. #$08 + Bit11-SNES_RS: SNES_HIGH, Snes Right Select #$10 (do nothing)
  BEQ intercept_xmovement_end
  
  LDA SNES_HIGH ;$BF
  AND #%00001000  ; Bit10-SNES_LS: SNES_HIGH, Snes Left Select. #$08
  BNE addr_movementx_next
  DEC addr_movementx
  LDA #$02 ;-2 ratio
  STA addr_bullet_x_ratio 
addr_movementx_next:
  LDA SNES_HIGH ;$BF
  AND #%00010000  ; Bit11-SNES_RS: SNES_HIGH, Snes Right Select #$10
  BNE intercept_xmovement_end
  INC addr_movementx
  LDA #$06 ;+2 Ratio
  STA addr_bullet_x_ratio
intercept_xmovement_end:  
  LDA addr_movementx 
  RTS

inject_ymovement:
;Version 2.0 - 2x movement + lowcreendetect on b4
;addr_movementy = $40D2 ; Movement y axis - Bottom Screen (default and lowest) b4. Top screen 7e. Game resets to default under landing

  ;Set default speed.
  LDY #$c8 ;Speed 200

  LDA SNES_LOW
  AND #%01000000       ; Check SNES_B (Downspeed)
  BNE inject_ymovement_upspeed
  INC addr_movementy   ; Increase y-movement
  INC addr_movementy   ; Increase y-movement
  LDY #$c3 ;Speed 195
  JMP inject_ymovement_End ; 

inject_ymovement_upspeed:
  LDA SNES_HIGH
  AND #%00000100       ; Check SNES_X (Upspeed)
  BNE check_upper_limit
  DEC addr_movementy   ; Decrease y-movement
  DEC addr_movementy   ; Decrease y-movement
  LDY #$cd ;Speed 205
  ;Check lower limit (no key pressed)

  
  LDA addr_movementy
  CMP #$7E             ; Check if y-movement is below the lower limit
  BCS inject_ymovement_End ; If above #$7E, no further action
  LDA #$7E             ; If below #$7E, set to #$7E
  STA addr_movementy
  JMP inject_ymovement_End


inject_ymovement_End:
  STY addr_speed
  RTS                  ; Return if no change in y-movement



check_upper_limit:
  LDA addr_movementy
  CMP #$B4             ; Compare with new upper limit
  BCC inject_ymovement_End ; If below #$B4, no further action
  DEC addr_movementy       ; We let the new addr_movementy_treshold handle the absolute treshold.
  JMP inject_ymovement_End




* = $7a90 "$7a90 $7b61: Soundmem #3 "
BRK
BRK

intercept_functionkey_v2:
; This i version 2 where we aim to emulat feedback for Function keys pressed back instead of $4086
; Key During  Function  Address
; F3 ($20) Options Enter Options $4086 set to $02 ; SNES_HIGH - Snes_Select - %11111110
; F5 ($40) Options Change Options  $4086 set to $03 ; SNES_HIGH - Snes_X - %11111011
; F7 ($08)  Options/Game  Start Game  $4086 set to $04 ; SNES_HIGH - Snes_Start - %11111101

LDA $DC01; Start of to load the original code that was in .C:5d41  AD 01 DC    LDA $DC01
PHA
JSR snes_read; Get the snes status
LDA SNES_HIGH
LDX #0                   ; Initialize X register for the loop
CMP #$FF                ; Compare SNES_HIGH with $FF
BNE inject_functionkeys_loop  ; If not Equal execute code.
STA LastFunctionKey          ;A is FF from test above - To avoid sending many keystrokes...
JMP inject_functionkeys_end

inject_functionkeys_loop:
    LDA function_key_table, X   ; Load key pattern from table
    CMP SNES_HIGH               ; Compare with SNES_HIGH
    BEQ inject_functionkeys_store_value ; If match, store corresponding value
    INX                         ; Increment X to next key pattern
    INX                         ; Skip to next value in the table
    CPX #$06                      ; Check if we've reached the end of the table
    BNE inject_functionkeys_loop  ; If not, continue looping
    LDA #$FF
    STA LastFunctionKey
    JMP inject_functionkeys_end  ; Return if no match found

inject_functionkeys_store_value:
    INX                         ; Increment to point to value in table
    LDA function_key_table, X   ; Load the corresponding value
    CMP LastFunctionKey
    BEQ inject_functionkeys_end
    STA LastFunctionKey
inject_functionkeys_end:
    PLA ;Get the value polled from $DC01 earlier
    AND LastFunctionKey ; Combined with snes buttons.
    RTS                         ; Return from subroutine
    


; Create a table of key values
function_key_table:
    !byte %11110110, $df  ; Snes_Select + SNES_LS  -> push_f3 $20 - 00100000 11011111 (ends up as $02 is $4086)
    !byte %11101110, $bf  ; Snes_Select + SNES_RS -> push_f5      $40 - 01000000 10111111 (ends up as $03 is $4086)
    !byte %11111101, $f7  ; Snes_Start -> push_f7  $08 - 00001000 11110111 (ends up as $04 is $4086)


intercept_bomb:
  LDA SNESJOY
  AND #$20         ; 0010 0000 - Isolate bit 5 (2nd button)
  BNE nobomb       ;If true (Zero) drop no bomb.
  LDA #$01
  STA addr_bomb_enable
  LDA addr_bomb_and_logic_value          ;#$05 Will sett true for the AND $10 after the return, but needs to be EOR (XOR)
  EOR #$FF
  JMP bombexit
nobomb:
  LDA addr_Bluemax_Joystick ;Loads value from normal
bombexit:
  RTS

intercept_in_menu ; 
  PHA
  LDA #$00
  STA addr_ingame_or_menu ; Ingame 08, in menu 00
  JSR inject_game_settings 
  PLA
  JSR $759C
  RTS
 
inject_game_settings: ;Game settings as set in poke 30,x

;0x01 (1): Disables bomb drop when Down + Fire is pressed.
;0x02 (2): Enables unlimited bombs.
;0x04 (4): Enables unlimited fuel.
;0x08 (8): Enables unlimited damage (invulnerability).

;Poke 30,0 (or not set) only keeps disable bomb drop when Down + Fire
;Poke 30,14 All cheats + disable bomb drop when Down + Fire


  LDA addr_settings_done
  BNE inject_game_settings_done ; If not 0, settings have already been applied

  ; Handle each game setting (only runs once)

  ; Disable bomb logic
  LDA addr_settings
  AND #%00000001
  BEQ disable_bomb_logic
  LDA #$10  ; Enable bomb on down + fire
  STA addr_bomb_and_logic_value
  JMP Check_Unlimited_Bombs

disable_bomb_logic:
  LDA #$FF  ; Disable bomb for down + fire
  STA addr_bomb_and_logic_value
  ; Continue to Check_Unlimited_Bombs without a jump


Check_Unlimited_Bombs:
  LDA addr_settings
  AND #%00000010
  BEQ Check_Unlimited_Fuel  ; Skip if the 2nd bit is not set

  ; Apply NOP for unlimited bombs
  LDA #$EA  ; NOP operation
  STA addr_bomb_dec_counter
  STA addr_bomb_dec_counter+1
  STA addr_bomb_dec_counter+2

Check_Unlimited_Fuel:
  LDA addr_settings
  AND #%00000100
  BEQ Check_Unlimited_Damage  ; Skip if the 3rd bit is not set

  ; Apply NOP for unlimited fuel
  LDA #$EA  ; NOP operation
  STA addr_fuel_dec_counter
  STA addr_fuel_dec_counter+1
  STA addr_fuel_dec_counter+2

Check_Unlimited_Damage:
  LDA addr_settings
  AND #%00001000
  BEQ inject_movementy_treshold  ; Skip if the 4th bit is not set

  ; Apply NOP for unlimited damage
  LDA #$EA  ; NOP operation
  STA addr_damage_dec_counter
  STA addr_damage_dec_counter+1
  STA addr_damage_dec_counter+2
  

inject_movementy_treshold:
  
;addr_movementy_treshold = $5a4A; Org is .C:5a49  C9 B5       CMP #$B5 and detect the lowest (with highest number) possibly
;addr_movementy_treshold_reset = $5a4e; .C:5a4d  A9 B4       LDA #$B4 and detect the lowest (with highest number) possibly reset value

  LDA addr_settings
  AND #%00010000
  BNE inject_game_settings_done  ; Skip if the 5th bit is set

  ; Apply NOP for unlimited damage
  LDA #$cd ; New treshold values replaces #$B5 As tested and works
  STA addr_movementy_treshold
  LDA #$cc ;Reset to set -1
  STA addr_movementy_treshold_reset
  

inject_game_settings_done:
  LDA #$01
  STA addr_settings_done
  RTS


* = $7b62 "7b62 *: Section For test only, after SoundBank #3 in test build"

display_functionkey:
    PHA
    JSR PRINT_FUNCTIONKEY
    PLA
    LDY #$04
    JSR display_binary
    RTS


PRINT_FUNCTIONKEY:
    LDA #<textf  ; Load the low byte of the address of the text string
    LDY #>textf  ; Load the high byte of the address of the text string
    JMP $AB1E             ; Call the ROM routine to print the string
    RTS
textf:
    !text "FUNCTIONKEY:", 0


display_snes_new:


    JSR $E566             ; Home the cursor using ROM routine
    
    JSR PRINT_HEADER
    LDA #$0D             ; Return Char
    JSR $ffd2            ; Display Return char
    JSR PRINT_SNES_LOW
    LDA SNES_LOW
    LDY #$00
    JSR display_binary
    JSR PRINT_SNES_HIGH
    LDA SNES_HIGH
    LDY #$01
    JSR display_binary
    JSR PRINT_DC01
    LDA $DC01
    LDY #$02
    JSR display_binary
    JSR PRINT_DC00
    LDA $DC00
    LDY #$03
    JSR display_binary
    RTS


PRINT_HEADER:
    LDA #<text0  ; Load the low byte of the address of the text string
    LDY #>text0  ; Load the high byte of the address of the text string
    JMP $AB1E             ; Call the ROM routine to print the string
    RTS
text0:
    !text "BITS       :12345678", 0

PRINT_SNES_LOW:
    LDA #<text1  ; Load the low byte of the address of the text string
    LDY #>text1  ; Load the high byte of the address of the text string
    JMP $AB1E             ; Call the ROM routine to print the string
    RTS
text1:
    !text "SNES LOW   :", 0

PRINT_SNES_HIGH:
    LDA #<text2  ; Load the low byte of the address of the text string
    LDY #>text2  ; Load the high byte of the address of the text string
    JMP $AB1E             ; Call the ROM routine to print the string
    RTS
text2:
    !text "SNES HIGH  :", 0

PRINT_DC00:
    LDA #<text3  ; Load the low byte of the address of the text string
    LDY #>text3  ; Load the high byte of the address of the text string
    JMP $AB1E             ; Call the ROM routine to print the string
    RTS
text3:
    !text "DC00       :", 0

PRINT_DC01:
    LDA #<text4  ; Load the low byte of the address of the text string
    LDY #>text4  ; Load the high byte of the address of the text string
    JMP $AB1E             ; Call the ROM routine to print the string
    RTS
text4:
    !text "DC01       :", 0



display_binary:
; Subroutine to display binary value of A at the column specified by Y

    STY current_column    ; Save column position in variable
    STA input_value       ; Save A register in variable
    LDX #$08                ; Initialize bit counter to 8
display_binary_loop:
    LDA input_value       ; Load the saved A value
    ASL A                 ; Shift left, move next bit into carry
    STA input_value       ; Save the shifted A value back into the variable
    BCC bit_is_zero       ; Branch if carry is clear (bit is 0)
    LDA #$31              ; PETSCII for '1' 0011 0001
    JMP display_char
bit_is_zero:
    LDA #$30              ; PETSCII for '0' 0011 0000
display_char:
    JSR $AB47             ; Output character to screen
    DEX                   ; Decrement bit counter
    BNE display_binary_loop ; Loop until all bits are processed
    LDA #$0D             ; Return Char
    JSR $ffd2            ; Display Return char
    RTS                   ; Return from subroutine


; Variables to store the current column position and input value
current_column: !byte 0
input_value:    !byte 0

!endoffile
