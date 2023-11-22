; -----------------------------------------------------------------------------
; CONSTANTS
; -----------------------------------------------------------------------------
SCRWIDTH    EQU     640                     ; DESIRED SCREEN WIDTH
SCRHEIGH    EQU     480                     ; DESIRED SCREEN HEIGHT
SQRSIDE     EQU     64                      ; SIDE OF THE SQUARE TO DRAW
SQRRGB      EQU     $00FF00FF               ; SQUARE RGB COLOR (Magenta)
SQRXPOS     EQU     SCRWIDTH/2              ; INITIAL X POSITION OF THE SQUARE
SQRYPOS     EQU     SCRHEIGH/2              ; INITIAL Y POSITION OF THE SQUARE

            ORG     $1000
START
            JSR     INIT                    ; INITIALIZE SCREEN
            MOVE.W  #SQRXPOS,XPOS           ; INITIALIZE X POSITION
            MOVE.W  #SQRYPOS,YPOS           ; INITIALIZE Y POSITION
            MOVE.W  #SQRSIDE,D3             ; SQUARE SIDE

            MOVE.B  #17,D0                  ; ENABLE DOUBLE BUFFERING
            TRAP    #15
            MOVE.B  #4,D0                   ; SET DRAWING MODE TO NORMAL
            MOVE.B  #92,D1                  ; SET DRAWING MODE TASK
            TRAP    #15

MAIN_LOOP
            MOVE.B  #11,D0                  ; CLEAR SCREEN TASK
            TRAP    #15                     ; CLEAR OFF-SCREEN BUFFER

            MOVE.W  XPOS,D1                 ; GET CURRENT X POSITION
            MOVE.W  YPOS,D2                 ; GET CURRENT Y POSITION
            JSR     DRSQUARE                ; DRAW SQUARE

            JSR     CHECK_KEYS              ; CHECK FOR KEY PRESSES

            MOVE.B  #94,D0                  ; REPAINT SCREEN TASK
            TRAP    #15                     ; COPY BUFFER TO SCREEN

            BRA     MAIN_LOOP               ; REPEAT LOOP            

            SIMHALT                         ; HALT SIMULATOR ON EXIT

; -----------------------------------------------------------------------------
; VARIABLES
; -----------------------------------------------------------------------------
            ORG     $2000                   ; SAFE LOCATION FOR VARIABLES
XPOS        DS.W    1                       ; VARIABLE TO STORE X POSITION
YPOS        DS.W    1                       ; VARIABLE TO STORE Y POSITION

; Rest of the subroutines remain the same...
                     ; VARIABLE TO STORE Y POSITION

; -----------------------------------------------------------------------------
; SUBROUTINES
; -----------------------------------------------------------------------------
INIT
; Initializes the output window to 640x480 windowed mode.
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
; Input    - D1.W - Square center X coordinate.
;            D2.W - Square center Y coordinate.
;            D3.W - Square side.
; Output   - None
; Modifies - D0, D1, D4-D6
; -----------------------------------------------------------------------------
            MOVEM.L D0-D6,-(A7)             ; STORE REGISTERS
            MOVE.W  D1,D6                   ; STORE D1
            MOVE.L  #SQRRGB,D1              ; SQUARE RGB COLOR
            MOVE.B  #81,D0
            TRAP    #15                     ; DEFINE FILL COLOR
            MOVE.L  #$00FFFFFF,D1           ; WHITE COLOR
            MOVE.B  #80,D0
            TRAP    #15                     ; DEFINE CONTOUR COLOR
            MOVE.W  D6,D1                   ; RESTORE D1
            MOVE.W  D3,D5                   ; COPY THE VALUE TO D5
            LSR.W   #1,D5                   ; COMPUTE HALF THE SIDE
                        ; After computing half side in D5
            SUB.W   D5,D1                   ; COMPUTE XLEFT
            SUB.W   D5,D2                   ; COMPUTE YLEFT
            ADD.W   D5,D6                   ; COMPUTE XRIGHT using the half side length in D5
            ADD.W   D5,D7                   ; COMPUTE YRIGHT using the half side length in D5

            MOVE.B  #87,D0                  ; DRAW RECTANGLE TASK NUMBER
            TRAP    #15                     ; DRAW IT
            MOVEM.L (A7)+,D0-D6             ; RESTORE REGISTERS
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
            SUB.W   #1,D4                   ; MOVE UP BY 1 PIXEL
NO_W        BTST.L  #16,D1                  ; CHECK 'A'
            BEQ     NO_A
            SUB.W   #1,D3                   ; MOVE LEFT BY 1 PIXEL
NO_A        BTST.L  #8,D1                   ; CHECK 'S'
            BEQ     NO_S
            ADD.W   #1,D4                   ; MOVE DOWN BY 1 PIXEL
NO_S        BTST.L  #0,D1                   ; CHECK 'D'
            BEQ     NO_D
            ADD.W   #1,D3                   ; MOVE RIGHT BY 1 PIXEL
NO_D        MOVE.W  D3,XPOS                 ; STORE UPDATED X POSITION
            MOVE.W  D4,YPOS                 ; STORE UPDATED Y POSITION
            RTS
            
            
            END     START



            
            
