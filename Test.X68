; -----------------------------------------------------------------------------
; CONSTANTS
; -----------------------------------------------------------------------------
SCRWIDTH    EQU     640                     ; DESIRED SCREEN WIDTH
SCRHEIGH    EQU     480                     ; DESIRED SCREEN HEIGHT
MID_X       EQU     SCRWIDTH/2              ; MIDPOINT X COORDINATE
MID_Y       EQU     SCRHEIGH/2              ; MIDPOINT Y COORDINATE
SQRSIDE     EQU     64                      ; SIDE OF THE SQUARE TO DRAW
SQRBCHAN    EQU     128                     ; SQUARE BLUE CHANNEL VALUE
DELTA       EQU     1                       ; AMOUNT TO MOVE THE SQUARE BY EACH FRAME
RED_COLOR    EQU     $00FF0000               ; RED COLOR
ORANGE_COLOR EQU     $00FFA500               ; ORANGE COLOR
YELLOW_COLOR EQU     $00FFFF00               ; YELLOW COLOR
GREEN_COLOR  EQU     $00008000               ; GREEN COLOR

            ORG     $1000
            
; -----------------------------------------------------------------------------
; VARIABLES
; -----------------------------------------------------------------------------
XPOS        DS.W    1                       ; VARIABLE TO STORE X POSITION
YPOS        DS.W    1                       ; VARIABLE TO STORE Y POSITION

; -----------------------------------------------------------------------------
START
            JSR     INIT                    ; INITIALIZE SCREEN
            MOVE.W  #SCRWIDTH/2,XPOS        ; INITIALIZE X POSITION (CENTER)
            MOVE.W  #SCRHEIGH/2,YPOS        ; INITIALIZE Y POSITION (CENTER)
            MOVE.B  #17,D1  ; Set drawing mode to double buffering
            MOVE.B  #92,D0
            TRAP    #15
            
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

; -----------------------------------------------------------------------------
; Subroutine to check key presses and update position
; -----------------------------------------------------------------------------
CHECK_KEYS
            MOVEM.L D1-D7/A0-A1,-(A7)       ; Save registers on the stack

            MOVE.B  #19,D0                  ; TASK NUMBER FOR CHECKING KEYS
            MOVE.L  #'W'<<24+'A'<<16+'S'<<8+'D',D1 ; CHECK FOR 'W', 'A', 'S', 'D'
            TRAP    #15                     ; Call the keyboard check task
            
            MOVE.W  XPOS,D3                 ; Load current X position
            MOVE.W  YPOS,D4                 ; Load current Y position

            ; Check if 'W' is pressed
            BTST    #24,D1
            BEQ     NO_W
            SUB.W   #DELTA,D4               ; Move up
            CMP.W   #SQRSIDE/2,D4
            BGE     NO_W
            MOVE.W  #SQRSIDE/2,D4           ; Correct position at top edge
NO_W        
            ; Check if 'S' is pressed
            BTST    #8,D1
            BEQ     NO_S
            ADD.W   #DELTA,D4               ; Move down
            CMP.W   #SCRHEIGH-SQRSIDE/2,D4
            BLE     NO_S
            MOVE.W  #SCRHEIGH-SQRSIDE/2,D4  ; Correct position at bottom edge
NO_S        
            ; Check if 'A' is pressed
            BTST    #16,D1
            BEQ     NO_A
            SUB.W   #DELTA,D3               ; Move left
            CMP.W   #SQRSIDE/2,D3
            BGE     NO_A
            MOVE.W  #SQRSIDE/2,D3           ; Correct position at left edge
NO_A        
            ; Check if 'D' is pressed
            BTST    #0,D1
            BEQ     NO_D
            ADD.W   #DELTA,D3               ; Move right
            CMP.W   #SCRWIDTH-SQRSIDE/2,D3
            BLE     NO_D
            MOVE.W  #SCRWIDTH-SQRSIDE/2,D3  ; Correct position at right edge
NO_D        
            MOVE.W  D3,XPOS                 ; Store updated X position
            MOVE.W  D4,YPOS                 ; Store updated Y position

            MOVEM.L (A7)+,D1-D7/A0-A1       ; Restore registers from the stack
            RTS                             ; Return from subroutine


PAINT_BACKGROUND
            MOVEM.L D1-D6,-(A7)             ; STORE REGISTERS
            ; Top left quadrant (RED)
            MOVE.L  #RED_COLOR,D1           ; Set fill color to RED
            MOVE.B  #81,D0                  ; Set fill color task
            TRAP    #15
            MOVE.W  #0,D1                   ; Upper left X
            MOVE.W  #0,D2                   ; Upper left Y
            MOVE.W  #MID_X-1,D3             ; Lower right X (midpoint minus one)
            MOVE.W  #MID_Y-1,D4             ; Lower right Y (midpoint minus one)
            MOVE.B  #87,D0                  ; Draw rectangle task
            TRAP    #15

            ; Top right quadrant (ORANGE)
            MOVE.L  #ORANGE_COLOR,D1        ; Set fill color to ORANGE
            MOVE.B  #81,D0                  ; Set fill color task
            TRAP    #15
            MOVE.W  #MID_X,D1               ; Upper left X (midpoint)
            MOVE.W  #0,D2                   ; Upper left Y
            MOVE.W  #SCRWIDTH-1,D3          ; Lower right X (full width minus one)
            MOVE.W  #MID_Y-1,D4             ; Lower right Y (midpoint minus one)
            MOVE.B  #87,D0                  ; Draw rectangle task
            TRAP    #15

            ; Bottom left quadrant (YELLOW)
            MOVE.L  #YELLOW_COLOR,D1        ; Set fill color to YELLOW
            MOVE.B  #81,D0                  ; Set fill color task
            TRAP    #15
            MOVE.W  #0,D1                   ; Upper left X
            MOVE.W  #MID_Y,D2               ; Upper left Y (midpoint)
            MOVE.W  #MID_X-1,D3             ; Lower right X (midpoint minus one)
            MOVE.W  #SCRHEIGH-1,D4          ; Lower right Y (full height minus one)
            MOVE.B  #87,D0                  ; Draw rectangle task
            TRAP    #15

            ; Bottom right quadrant (GREEN)
            MOVE.L  #GREEN_COLOR,D1         ; Set fill color to GREEN
            MOVE.B  #81,D0                  ; Set fill color task
            TRAP    #15
            MOVE.W  #MID_X,D1               ; Upper left X (midpoint)
            MOVE.W  #MID_Y,D2               ; Upper left Y (midpoint)
            MOVE.W  #SCRWIDTH-1,D3          ; Lower right X (full width minus one)
            MOVE.W  #SCRHEIGH-1,D4          ; Lower right Y (full height minus one)
            MOVE.B  #87,D0                  ; Draw rectangle task
            TRAP    #15
            MOVEM.L (A7)+,D1-D6             ; RESTORE REGISTERS
            RTS



          

            END     START
