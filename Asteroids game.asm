;--------------------------------------

;         ASTEROIDS GAME
;       Marko Jovanovski 89251177

;--------------------------------------

;A - move left
;D - move right
;W - shoot laser

JMP main
JMP isr
;-----------------------------------------
;       variables
;-----------------------------------------
vsync: DW 0

keyReady: DW 0 
lastKey: DW 0 

spaceshipPos: DW 0x0E10

laserActive: DW 0 
laserPos: DW 0

rockActive: DW 0
rockPos: DW 0 
rockTimer: DW 0
rockSpawnTimer: DW 0 

rock2Active: DW 0
rock2Pos: DW 0 
rock2Timer: DW 0
rock2SpawnTimer: DW 0

rock3Active: DW 0
rock3Pos: DW 0 
rock3Timer: DW 0 
rock3SpawnTimer: DW 0
;-----------------------------------------
;       isr
;-----------------------------------------
isr:
    PUSH A
    IN 1                            ;checks IRQSTATUS for what interrupt happened
    CMP A, 4                        ;checks if vsync interrupt happened
    JE vsyncInterrupt

    CMP A, 1                        ;checks if kbd interrupt happened
    JE keyboardInterrupt            
    JMP isrExit
keyboardInterrupt:
    IN 5                            ;reads KBDSTATUS
    MOV B, A                        ;save status to check bits
    IN 6                            ;read KBDDATA

    AND B, 1                        ;get last bit 
    CMP B, 1                        ;check if keydown happened
    JNE keyboardDone

    MOV [lastKey], A                ;saves the last key pressed
    MOV [keyReady], 1               
keyboardDone:
    MOV A, 1                        ;kbd interrupt mask
    OUT 2                           ;end of interrupt 
    JMP isrExit
vsyncInterrupt:
    MOV [vsync], 1                  ;next frame ready
    MOV A, 4                        ;vsync interrupt mask
    OUT 2                           ;end of interrupt
    JMP isrExit
waitFrame:
    MOV A, [vsync]
    CMP A, 0                        ;checks if frame happened, 0=no frame
    JE waitFrame                    ;if not go again
    MOV [vsync], 0                  ;reset frame
    RET
isrExit:
    POP A 
    IRET
titleText:
    DB "Asteroids game!"
    DB 0
startText:
    DB "E to start"
    DB 0
gameOverText:
    DB "Game over!"
    DB 0 
printText:
printLoop:
    MOV A, D                        ;activate screen cell
    OUT 8                           ;through VIDADDR
    MOVB AH, [C]                    ;get char
    CMPB AH, 0                      ;if string done, ret
    JE printDone
    MOVB AL, 252                    ;yellow
    OUT 9                           ;display thru VIDDATA
    INC C                           ;next char
    ADD D, 2                       ;next screen cell (1 char=2 bytes)
    JMP printLoop
printDone:
    RET
spaceship:
    DB "\x01\x80\x02\x40\x02\x40\x04\x20\x04\x20\x04\x20\x05\xA0\x09\x90"
    DB "\x11\x88\x20\x04\x40\x02\x84\x21\x89\x91\x79\x9E\x09\x90\x06\x60"
rock:
    DB "\x0F\xE0\x1F\xF0\x3F\xF8\x3F\xFC\x7F\xFE\xFF\xFE\xFF\xFF\xFF\xFF"
    DB "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\x7F\xFE\x3F\xFC\x1F\xF8\x00\x00"
;-----------------------------------------
;           laser
;-----------------------------------------
updateLaser:
    ;check if laser exists, if not no need for update
    MOV A, [laserActive]
    CMP A, 0 
    JE laserDone

    MOV A, [laserPos]
    PUSH A                      ;remove old laser
    OUT 8 
    MOVB AH, ' '
    MOVB AL, 0         
    OUT 9 
    POP A

    SUBB AH, 1                  ;move laser upwards
    CMPB AH, 0                  ;top border check
    JE disableLaser

    MOV [laserPos], A           ;save new position
    ;drawing laser
    OUT 8 
    MOVB AH, '|'
    MOVB AL, 196
    OUT 9 
    RET
disableLaser:
    MOV A, 0
    MOV [laserActive], A 
laserDone:
    RET
;-----------------------------------------
;       middle rock 
;-----------------------------------------
spawnRock:
    ;rock spawn timer after hit is set to 60, once it reaches 0 it spawns
    MOV A, [rockSpawnTimer]
    CMP A, 0 
    JE continueSpawnRock            

    DEC A 
    MOV [rockSpawnTimer], A 
    RET                             ;decrease spawn timer until it can spawn again
continueSpawnRock:
    MOV A, [rockActive]
    CMP A, 1 
    JE rockDone                     ;if rock exists no need to spawn new

    MOV A, 1
    MOV [rockActive], A 

    MOV A, 0x000E                   ;top row middle column starter point
    MOV [rockPos], A 

    OUT 8
    MOVB AH, 254
    MOVB AL, 109
    OUT 9
rockDone:
    RET
updateRock:
    ;check if rock exists, if not no need for update
    MOV A, [rockActive]
    CMP A, 0 
    JE rockReturn

    ;rock timer so it doesn't fall so fast (because of vsync)
    MOV A, [rockTimer]
    INC A 
    MOV [rockTimer], A 
    CMP A, 15                       ;if 15 frames passed, rock falls
    JNE rockReturn                  ;if timer not ready, ret
    MOV A, 0                        
    MOV [rockTimer], A              ;when done, timer resets and goes again


    MOV A, [rockPos]                ;get current rock position

    PUSH A 
    OUT 8 
    MOVB AH, ' '
    MOVB AL, 0 
    OUT 9
    POP A                           ;erasing previous rock

    ADDB AH, 1 
    CMPB AH, 15                     ;bottom border check
    JE resetRock
    MOV [rockPos], A 

    OUT 8 
    MOVB AH, 254
    MOVB AL, 109
    OUT 9                           ;draw new rock
rockReturn:
    RET
resetRock:
    MOV A, 0 
    MOV [rockActive], A 

;-----------------------------------------
;       left rock
;-----------------------------------------


spawn2Rock:
    MOV A, [rock2SpawnTimer]
    CMP A, 0 
    JE continueSpawnRock2

    DEC A 
    MOV [rock2SpawnTimer], A 
    RET
continueSpawnRock2:
    MOV A, [rock2Active]
    CMP A, 1 
    JE rock2Done                     ;if rock exists no need to spawn new

    MOV A, 1
    MOV [rock2Active], A 

    MOV A, 0x0004                   ;top row middle column starter point
    MOV [rock2Pos], A 

    OUT 8
    MOVB AH, 254
    MOVB AL, 109
    OUT 9
rock2Done:
    RET
update2Rock:
    ;check if rock exists, if not no need for update
    MOV A, [rock2Active]
    CMP A, 0 
    JE rock2Return

    ;rock timer so it doesn't fall so fast (because of vsync)
    MOV A, [rock2Timer]
    INC A 
    MOV [rock2Timer], A 
    CMP A, 20                       ;if 20 frames passed, rock falls
    JNE rock2Return                  ;if timer not ready, ret
    MOV A, 0                        
    MOV [rock2Timer], A              ;when done, timer resets and goes again


    MOV A, [rock2Pos]                ;get current rock position

    PUSH A 
    OUT 8 
    MOVB AH, ' '
    MOVB AL, 0 
    OUT 9
    POP A                           ;erasing previous rock

    ADDB AH, 1 
    CMPB AH, 15                     ;bottom border check
    JE reset2Rock
    MOV [rock2Pos], A 

    OUT 8 
    MOVB AH, 254
    MOVB AL, 109
    OUT 9                           ;draw new rock
rock2Return:
    RET
reset2Rock:
    MOV A, 0 
    MOV [rock2Active], A 


;-----------------------------------------
;       right rock 
;-----------------------------------------


spawn3Rock:
    MOV A, [rock3SpawnTimer]
    CMP A, 0 
    JE continueSpawnRock3

    DEC A 
    MOV [rock3SpawnTimer], A 
    RET
continueSpawnRock3:
    MOV A, [rock3Active]
    CMP A, 1 
    JE rock3Done                     ;if rock exists no need to spawn new

    MOV A, 1
    MOV [rock3Active], A 

    MOV A, 0x0018                   
    MOV [rock3Pos], A 

    OUT 8
    MOVB AH, 254
    MOVB AL, 109
    OUT 9
rock3Done:
    RET
update3Rock:
    ;check if rock exists, if not no need for update
    MOV A, [rock3Active]
    CMP A, 0 
    JE rock3Return

    ;rock timer so it doesn't fall so fast (because of vsync)
    MOV A, [rock3Timer]
    INC A 
    MOV [rock3Timer], A 
    CMP A, 12                       ;if 15 frames passed, rock falls
    JNE rock3Return                  ;if timer not ready, ret
    MOV A, 0                        
    MOV [rock3Timer], A              ;when done, timer resets and goes again


    MOV A, [rock3Pos]                ;get current rock position

    PUSH A 
    OUT 8 
    MOVB AH, ' '
    MOVB AL, 0 
    OUT 9
    POP A                           ;erasing previous rock

    ADDB AH, 1 
    CMPB AH, 15                     ;bottom border check
    JE reset3Rock
    MOV [rock3Pos], A 

    OUT 8 
    MOVB AH, 254
    MOVB AL, 109
    OUT 9                           ;draw new rock
rock3Return:
    RET
reset3Rock:
    MOV A, 0 
    MOV [rock3Active], A 

;-----------------------------------------
;       collision laser-rocks
;-----------------------------------------
checkRockLaserCollision:
    MOV A, [laserActive]
    CMP A, 0 
    JE collisionDone

    MOV A, [laserPos]               ;comparing laser with middle rock
    CMP A, [rockPos]
    JE destroyRock

    MOV A, [laserPos]               ;comparing laser with left rock
    CMP A, [rock2Pos]
    JE destroyRock2

    MOV A, [laserPos]
    CMP A, [rock3Pos]
    JE destroyRock3
collisionDone:
    RET

destroyRock:
    MOV A, [rockPos]
    OUT 8 
    MOVB AH, ' '
    MOVB AL, 0
    OUT 9                           ;erase rock

    MOV A, [laserPos]   
    OUT 8 
    MOVB AH, ' '
    MOVB AL, 0
    OUT 9                           ;erase laser

    MOV A, 0
    MOV [rockActive], A 
    MOV [laserActive], A 

    MOV A, 60
    MOV [rockSpawnTimer], A              ;cooldown after hit
    RET

destroyRock2:
    MOV A, [rock2Pos]
    OUT 8 
    MOVB AH, ' '
    MOVB AL, 0
    OUT 9                           ;erase rock

    MOV A, [laserPos]   
    OUT 8 
    MOVB AH, ' '
    MOVB AL, 0
    OUT 9                           ;erase laser

    MOV A, 0
    MOV [rock2Active], A 
    MOV [laserActive], A 

    MOV A, 60
    MOV [rock2SpawnTimer], A              ;cooldown after hit
    RET

destroyRock3:
    MOV A, [rock3Pos]
    OUT 8 
    MOVB AH, ' '
    MOVB AL, 0
    OUT 9                           ;erase rock

    MOV A, [laserPos]   
    OUT 8 
    MOVB AH, ' '
    MOVB AL, 0
    OUT 9                           ;erase laser

    MOV A, 0
    MOV [rock3Active], A 
    MOV [laserActive], A 

    MOV A, 60
    MOV [rock3SpawnTimer], A              ;cooldown after hit
    RET
;-----------------------------------------
;       collision spaceship-rocks
;-----------------------------------------

checkShipCollision:
    MOV A, [spaceshipPos]
    CMP A, [rockPos]
    JE gameOver                            ;if rock position hits spaceship position game ends

    MOV A, [spaceshipPos]
    CMP A, [rock2Pos]
    JE gameOver   

    MOV A, [spaceshipPos]
    CMP A, [rock3Pos]
    JE gameOver   

    RET

;-----------------------------------------
;       main and game start
;-----------------------------------------
main:
    MOV SP, 0x0FFF

    MOV A, 1                        ;text mode
    OUT 7                           ;VIDMODE
    
    MOV C, titleText
    MOV D, 0x0502
    CALL printText

    MOV C, startText
    MOV D, 0x0906
    CALL printText

    MOV A, 5                        ;enable keyboard and vsync interrupts 1(kbd)+4(vsync)=5
    OUT 0                           ;IRQMASK
    STI                             ;enable interrupt
waitGameStart:
    MOV A, [keyReady]
    CMP A, 0 
    JE waitGameStart                ;checks if key pressed, if not loop back

    MOV A, [lastKey]
    CMP A, 'e'                      ;check if key pressed is e
    JE startGame
    CMP A, 'E'
    JE startGame

    MOV [keyReady], 0
    JMP waitGameStart
startGame:
    MOV [keyReady], 0
    MOV A, 3
    OUT 7                           ;clear screen

    MOV A, 1 
    OUT 7                           ;text mode

    MOV C, spaceship
    MOV D, 0x9FE0                   ;vram address for character 255 
    MOV B, 16                       ;16 words to copy (32 bytes)

    loadSpaceshipSprite:
        MOV A, D 
        OUT 8                       ;VIDADDR

        MOV A, [C]
        OUT 9                       ;write sprite data
        ADD C, 2                    ;next sprite word
        ADD D, 2                    ;next vram word

        DEC B 
        CMP B, 0
        JNE loadSpaceshipSprite

        ;draw spaceship
        MOV A, [spaceshipPos]              
        OUT 8 

        MOVB AH, 255               ;ascii char 255
        MOVB AL, 240               ;color
        OUT 9
    
    MOV C, rock
    MOV D, 0x9FC0                   ;vram address for char 254
    MOV B, 16

    loadRockSprite:
        MOV A, D
        OUT 8 

        MOV A, [C]
        OUT 9 
        ADD C, 2
        ADD D, 2

        DEC B
        CMP B, 0
        JNE loadRockSprite
    
    JMP loop
;-----------------------------------------
;       game loop 
;-----------------------------------------
loop:
    CALL waitFrame

    CALL updateLaser

    CALL spawnRock
    CALL updateRock

    CALL spawn2Rock
    CALL update2Rock

    CALL spawn3Rock
    CALL update3Rock

    CALL checkRockLaserCollision
    CALL checkShipCollision

    MOV A, [keyReady]
    CMP A, 1 
    JNE loop                      ;stay in loop if no key pressed
    MOV [keyReady], 0
    MOV A, [lastKey]

    CMP A, 'a'
    JE moveLeft
    CMP A, 'A'
    JE moveLeft                   ;if A is pressed move left

    CMP A, 'd'
    JE moveRight
    CMP A, 'D'
    JE moveRight                 ;if D is pressed move right

    CMP A, 'w'
    JE shootLaser
    CMP A, 'W'
    JE shootLaser               ;if W is pressed shoot laser
    
    JMP loop
    moveLeft:
        MOV A, [spaceshipPos]
        ;clear old spaceship
        PUSH A                  ;preserve reg A
        OUT 8 
        MOVB AH, ' '
        MOVB AL, 0 
        OUT 9 
        POP A 

        CMPB AL, 0              ;left border check
        JE redrawShip
        SUBB AL, 2              ;move left 1 cell
        JMP redrawShip
    moveRight:
        MOV A, [spaceshipPos]
        PUSH A 
        OUT 8 
        MOVB AH, ' '
        MOVB AL, 0 
        OUT 9 
        POP A 
        
        CMPB AL, 30             ;right border check
        JE redrawShip
        ADDB AL, 2              ;move right 1 cell
        JMP redrawShip
    shootLaser:
        MOV A, [laserActive]
        CMP A, 1 
        JE loop                 ;if laser already exists, no need to spawn another

        MOV A, 1 
        MOV [laserActive], A  

        MOV A, [spaceshipPos]
        SUBB AH, 1             ;spawn row above ship
        MOV [laserPos], A      ;save laser to memory
        JMP loop
    redrawShip:
        MOV [spaceshipPos], A 
        OUT 8
        MOVB AH, 255
        MOVB AL, 240
        OUT 9
    
    JMP loop
;-----------------------------------------
;       game over screen 
;-----------------------------------------
gameOver:
    MOV A, 3 
    OUT 7                                   ;clear screen

    MOV A, 1
    OUT 7                                   ;text mode

    MOV C, gameOverText
    MOV D, 0x0708
    CALL printText
