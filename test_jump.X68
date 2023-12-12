; -----------------------------------------------------------------------------
; CONSTANTS
; -----------------------------------------------------------------------------
SCRWIDTH    EQU     640                     ; DESIRED SCREEN WIDTH
SCRHEIGH    EQU     480                     ; DESIRED SCREEN HEIGHT
MID_X             EQU     SCRWIDTH/2              ; MIDPOINT X COORDINATE
MID_Y             EQU     SCRHEIGH/2              ; MIDPOINT Y COORDINATE
SQRSIDE        EQU     64                      ; SIDE OF THE SQUARE TO DRAW
SQRBCHAN    EQU     128                     ; SQUARE BLUE CHANNEL VALUE
DELTA             EQU     1                       ; AMOUNT TO MOVE THE SQUARE BY EACH FRAME
RED_COLOR   EQU     $000000FF               ; RED COLOR
ORANGE_COLOR EQU     $00FFA500               ; ORANGE COLOR
YELLOW_COLOR EQU     $00FFFF00               ; YELLOW COLOR
GREEN_COLOR  EQU     $00008000               ; GREEN COLOR
BLUE_COLOR  EQU     $00FF0000
BAR_HEIGHT   EQU     20                      ; HEIGHT OF EACH BAR
NUM_BARS     EQU     SCRHEIGH / BAR_HEIGHT   ; TOTAL NUMBER OF BARS
PATTERN_WIDTH   EQU     960    ; Example width, can be adjusted
RECT_WIDTH    EQU     SCRWIDTH*2           ; Width of the rectangle
RECT_HEIGHT   EQU     SCRHEIGH               ; Height of the rectangle (same as the screen height)
SCROLL_OFFSET  EQU     200    ; Example offset value, adjust as needed
FRAME_DELAY    EQU     5                       ; MOVE SQUARE EVERY 'FRAME_DELAY' FRAMES
GROUND_HEIGHT  EQU     450                      ; HEIGHT OF THE GROUND
GROUND_COLOR   EQU     $008B4513               ; BROWN COLOR FOR GROUND
INITIAL_JUMP_VELOCITY  EQU     -15             ; INITIAL VELOCITY FOR JUMP (NEGATIVE FOR UPWARDS)
GRAVITY                EQU     1               ; GRAVITY TO APPLY EACH FRAME
GROUND_Y               EQU     SCRHEIGH - GROUND_HEIGHT ; Y POSITION OF THE GROUND


            ORG     $1000
            
; -----------------------------------------------------------------------------
; VARIABLES
; -----------------------------------------------------------------------------
XPOS        DS.W    1                       ; VARIABLE TO STORE X POSITION
YPOS        DS.W    1                       ; VARIABLE TO STORE Y POSITION
BG_OFFSET    DS.W    1                       ; BACKGROUND OFFSET FOR SCROLLING
FRAME_COUNTER DS.W  1                       ; VARIABLE TO COUNT FRAMES
VERT_VELOCITY    DS.W    1                       ; VERTICAL VELOCITY FOR JUMPING
IS_JUMPING       DS.W    1                       ; JUMP STATE FLAG
GRAVITY_COUNTER   DS.W    1 


; -----------------------------------------------------------------------------
START
            JSR     INIT                    ; INITIALIZE SCREEN
            MOVE.W  #MID_X,XPOS               ; INITIALIZE X POSITION (CENTER)
            MOVE.W  #GROUND_Y-SQRSIDE,YPOS    ; INITIALIZE Y POSITION (ON TOP OF THE GROUND)
            MOVE.B  #17,D1  ; Set drawing mode to double buffering
            MOVE.B  #92,D0
            TRAP    #15
            
            MOVE.W  #0,FRAME_COUNTER        ; INITIALIZE FRAME COUNTER            
            MOVE.W  #0,BG_OFFSET                        ; INITIALIZE BACKGROUND OFFSET
            MOVE.W  #0,GRAVITY_COUNTER

            ; Set Drawing Mode to Normal
            MOVE.B  #4,D1
            MOVE.B  #92,D0  ; Set drawing mode task
            TRAP    #15
            
         
            
MAIN_LOOP
            ; Clear the off-screen buffer first
            MOVE.B  #11,D0
            MOVE.W  #$FF00,D1
            TRAP    #15

           
            ; Check for key presses and update position if necessary
            JSR     CHECK_KEYS
            JSR     UPDATE_JUMP
            ; Call subroutine to paint background
            JSR     PAINT_BACKGROUND
            
            ; Get the updated position from variables
            MOVE.W  XPOS,D1                 ; GET CURRENT X POSITION
            MOVE.W  YPOS,D2                 ; GET CURRENT Y POSITION
            MOVE.L  #$00FF00FF,D0
            MOVE.W  #SQRSIDE,D3             ; SQUARE SIDE
            
            JSR     DRSQUARE                ; DRAW SQUARE
           
            
            MOVE.B  #94,D0                  ; REPAINT SCREEN TASK
            TRAP    #15                     ; COPY BUFFER TO SCREEN

            BRA     MAIN_LOOP               ; REPEAT LOOP


; -----------------------------------------------------------------------------
INIT
; Initializes the output window to 640x480 windowed mode. The routine INIT
; in the exercises could have also been used.
; -----------------------------------------------------------------------------
            MOVE.L  #SCRWIDTH<<16|SCRHEIGH,D1
            MOVE.B  #33,D0
            TRAP    #15                     ; SET RESOLUTION
            MOVE.L  #1,D1
            TRAP    #15                     ; SET WINDOWED MODE
            RTS

; -----------------------------------------------------------------------------
DRSQUARE
; Draws a square with side D3.W and centered at D1.W, D2.W. The fill color is
; R=0, G=0 and B=D0.B and the border color is white.
; Input    - D0.B - Fill color blue channel value.
;            D1.W - Square center X coordinate.
;            D2.W - Square center Y coordinate.
;            D3.W - Square side.
; Output   - None
; Modifies - Nothing
; -----------------------------------------------------------------------------
            MOVEM.L D1-D6,-(A7)             ; STORE REGISTERS
            MOVE.W  D1,D6                   ; STORE D1
            MOVE.B  D0,D1
            SWAP.W  D1                      ; PUT THE BLUE CHANNEL
            AND.L   #$00FF0000,D1           ; MASK IT
            MOVE.B  #81,D0
            TRAP    #15                     ; DEFINE FILL COLOR
            MOVE.L  #$00FFFFFF,D1           ; WHITE COLOR
            MOVE.B  #80,D0
            TRAP    #15                     ; DEFINE CONTOUR COLOR
            MOVE.W  D6,D1                   ; RESTORE D1
            MOVE.W  D3,D5                   ; COPY THE VALUE TO D5
            LSR.W   #1,D5                   ; COMPUTE HALF THE SIDE
            MOVE.W  D1,D3                   ; PREPARE XRIGHT
            MOVE.W  D2,D4                   ; PREPARE YRIGHT
            ADD.W   D5,D3                   ; COMPUTE XRIGHT
            ADD.W   D5,D4                   ; COMPUTE YRIGHT
            NEG.W   D5                      ; CONVERT TO NEGATIVE
            ADD.W   D5,D1                   ; COMPUTE XLEFT
            ADD.W   D5,D2                   ; COMPUTE YLEFT
            MOVE.B  #87,D0                  ; DRAW RECTANGLE TASK NUMBER
            TRAP    #15                     ; DRAW IT
            MOVEM.L (A7)+,D1-D6             ; RESTORE REGISTERS
            RTS


; -----------------------------------------------------------------------------
; CHECK_KEYS Subroutine
; Checks for key presses and updates position and jump status
; -----------------------------------------------------------------------------
CHECK_KEYS
    MOVEM.L D1-D7/A0-A1,-(A7)   ; Save registers on the stack

    MOVE.B  #19,D0              ; TASK NUMBER FOR CHECKING KEYS
    MOVE.L  #'W'<<24+'A'<<16+'S'<<8+'D',D1 ; CHECK FOR 'W', 'A', 'S', 'D'
    TRAP    #15                 ; Call the keyboard check task

    MOVE.W  XPOS,D3             ; Load current X position
    MOVE.W  YPOS,D4             ; Load current Y position
    MOVE.W  FRAME_COUNTER,D5    ; Load frame counter
    ADD.W   #1,D5               ; Increment frame counter
    CMP.W   #FRAME_DELAY,D5     ; Check if it's time to move
    BLO     SKIP_MOVEMENT       ; Skip movement if not enough frames have passed
    MOVE.W  #0,D5               ; Reset frame counter

    ; Check for jump key ('W') press and initiate jump if not already jumping
    MOVE.W  IS_JUMPING,D0       ; Check if already jumping
    BNE     NO_JUMP             ; Skip jump initiation if already jumping
    BTST    #24,D1              ; Check if 'W' is pressed
    BNE     JUMP_START
NO_JUMP:
    ; Check if 'A' is pressed for left movement
    BTST    #16,D1
    BEQ     NO_A
    CMP.W   #SCROLL_OFFSET,D3   ; Check if within scroll offset
    BHI     MOVE_LEFT           ; If outside scroll offset, move left
    JSR     SCROLL_BACKGROUND_LEFT  ; Otherwise, adjust background to the right
    BRA     NO_A

MOVE_LEFT:
    SUB.W   #DELTA,D3           ; Move left
    CMP.W   #SQRSIDE/2,D3
    BGE     NO_A
    MOVE.W  #SQRSIDE/2,D3       ; Correct position at left edge
NO_A:
    ; Check if 'D' is pressed for right movement
    BTST    #0,D1
    BEQ     NO_D
    CMP.W   #(SCRWIDTH - SCROLL_OFFSET),D3 ; Check if within scroll offset
    BLT     MOVE_RIGHT          ; If outside scroll offset, move right
    JSR     SCROLL_BACKGROUND_RIGHT ; Otherwise, adjust background to the left
    BRA     NO_D

MOVE_RIGHT:
    ADD.W   #DELTA,D3           ; Move right
    CMP.W   #SCRWIDTH-SQRSIDE/2,D3
    BLE     NO_D
    MOVE.W  #SCRWIDTH-SQRSIDE/2,D3  ; Correct position at right edge
NO_D:
    MOVE.W  D3,XPOS             ; Store updated X position
    MOVE.W  D4,YPOS             ; Store updated Y position

SKIP_MOVEMENT:
    MOVE.W  D5,FRAME_COUNTER    ; Store updated frame counter

JUMP_START:
    MOVE.W  #INITIAL_JUMP_VELOCITY,VERT_VELOCITY ; Set initial jump velocity
    MOVE.W  #1,IS_JUMPING                           ; Set jumping flag

    MOVEM.L (A7)+,D1-D7/A0-A1   ; Restore registers from the stack
    RTS                         ; Return from subroutine



; -----------------------------------------------------------------------------
; UPDATE_JUMP Subroutine
; Handles the jump mechanics and applies gravity
; -----------------------------------------------------------------------------
UPDATE_JUMP:
    MOVEM.L D1-D7/A0-A1,-(A7)    ; Save registers on the stack

    MOVE.W  IS_JUMPING,D0        ; Load jumping state
    BEQ     NO_JUMP_UPDATE       ; If not jumping, skip to the end

    MOVE.W  YPOS,D1              ; Load current Y position
    MOVE.W  VERT_VELOCITY,D2     ; Load current vertical velocity

    ADD.W   D2,D1                ; Update Y position with current velocity
    ADD.W   #GRAVITY,D2          ; Apply gravity to vertical velocity

    MOVE.W  D1,YPOS              ; Update Y position
    MOVE.W  D2,VERT_VELOCITY     ; Update vertical velocity

    ; Check for landing
    CMP.W   #GROUND_Y-SQRSIDE,D1 ; Compare current Y with ground position
    BLS     LANDING              ; If below ground level, adjust to ground level

    BRA     UPDATE_COMPLETE      ; Skip landing adjustment if not landed

LANDING:
    MOVE.W  #0,VERT_VELOCITY     ; Reset vertical velocity
    MOVE.W  #GROUND_Y-SQRSIDE,D1 ; Adjust Y position to ground level
    MOVE.W  D1,YPOS              ; Update Y position
    MOVE.W  #0,IS_JUMPING        ; Update jumping state to not jumping

UPDATE_COMPLETE:
    MOVEM.L (A7)+,D1-D7/A0-A1    ; Restore registers from the stack
    RTS                          ; Return from subroutine

NO_JUMP_UPDATE:
    MOVEM.L (A7)+,D1-D7/A0-A1    ; Restore registers if jump update is skipped
    RTS                          ; Return from subroutine











PAINT_BACKGROUND
            MOVEM.L D1-D6,-(A7)               ; STORE REGISTERS

            MOVE.L  #RED_COLOR,D1             ; Set fill color to red
            MOVE.B  #81,D0                    ; Set fill color task
            TRAP    #15

            ; Draw the background rectangle
            MOVE.W  BG_OFFSET,D1              ; Load background offset
            MOVE.W  #0,D2                     ; Upper Y is always 0
            MOVE.W  D1,D3                     ; Lower X is BG_OFFSET + RECT_WIDTH
            ADD.W   #RECT_WIDTH,D3
            MOVE.W  #RECT_HEIGHT,D4           ; Lower Y is the height of the rectangle
            MOVE.B  #87,D0                    ; Draw filled rectangle task
            TRAP    #15

            ; Draw the ground rectangle
            MOVE.L  #GROUND_COLOR,D1          ; Set fill color to brown for ground
            MOVE.B  #81,D0                    ; Set fill color task
            TRAP    #15
            MOVE.W  #0,D1                     ; Left X is 0
            MOVE.W  #GROUND_HEIGHT,D2    ; Upper Y is screen height minus ground height
            MOVE.W  #SCRWIDTH,D3              ; Right X is screen width
            MOVE.W  #SCRHEIGH,D4              ; Lower Y is screen height
            MOVE.B  #87,D0                    ; Draw filled rectangle task
            TRAP    #15

            MOVEM.L (A7)+,D1-D6               ; RESTORE REGISTERS
            RTS




            
SCROLL_BACKGROUND_RIGHT:
    MOVEM.L D1-D7/A0-A1,-(A7)                  ; Save registers on the stack

    MOVE.W  BG_OFFSET,D1                       ; Load current background offset
    SUB.W   #DELTA,D1                          ; Shift background to the left
    MOVE.W  D1,BG_OFFSET                       ; Store updated background offset

    MOVEM.L (A7)+,D1-D7/A0-A1                  ; Restore registers from the stack
    RTS                                        ; Return from subroutine


SCROLL_BACKGROUND_LEFT:
    MOVEM.L D1-D7/A0-A1,-(A7)                  ; Save registers on the stack

    MOVE.W  BG_OFFSET,D1                       ; Load current background offset
    ADD.W   #DELTA,D1                          ; Shift background to the right
    MOVE.W  D1,BG_OFFSET                       ; Store updated background offset

    MOVEM.L (A7)+,D1-D7/A0-A1                  ; Restore registers from the stack
    RTS                                        ; Return from subroutine


            END     START
