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
BAR_HEIGHT   EQU     20                      ; HEIGHT OF EACH BAR
NUM_BARS     EQU     SCRHEIGH / BAR_HEIGHT   ; TOTAL NUMBER OF BARS
PATTERN_WIDTH   EQU     960    ; Example width, can be adjusted
RECT_WIDTH    EQU     SCRWIDTH*2           ; Width of the rectangle
RECT_HEIGHT   EQU     SCRHEIGH               ; Height of the rectangle (same as the screen height)


            ORG     $1000
            
; -----------------------------------------------------------------------------
; VARIABLES
; -----------------------------------------------------------------------------
XPOS        DS.W    1                       ; VARIABLE TO STORE X POSITION
YPOS        DS.W    1                       ; VARIABLE TO STORE Y POSITION
BG_OFFSET    DS.W    1                       ; BACKGROUND OFFSET FOR SCROLLING


; -----------------------------------------------------------------------------
START
            JSR     INIT                    ; INITIALIZE SCREEN
            MOVE.W  #SCRWIDTH/2,XPOS        ; INITIALIZE X POSITION (CENTER)
            MOVE.W  #SCRHEIGH/2,YPOS        ; INITIALIZE Y POSITION (CENTER)
            MOVE.B  #17,D1  ; Set drawing mode to double buffering
            MOVE.B  #92,D0
            TRAP    #15
            
            MOVE.W  #0,BG_OFFSET                        ; INITIALIZE BACKGROUND OFFSET

            ; Set Drawing Mode to Normal
            MOVE.B  #4,D1
            MOVE.B  #92,D0  ; Set drawing mode task
            TRAP    #15
            
         
            
MAIN_LOOP
            ; Clear the off-screen buffer first
            MOVE.B  #11,D0
            MOVE.W  #$FF00,D1
            TRAP    #15

            ; Call subroutine to paint background
            JSR     PAINT_BACKGROUND

            ; Check for key presses and update position if necessary
            JSR     CHECK_KEYS

            ; Get the updated position from variables
            MOVE.W  XPOS,D1                 ; GET CURRENT X POSITION
            MOVE.W  YPOS,D2                 ; GET CURRENT Y POSITION
            MOVE.L  #$00FF00FF,D0
            MOVE.W  #SQRSIDE,D3             ; SQUARE SIDE
            JSR     DRSQUARE                ; DRAW SQUARE

            ; Copy the off-screen buffer to the on-screen buffer
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


CHECK_KEYS
            MOVEM.L D1-D7/A0-A1,-(A7)       ; Save registers on the stack

            MOVE.B  #19,D0                  ; TASK NUMBER FOR CHECKING KEYS
            MOVE.L  #'W'<<24+'A'<<16+'S'<<8+'D',D1 ; CHECK FOR 'W', 'A', 'S', 'D'
            TRAP    #15                     ; Call the keyboard check task
            
            MOVE.W  XPOS,D3                 ; Load current X position
            MOVE.W  YPOS,D4                 ; Load current Y position

            ; Check if 'A' is pressed for left movement
            BTST    #16,D1
            BEQ     NO_A
            CMP.W   #MID_X,D3
            BLS     MOVE_LEFT               ; If square is not at midpoint, move left
            JSR     SCROLL_BACKGROUND_LEFT  ; Otherwise, adjust background to the right
            BRA     NO_A

MOVE_LEFT:
            SUB.W   #DELTA,D3               ; Move left
            CMP.W   #SQRSIDE/2,D3
            BGE     NO_A
            MOVE.W  #SQRSIDE/2,D3           ; Correct position at left edge

NO_A:        
            ; Check if 'D' is pressed for right movement
            BTST    #0,D1
            BEQ     NO_D
            CMP.W   #MID_X,D3
            BLS     MOVE_RIGHT              ; If square is not at midpoint, move right
            JSR     SCROLL_BACKGROUND_RIGHT ; Otherwise, adjust background to the left
            BRA     NO_D

MOVE_RIGHT:
            ADD.W   #DELTA,D3               ; Move right
            CMP.W   #SCRWIDTH-SQRSIDE/2,D3
            BLE     NO_D
            MOVE.W  #SCRWIDTH-SQRSIDE/2,D3  ; Correct position at right edge

NO_D:        
            MOVE.W  D3,XPOS                 ; Store updated X position
            MOVE.W  D4,YPOS                 ; Store updated Y position

            MOVEM.L (A7)+,D1-D7/A0-A1       ; Restore registers from the stack
            RTS                             ; Return from subroutine


PAINT_BACKGROUND
            MOVEM.L D1-D6,-(A7)               ; STORE REGISTERS

        

            MOVE.L  #RED_COLOR,D1             ; Set fill color to red
            MOVE.B  #81,D0                    ; Set fill color task
            TRAP    #15

            MOVE.L  #ORANGE_COLOR,D0                 ; Set pen color to white
            MOVE.B  #80,D0                    ; Set pen color task
            TRAP    #15
            
            MOVE.W  BG_OFFSET,D1              ; Load background offset
            MOVE.W  #0,D2                     ; Upper Y is always 0
            MOVE.W  D1,D3                     ; Lower X is BG_OFFSET + RECT_WIDTH
            ADD.W   #RECT_WIDTH,D3
            MOVE.W  #RECT_HEIGHT,D4           ; Lower Y is the height of the rectangle

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


            END     START    ꉊāG剆預ˑʨ¹                                                                                                                                                                                                                    
