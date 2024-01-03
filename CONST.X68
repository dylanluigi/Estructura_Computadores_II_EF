;=========================================
; GAME CONSTANTS
;=========================================

;SQUARE CONSTANTS ------------------------

SQRSIDE EQU 64
SQRSCLR EQU $006B62D9 
SQRFCLR EQU $006D9AEC

;MAP CONSTANTS ---------------------------------------------------

MAPINIX     EQU     0                       ; X OF INITIAL SCREEN
MAPINIY     EQU     0                       ; Y OF INITIAL SCREEN
MAPWIDTH    EQU     3                       ; NUMBER OF SCREENS HORIZONTALLY
MAPHEIGH    EQU     3                       ; NUMBER OF SCREENS VERTICALLY
MAPSCRW     EQU     20                      ; TILES PER SCREEN HORIZONTALLY
MAPSCRH     EQU     15                      ; TILES PER SCREEN VERTICALLY
MAPTILEW    EQU     32                      ; SIZE OF TILE, HORIZONTALLY
MAPTILEH    EQU     32                      ; SIZE OF TILE, VERTICALLY
MAPANIM0    EQU     4                       ; ANIMATED TILE 0
MAPANIM1    EQU     8                       ; ANIMATED TILE 1
MAPDOOR     EQU     3                       ; DOOR GRAPHIC ID
MAPFREE     EQU     %00                     ; FREE CELL CODE
MAPDMG      EQU     %01                     ; DAMAGING CELL CODE
MAPOBS      EQU     %10                     ; OBSTACLE CELL
MAPSCRCM    EQU     $00FF                   ; SCREEN COMPLETED
MAPSCRNC    EQU     $0000                   ; SCREEN NOT COMPLETED
MAPSCRVS    EQU     $FF00                   ; SCREEN VISITED
MAPSCRNV    EQU     $0000                   ; SCREEN NOT VISITED

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
