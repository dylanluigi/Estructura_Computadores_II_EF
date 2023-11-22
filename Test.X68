; -----------------------------------------------------------------------------
; CONSTANTS
; -----------------------------------------------------------------------------
SCRWIDTH    EQU     640*2                     ; DESIRED SCREEN WIDTH
SCRHEIGH    EQU     480*2                     ; DESIRED SCREEN HEIGHT
SQRSIDE     EQU     64                      ; SIDE OF THE SQUARE TO DRAW
SQRBCHAN    EQU     128                     ; SQUARE BLUE CHANNEL VALUE
DELTA       EQU     1                       ; AMOUNT TO MOVE THE SQUARE BY EACH FRAME

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

            ; Check for key presses and update position if necessary
            JSR     CHECK_KEYS

            ; Get the updated position from variables
            MOVE.W  XPOS,D1                 ; GET CURRENT X POSITION
            MOVE.W  YPOS,D2                 ; GET CURRENT Y POSITION

            ; Draw the square at the updated position
            MOVE.W  #SQRSIDE,D3             ; SQUARE SIDE
            MOVE.B  #SQRBCHAN,D0            ; SQUARE BLUE CHANNEL VALUE
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
CHECK_KEYS
; Check for 'W', 'A', 'S', 'D' key presses and update square position
; -----------------------------------------------------------------------------
            MOVE.B  #19,D0                  ; TASK NUMBER FOR CHECKING KEYS
            MOVE.L  #'W'<<24+'A'<<16+'S'<<8+'D',D1 ; CHECK FOR 'W', 'A', 'S', 'D'
            TRAP    #15
            
            MOVE.W  XPOS,D3                 ; LOAD CURRENT X POSITION
            MOVE.W  YPOS,D4                 ; LOAD CURRENT Y POSITION
            BTST.L  #24,D1                  ; CHECK 'W'
            BEQ     NO_W
            SUB.W   #DELTA,D4               ; MOVE UP BY 'DELTA' PIXELS
NO_W        BTST.L  #16,D1                  ; CHECK 'A'
            BEQ     NO_A
            SUB.W   #DELTA,D3               ; MOVE LEFT BY 'DELTA' PIXELS
NO_A        BTST.L  #8,D1                   ; CHECK 'S'
            BEQ     NO_S
            ADD.W   #DELTA,D4               ; MOVE DOWN BY 'DELTA' PIXELS
NO_S        BTST.L  #0,D1                   ; CHECK 'D'
            BEQ     NO_D
            ADD.W   #DELTA,D3               ; MOVE RIGHT BY 'DELTA' PIXELS
NO_D        MOVE.W  D3,XPOS                 ; STORE UPDATED X POSITION
            MOVE.W  D4,YPOS                 ; STORE UPDATED Y POSITION
            RTS

          

            END     START
