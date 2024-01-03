; =============================================
;  GAME VARIABLES
; =============================================

; --- CHARACTER RELATED VARIABLES -------------

CHARPOSY DS.W 1 ;CHARACTER Y COORDINATE
CHARPOSX DS.W 1 ;CHARACTER X COORDINATE

; --- INSTRUCTIONS STATE RELATED VARIABLES ----

INSTIMER DS.W 1 ;INSTRUCTIONS TIMER

; --- STATE RELATED VARIABLES -----------------

STACUR DS.W 1 ;CURRENT STATE
STANEXT DS.W 1 ;NEXT STATE

; --- MAP RELATED VARIABLES --------------------------------------------------

MAPPOSX     DS.W    1                       ; CURRENT SCREEN X
MAPPOSY     DS.W    1                       ; CURRENT SCREEN Y
MAPSCPTR    DS.L    1                       ; CURRENT SCREEN POINTER
MAPNUMEN    DS.W    1                       ; NUMBER OF LIVING ENEMIES IN SCR
MAPCOMPL    DS.W    MAPWIDTH*MAPHEIGH       ; FLAGS FOR VISITED/COMPLETED ROOM

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
