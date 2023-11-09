; ================================
; CHARACTER MANAGMENT
; ================================

; INITIALIZE CHARACTER

    MOVE.W #SCRHEIGH/2,(PADPOSY)
    RTS
    
;UPDATE CHARACTER

    MOVE.W D0,-(A7)

    ;UPDATE COORDINATE
    
    MOVE.W (PADPOSY),D0
    BTST
    
        


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
