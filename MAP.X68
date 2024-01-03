; =============================================================================
; MAP MANAGEMENT
; =============================================================================

; -----------------------------------------------------------------------------
MAPINIT
; INITIALIZES THE MAP
; INPUT    - NONE
; OUTPUT   - NONE
; MODIFIES - NONE
; -----------------------------------------------------------------------------

            MOVEM.L     D0/A0,-(A7)
            
            MOVE.W      #MAPINIX,(MAPPOSX)      ; INITIALIZES SCREEN X
            MOVE.W      #MAPINIY,(MAPPOSY)      ; INITIALIZES SCREEN Y
            LEA         MAPCMPL,A0              ; COMPLETED SCREEN FLAGS
            MOVE.W      #MAPWIDTH*MAPHEIGH-1,D0 ; LOOP COUNTER
.LOOP       CLR.W       (A0)+                   ; INITIALY SCREEN NOT COMPLETED
            DBRA.W      D0,.LOOP
            MOVE.W      MAPSCRVS,D0             ; FIRST ROOM VISITED
            JSR         MAPCOMPL                ; ZERO: SET ROOM AS COMPLETED
            JSR         MAPGTSCA                ; GET SCREEN ADDRESS
;            JSR         MAPENMDL                ; DELETE ALL ENEMIES
;            JSR         MAPENMCR                ; CREATE CURRENT ENEMIES
            
            MOVEM.L     (A7)+,D0/A0
            RTS
            

; -----------------------------------------------------------------------------
MAPUPD
; UPDATES THE MAP IF PLAYER CHANGES SCREEN
; INPUT    - NONE
; OUTPUT   - NONE
; MODIFIES - NONE
; -----------------------------------------------------------------------------

            MOVE.L      D5,-(A7)
            
;            TST.W       (MAPNUMEN)              ; CHECK NUMBER OF ENEMIES
;            BNE         .CONT                   ; IF NOT ZERO JUMP
;            MOVE.W      #MAPSCRCM,D0  
;            JSR         MAPCOMPL                ; IF ZERO SET ROOM AS COMPLETED
            
.CONT       CMP.W       #MAPTILEW*MAPSCRW-AGNWIDTH-AGNBBXO,(PLRPOSX)
            BGE         .CHGR                       ; IF AT SCREEN RIGHT, CHANGE
            CMP.W       #AGNBBXO,(PLRPOSX)
            BLE         .CHGL                       ; IF AT SCREEN LEFT, CHANGE
            CMP.W       #MAPTILEH*MAPSCRH-AGNHEIGH-AGNBBYO,(PLRPOSY)
            BGE         .CHGD                       ; IF AT SCREEN BOTTOM, CHANGE
            CMP.W       #AGNBBYO,(PLRPOSY)
            BGE         .END                        ; IF NOT AT TOP, END
.CHGU       MOVE.L      #$FFFF0000,D5               ; REQUEST UPWARD SCREEN
            MOVE.L      #MAPTILEH*MAPSCRH-AGNHEIGH-AGNBBYO*2<<16,(PLRPOSY)
            BRA         .DOCHG                      ; AND SET PLAYER Y TO BOTTOM
.CHGR       MOVE.L      #$00000001,D5               ; REQUEST RIGHTWARD SCREEN
            MOVE.W      #AGNBBXO*2,(PLRPOSX)        ; AND SET PLAYER X TO LEFT
            BRA         .DOCHG
.CHGL       MOVE.L      #$0000FFFF,D5               ; REQUEST LEFTWARD SCREEN
            MOVE.W      #MAPTILEW*MAPSCRW-AGNWIDTH-AGNBBXO*2,(PLRPOSX)
            BRA         .DOCHG                      ; AND SET PLAYER X TO RIGHT
.CHGD       MOVE.L      #$00010000,D5               ; REQUEST DOWNWARD SCREEN
            MOVE.L      #AGNBBYO*2<<16,(PLRPOSY)    ; AND SET PLAYER Y TO TOP
.DOCHG      JSR         MAPMOVE                     ; DO SCREEN CHANGE REQUEST
            JSR         MAPENMDL                    ; DELETE EXISTING ENEMIES
            JSR         MAPENMCR                    ; CREATE NEW ENEMIES
            
.END        MOVE.L      (A7)+,D5
            RTS
            

; -----------------------------------------------------------------------------
MAPPLOT
; PLOTS THE MAP
; INPUT    - NONE
; OUTPUT   - NONE
; MODIFIES - NONE
; -----------------------------------------------------------------------------


            MOVEA.L     (MAPSCPTR),A2               ; GET SCREEN ADDRESS
            LEA         GFXLST,A0                   ; GET GRAPHICS
            MOVE.W      #MAPSCRH-1,D0               ; ITERATOR (ROW)
            CLR.W       D6                          ; INITIAL Y
.LOOPY      CLR.W       D5                          ; INITIAL X
            MOVE.W      #MAPSCRW-1,D1               ; ITERATOR (COLUMN)
.LOOPX      MOVE.W      (A2)+,D7                    ; GET CELL
            IFEQ        CASSCRBG                    ; SKIP IF NO BACKGROUND WAMTED
            BEQ         .SKIP                       ; IF 00 SKIP
            ENDC
;            CMP.W       #MAPDOOR,D7
;            BEQ         .DOOR                       ; IF IS A DOOR 
;            CMP.W       #MAPANIM0,D7
;            BEQ         .ANIM                       ; IF IS AN ANIMATED
;            CMP.W       #MAPANIM1,D7
;            BNE         .PLOT                       ; PLOT IF IT ISN´T ANIMATED
            BRA         .PLOT
.ANIM       MOVE.B      (GENFRMCT),D3               ; GET CYCLE COUNTER 
            ROR.W       #3,D3                       ; DIV BY 8 TO CHANGE EVERY 8 FRAMES
            AND.W       #3,D3                       ; ANIM PIC HAS 4 FRAMES CONTROLLED
            OR.W        D3,D7                       ; ...BY ITS TWO LSB 
.PLOT       JSR         GFXDRIDP                    ; DRAW
.SKIP       ADD.W       #MAPTILEW,D5                ; ADD 32 TO X
            DBRA.W      D1,.LOOPX                   ; LOOP FOR ALL COLUMNS
            ADD.W       #MAPTILEH,D6                ; ADD 32 TO Y
            ADD.L       #MAPSCRW*(MAPWIDTH*2-2),A2
            DBRA.W      D0,.LOOPY                   ; LOOP FOR ALL ROWS

            MOVEM.L     (A7)+,D0-D7/A2
            RTS

.DOOR       ;TST.W       (MAPNUMEN)                  ; ARE THERE ENEMIES?
            BNE         .PLOT                       ; IF SO, PLOT DOOR 
            CLR.W       D7
            IFEQ        CASSCRBG                    ; SKIP IF NO BACKGROUND WANTER
            BRA         .SKIP                       ; OTHERWISE, BACKGROUND CELL
            ENDC
            IFNE        CASSCRBG                    ; PLOT IF BACKGROUND WANTED
            BRA         .PLOT
            ENDC   

             
 
MAPDOCOMP
; STORES THE CURRENT SCREEN AS COMPLETED/VISITED
; INPUT    - D0.W   VALUE TO OR WITH EXISTING VALUE
; OUTPUT   - NONE
; MODIFIES - NONE
; -----------------------------------------------------------------------------

            MOVEM.L     A0,-(A7)
            
            JSR         MAPGTFLA                    ; GET THE ADDRESS
            OR.W        D0,(A0)                     ; MARK AS COMPLETED/VISITED
            
            MOVEM.L     (A7)+,A0
            RTS   


; -----------------------------------------------------------------------------
MAPGTFLA
; GETS THE ADDRESS OF THE CURRENT SCREEN IN THE COMPLETED SCREENS LIST
; INPUT    - NONE
; OUTPUT   - A0 ADDRESS
; MODIFIES - NONE
; -----------------------------------------------------------------------------


            MOVEM.L     D0-D1,-(A7)
            
            MOVE.W      (MAPPOSY),D0                ; GET SCREEN Y
            MULU        #MAPWIDTH*2,D0              ; * SCREENS PER ROW * 2 (WORDS)
            MOVE.W      (MAPPOSX),D1                ; GET SCREEN X
            ASL.W       #1,D1                       ; * 2 (WORDS)
            ADD.W       D1,D0                       ; ADD BOTH OFFSETS
            LEA         MAPCMPLT,A0                 ; GET DATA ADDRESS
            LEA         (A0,D0.W),A0                ; GET THE OFFSETTED ADDRESS
            
            MOVEM.L     (A7)+,D0-D1
            RTS


; -----------------------------------------------------------------------------
MAPMOVE
; CHANGE SCREEN
; INPUT    - D5.L   16 HIGH BITS AMOUNT TO MOVE VERT, 16 BITS LOW HOR
; OUTPUT   - NONE
; MODIFIES - NONE
; -----------------------------------------------------------------------------

            MOVE.W      D0,-(A7)
            
            ADD.W       D5,(MAPPOSX)                ; MOVE HORIZONTALLY
            SWAP.W      D5
            ADD.W       D5,(MAPPOSY)                ; MOVE VERTICALLY
            SWAP.W      D5                          ; RESTORE D5
            CMP.W       #MAPWIDTH,(MAPPOSX)         ; X OUT OF MAP?
            BGE         .WIN                        ; YES: WIN
            JSR         MAPGTSCA                    ; GET SCREEN ADDRESS
            MOVE.W      #MAPSCRVS,D0
            JSR         MAPDOCOMP
            
.END        MOVE.W      (A7)+,D0
            RTS
            
.WIN        MOVE.W      #STAVICT,(STANEXT)          ; GO TO VICTORY STATE!
            BRA         .END

                     
; -----------------------------------------------------------------------------
MAPGTSCA
; GETS THE INITIAL ADDRESS OF THE CURRENT SCREEN
; INPUT    - NONE
; OUTPUT   - NONE. UPDATES (MAPSCPTR)
; MODIFIES - NONE
; -----------------------------------------------------------------------------

            MOVEM.L     D0/A2,-(A7)
            
            LEA         MAPDATA,A2                  ; GET BASE MAP ADDRESS
            MOVE.W      (MAPPOSY),D0                ; GET SCREEN Y
            MULU        #MAPSCRH*MAPSCRW*MAPWIDTH*2,D0 ; COMPUTE Y OFFSET
            ADD.L       D0,A2                       ; ADD Y OFFSET
            MOVE.W      (MAPPOSX),D0                ; GET SCREEN Y
            MULU        #MAPSCRW*2,D0               ; COMPUTE X OFFSET
            ADD.L       D0,A2                       ; ADD IT
            MOVE.L      A2,(MAPSCPTR)               ; STORE IT
            
            MOVEM.L     (A7)+,D0/A2
            RTS
            
            
; -----------------------------------------------------------------------------
MAPGTTIL
; GETS THE TILE IN THE SPECIFIED (PIXELWISE) COORDINATES
; INPUT    - D5.W X COORDINATE
;            D6.W Y COORDINATE
; OUTPUT   - D7.W TILE ID
; MODIFIES - NONE
; -----------------------------------------------------------------------------
            
            MOVEM.L     D5-D6/A0,-(A7)
            
            ASR.W       #5,D6                       ; Y/=MAPTILEH. VALID IF MAPTILEH=32
            ASR.W       #4,D5                       ; X=2*(X/MAPTILEW) IF MAPTILEW=32
            AND.L       #$0000FFFE,D5               ; CLEAR LSB
            MULU        #MAPSCRW*MAPWIDTH*2,D6      ; COMPUTE Y OFFSET
            ADD.L       D5,D6                       ; ADD X OFFSET
            MOVE.L      (MAPSCPTR), A0              ; GET BASE SCREEN ADDR
            ADD.L       D6,A0                       ; GET ADDRESS
            MOVE.W      (A0),D7                     ; OUTPUT TO D7
            
            MOVEM.L     (A7)+,D5-D6/A0
            RTS            
            
; -----------------------------------------------------------------------------
MAPGTCOD
; GETS THE CODE OF THE SPECIFIED (PIXELWISE) COORDINATES.
; INPUT    - D5.W X COORDINATE
;            D6.W Y COORDINATE
; OUTPUT   - D7.B CODE:
;            %00 FREE (MAPFREE)
;            %01 DAMAGING BLOCK (MAPDMG)
;            %10 OBSTACLE (MAPOBS)
;            %11 LADDER (MAPLAD)
; MODIFIES - NONE
; -----------------------------------------------------------------------------

            CMP.W       #MAPTILEW*MAPSCRW,D5
            BGE         .OBST                       ; RIGHT SIDE IS OBSTACLE
            BTST        #15,D5
            BNE         .OBST                       ; LEFT SIDE IS OBSTACLE
            CMP.W       #MAPTILEH*MAPSCRH,D6
            BGE         .OBST                       ; BOTTOM IS OBSTACLE
            BTST        #15,D6
            BNE         .OBST                       ; TOP IS OBSTACLE
            JSR         MAPGTTIL
            TST.W       D7
            BEQ         .FREE                       ; ID=0 -> CODE 00
            CMP.B       #2,D7
            BLE         .OBST                       ; ID=1 OR 2 -> CODE 10
            CMP.B       #3,D7
            BEQ         .DOOR                       ; ID=3 -> DOOR
.DMG        MOVE.B      #MAPDMG,D7                  ; ID>=4 -> DAMAGING
            RTS
.DOOR       TST.W       (MAPNUMEN)
            BNE         .OBST                       ; IF STILL ENEMIES, CLOSED DOOR
.FREE       MOVE.B      #MAPFREE,D7
.END        RTS
.OBST       MOVE.B  #MAPOBS,D7
            RTS            
            
; -----------------------------------------------------------------------------
MAPENMCR
; CREATES ENEMIES FOR THE CURRENT SCREEN
; INPUT    - NONE
; OUTPUT   - NONE
; MODIFIES - NONE
; -----------------------------------------------------------------------------
            
            MOVEM.L     D0-D5/A0-A1,-(A7)
            
            CLR.W       D5                          ; ENEMY COUNTER
            JSR         MAPGTFLA
            MOVE.W      (A0),D0                     ; GET FLAG
            AND.W       #MAPSCRCM,D0                ; CHECK IF SCREEN ALREADY COMPLETED
            BNE         .END                        ; YES: DO NOT PUT ENEMIES AGAIN
            MOVE.W      (MAPPOSX),D4                ; FORMAT CURRENT SCREEN DATA
            SWAP        D4
            MOVE.W      (MAPPOSY),D4
            LEA         ENMDATA,A0                  ; GET ENEMY LIST
.LOOP       MOVE.L      (A0),D1                     ; GET DATA
            CMP.L       #$FFFFFFFF,D1               ; TERMINATOR REACHED?
            BEQ         .END                        ; IF SO, EXIT
            CMP.L       D1,D4                       ; ENEMY IN CURRENT SCREEN
            BNE         .NEXT
            ADDQ.W      #1,D5                       ; COUNT ENEMIES
            MOVE.L      4(A0),D1
            MOVE.W      8(A0),D2
            MOVE.L      10(A0),D3
            LEA         ENMINIT,A1
            LEA         ENMUPD,A2
            LEA         ENMPLOT,A3
            MOVE.W      #ENMTYPE,D0
            JSR         AGLADD
.NEXT       ADD.L       #14,A0                      ; GO TO NEXT ENEMY
            BRA         .LOOP
.END        MOVE.W      D5,(MAPNUMEN)               ; STORE THE NUMBER OF ENEMIES

            MOVEM.L     (A7)+,D0-D5/A0-A1
            RTS

; =============================================================================
; DE AQUÍ PARA ABAJO SON OPCIONALES A UTILIZAR SI FUERA NECESARIO
; =============================================================================

; -----------------------------------------------------------------------------
MAPENMDL
; DELETES ALL ENEMIES AND EXPLOSIONS
; INPUT    - NONE
; OUTPUT   - NONE
; MODIFIES - NONE
; -----------------------------------------------------------------------------

            MOVEM.L     D0/A0,-(A7)
            
            MOVE.W      #EXPTYPE,D0
            JSR         .DOKILL
            MOVE.W      #ENMTYPE,D0
            JSR         .DOKILL
            CLR.W       (MAPNUMEN)
            
            MOVEM.L     (A7)+,D0/A0
            RTS
            
.DOKILL     JSR         DMMFRSTO
.LOOP       CMP.L       #0,A0
            BEQ         .END
            JSR         DMMFREE
            JSR         DMMNEXTO
            BRA         .LOOP
.END        RTS
            
            
           
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
