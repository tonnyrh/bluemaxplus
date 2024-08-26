# Bluemax+ for Commodore 64

This project integrates a SNES PETSCII robot interface with the classic Bluemax game on the Commodore 64. It combines the original game code with additional features, such as rudder control, speed adjustment, and more. Note that this project does not include the full game; you'll need the original Bluemax game to build this modified version.

## Features

- **Rudder Control**: Use the SNES controller to control the plane's rudder.
- **Speed Control**: Adjust the plane's speed on the Y axis with the SNES controller.
- **Bomb Control**: Disable bomb drop when pressing down + fire.
- **Gun Sway**: Added gun sway with rudder control.

## SNES Controller

An SNES controller adapter is required to use the SNES controller with the Commodore 64. You can purchase one from [Texelec](https://texelec.com/product/snes-adapter-commodore/). Ensure that you use a high-quality SNES controller, as some cheaper versions may not work correctly.

### SNES Control Overview

| Button           | Function in Bluemax (In-Game)     | Function in Bluemax (Menu/Combo)                 |
|------------------|-----------------------------------|--------------------------------------------------|
| Button 2         | Downspeed                         |                                                  |
| Button 0         | Fire / Unpause                    |                                                  |
| Select           |                                   | Enter options (F3) / Change options (F5) / Pause |
| Start            | Start / Reset (F7)                |                                                  |
| Up               | Up                                |                                                  |
| Down             | Down                              |                                                  |
| Left             | Left                              |                                                  |
| Right            | Right                             |                                                  |
| Button 1         | Bomb                              |                                                  |
| Snes X           | Upspeed                           | Pause (Select + X)                               |
| Left Select      | Rudder Left                       | Enter options (F3) with Select                   |
| Right Select     | Rudder Right                      | Change options (F5) with Select                  |

## Known Issues

1. **Shortened Theme Song**: The theme song is shortened to make space for the additional code, which omits the "MUSIC PROGRAMMED BY STEPHEN C BIGGS" credit.
2. **Gun Sway on Air Targets**: The gun sway feature works well on ground targets but is less effective on air targets.
3. **Bomb Drop in Demo**: The demo may not drop bombs due to the bomb drop + down disable feature.

## Cheat and Feature Enabling

You can enable cheats or features by using a poke to address `30` before running the game:

- `0x01` (1): Disables bomb drop when Down + Fire is pressed.
- `0x02` (2): Enables unlimited bombs.
- `0x04` (4): Enables unlimited fuel.
- `0x08` (8): Enables unlimited damage (invulnerability).
- `0x10` (16): Disables plane lowscreen adjust limit.

### Examples:

- `Poke 30,0`: Only disables bomb drop when Down + Fire is pressed.
- `Poke 30,14`: Enables all cheats + disables bomb drop when Down + Fire.
- `Poke 30,17`: Disables all extra functions.

### Quick Build (windows):
1. Get all files from this respository in a folder (example G:\My Drive\C64\C64projects\BlueMax\bluemax\v10)
2. Install Vice 32 bit
3. Get hold of original Bluemax and name it bluemaxorg.prg and store it in the folder
4. Start Vice
5. Start Vice monitor Alt+H
6. Type:

Cd G:\My Drive\C64\C64projects\BlueMax\bluemax\v10

Load "bluemaxorg.prg" 0

w $D016

X

7. "Run" in vice. This starts monitor again.
8. Type:

bload "Soundmem1" 0 $788a

bload "Soundmem2" 0 $797c

bload "Soundmem3" 0 $7a90

Bload "Intercept Functionkey v2" 0 $5d41

bload "Intercept joystick inflight" 0 5934

bload "Intercept bomb drop" 0 63d7

Bload "intercept xmovement" 0 $5a04

Bload "Intercept in Menu" 0 $7173

Bload "Intercept in Game" 0 $4617

Bload "Intercept exit pause" 0 $438e

Bload "Intercept enter pause v2" 0 $5d94 

Bload "Intercept bullet xmovement" 0 $6540

Bload "Replace Text Startscreen" 0 $7339


Delete
X

9. Enjoy



## Building Instructions (complete)

1. **Set Up C64Studio**: Copy this code into C64Studio.
2. **Configure VICE Emulator**: Set up the VICE 32-bit emulator as a debugger tool in C64Studio.
3. **Prepare Project Folder**: Create a folder to gather all the necessary files.
4. **Copy Original Game**: Copy the original `bluemax.prg` into your project folder as `bluemaxorg.prg`.
5. **Compile & Run**: Compile and run the code.
6. **Exit Test Mode**: You can exit test mode by pressing "ESC".
7. **Enter Monitor**: Press `Alt + H` to enter the monitor.

### Dumping Instructions

1. **Prepare the Folder**:
    ```shell
    mkdir G:\My Drive\C64\C64projects\BlueMax\bluemax\v9.0
    cd G:\My Drive\C64\C64projects\BlueMax\bluemax\v9.0
    ```

2. **Dump the Memory**:
    ```shell
    bsave "Soundmem1" 0 $788a $7927
    bsave "Soundmem2" 0 $797c $7a2d
    bsave "Soundmem3" 0 $7a90 $7b61
    bsave "Intercept joystick inflight" 0 $5934 $5936
    bsave "Intercept bomb drop" 0 $63d7 $63d9
    Bsave "Intercept exit pause" 0 $438e $4390
    Bsave "intercept xmovement" 0 $5a04 $5a06 
    Bsave "Intercept enter pause v2" 0 $5d94 $5d96
    Bsave "Intercept in Menu" 0 $7173 $7175
    Bsave "Intercept in Game" 0 $4617 $4619
    Bsave "Intercept Functionkey v2" 0 $5d41 $5d43
    Bsave "Intercept bullet xmovement" 0 $6540 $6541
    bsave "Replace Text Startscreen" 0 $7339 $73b0
    ```

### Loading Instructions

1. **Load the Original Game**:
    ```shell
    Load "bluemaxorg.prg" 0
    w $D016
    X
    ```

2. **Import the Dumps**:
    ```shell
    bload "Soundmem1" 0 $788a
    bload "Soundmem2" 0 $797c
    bload "Soundmem3" 0 $7a90
    Bload "Intercept Functionkey v2" 0 $5d41
    bload "Intercept joystick inflight" 0 5934
    bload "Intercept bomb drop" 0 63d7
    Bload "intercept xmovement" 0 $5a04
    Bload "Intercept in Menu" 0 $7173
    Bload "Intercept in Game" 0 $4617
    Bload "Intercept exit pause" 0 $438e
    Bload "Intercept enter pause v2" 0 $5d94 
    Bload "Intercept bullet xmovement" 0 $6540
    Bload "Replace Text Startscreen" 0 $7339
    ```

3. **Test the Code**:
    - Write `x` to exit the monitor or `cartfreeze` to enter and save the image.

## Credits

- **Texelec**: For providing the SNES adapter.
- **The 8-Bit Guy**: For inspiration and PETSCII Robots.
- **Robin from 8-Bit Show and Tell**: For inspiration.

### Tribute to the Original Bluemax Creators

This project is a tribute to the original creators of Bluemax:

- **Peter Adams**: Game Developer
- **Synapse Software**: Original Publisher (1983)
- **Bob Polin**: Co-Developer
- **Stephen C Biggs**: Music Programmer

## Final Note

This is my first attempt at 6502 assembly programming, fulfilling a dream I've had for 40 years! Enjoy modding Bluemax with these SNES controls.
