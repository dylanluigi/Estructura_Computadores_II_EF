


; === SYSTEM INITIALIZES =============

SYSINIT

    MOVE.L (A7)+,A0
    JSR KBDINIT ;INIT KEYBOARD
    JSR SCRINIT ;INIT SCREEN
    JSR DMMINIT ;INIT DYNAMIC MEMORY
    ANDI.W #$DFFF,SR
    MOVE.L A0,-(A7)
    RTS
    
SCRINIT

    ORI.W #$0700,SR
    MOVE.L #SCRUPD,($80+SCRTRAP*4)
    MOVE.L #SCRWIDTH<<16|SCRHEIGH, D1 ;Set resolution
    MOVE.B #33,D0
    TRAP #15
    
    MOVE.L #1,D1    ;SET WINDOWED MODE
    TRAP #15
    
    ;CLEAR VISIBLE BUFFER
    MOVE.W #$FF00,D1
    MOVE.B #11,D0
    TRAP #15
    
    ;ENABLE DOUBLE BUFFER
    MOVE.B #17,D1
    MOVE.B #92,D0
    TRAP #15
    
    ;CLEAR HIDDEN BUFFER
    MOVE.W #$FF00,D1
    MOVE.B #11,D0
    TRAP #15
    
    ;SET EXCEPTION VECTOR
    MOVE.L #SCRISR,($60+SCRIRQ*4)
    
    ;ENABLE EXCEPTION PROCESSING
    MOVE.B #5,D1
    MOVE.B #32,D0
    TRAP #15
    
    ;ENABLE AUTO-IRQ
    MOVE.B  #%10000000|SCRIRQ,D2    ; ENABLE AUTO-IRQ
    MOVE.B  #SCRTIM,D3
    MOVE.B  #6,D1
    MOVE.B  #32,D0
    TRAP    #15
    
    ;PREPARE INTERRUPT FLAG
    CLR.B (SCRINTCT)
    
    ;PREPARE CYCLE COUNTER
    CLR.B (SCRCYCCT)
    
    ;ENABLE INTS
    ANDI.W #$F8FF,SR

    RTS
    
    
SCRISR

    ADDQ.B #1,(SCRINTCT)
    ADDQ.B #1,(SCRCYCCT)
    RTE
    
    
SCRUPD
    
    MOVEM.W D0-D1,-(A7)
    
    ;UPDATE DOUBLE BUFFER
    MOVE.B #94,D0
    TRAP #15

    ;CLEAR HIDDEN BUFFER
    MOVE.W #$FF00,D1
    MOVE.B #11,D0
    TRAP #15
    
    MOVEM.W (A7)+,D0-D1
    RTE
    
;=================================================================
; KEYBOARD MANAGMENT (SYSTEM CODE)
;=================================================================

KBDINIT
    
    ;INIT VARS
    CLR.B (KBDVAL)
    CLR.B (KBDEDGE)
    
    ;INSTALL
    MOVE.L #KBDREAD, ($80+KBDTRAP*4)
    
    RTS
    
KBDREAD

    MOVEM.L D0-D3,-(A7)

    MOVE.B #19,D0
    MOVE.L #KBDUP<<24+KBDLF<<16+KBDRG<<8+KBDDW,D1
    TRAP #15
    
    ;STORE KBDUP,KBDLF,KBDRG AND KBDDW
    BSR .STORE
    
    MOVE.L #KBDPA<<24+KBDA1<<16+KBDA2<<8+KBDUL,D1
    TRAP #15
 
    ;STORE KBDPA,KBDA1,KBDA2 AND KBDUL
    BSR .STORE
    
    ;COMPUTE EDGE
    MOVE.B (KBDVAL),D0
    
    ;EDGE = NOT(PREVIOUS) AND CURRENT ERGO LOOK AT CHANGED KEYS
    NOT.B D0
    AND.B D2,D0
    
    ;STORE VALUES (PRESS AND EDGE)
    MOVE.B D2,(KBDVAL)
    MOVE.B D0,(KBDEDGE)
    MOVEM.L (A7)+,D0-D3
    RTE
    
    ;TRANSLATES THE 8-BIT ENCODING
    ;OF TRAP #15 TASK 19 INTO A 1-BIT
    ;PER KEYPRESS ENCODING

.STORE        
    MOVE.W #3,D3
.LOOP
    LSL.L #8,D1
    ROXL.B #1,D2
    DBRA.W D3,.LOOP
    RTS

;=================================================================
; DYNAMIC MEMORY MANAGMENT (SYSTEM CODE)
;=================================================================    

; -----------------------------------------------------------------------------
DMMINIT
; INITIALIZES THE DYNAMIC MEMORY TO ALL OWNED BY SYSTEM.
; INPUT    - NONE
; OUTPUT   - NONE
; MODIFIES - NONE
; -----------------------------------------------------------------------------
            MOVEM.L D0/A0,-(A7)
            LEA     DMMDATA,A0
            MOVE.W  #DMMBNUM-1,D0
.LOOP       MOVE.W  #DMMSYSID,(A0)
            ADD.L   #DMMBSIZE,A0
            DBRA.W  D0,.LOOP
            MOVEM.L (A7)+,D0/A0
            RTS

; -----------------------------------------------------------------------------
DMMFIRST
; SEARCHES THE FIRST MEMORY SLOT NOT OWNED BY SYSTEM AND OUTPUTS A POINTER
; TO THE CORRESPONDING DATA (SLOT ADDRESS+2)
; INPUT    - NONE
; OUTPUT   - A0   : POINTER TO THE DATA OR 0 IF NOT FOUND
; MODIFIES - NONE (ASIDE OF OUTPUT)
; -----------------------------------------------------------------------------
            LEA     DMMDATA,A0
DMMFRLOP    TST.W   (A0)+
            BNE     DMMFRFND
            ADD.L   #DMMBSIZE-2,A0
DMMFRCOM    CMP.L   #DMMDATA+DMMBSIZE*DMMBNUM-1,A0
            BLT     DMMFRLOP
            MOVE.L  #0,A0
DMMFRFND    RTS

; -----------------------------------------------------------------------------
DMMNEXT
; SEARCHES THE NEXT MEMORY SLOT NOT OWNED BY SYSTEM AND OUTPUTS A POINTER
; TO THE CORRESPONDING DATA (SLOT ADDRESS+2)
; INPUT    - A0   : POINTER WITHIN THE CURRENT SLOT
; OUTPUT   - A0   : POINTER TO THE DATA OR 0 IF NOT FOUND
; MODIFIES - NONE (ASIDE OF OUTPUT)
; -----------------------------------------------------------------------------
            MOVE.L  D0,-(A7)
            MOVE.L  A0,D0
            AND.L   #-DMMBSIZE,D0           ; TAKE ADVANTAGE OF ALIGNMENT
            ADD.L   #DMMBSIZE,D0
            MOVE.L  D0,A0
            MOVE.L  (A7)+,D0
            BRA     DMMFRCOM

; -----------------------------------------------------------------------------
DMMFRSTO
; SEARCHES THE FIRST MEMORY SLOT WITH THE SPECIFIED ID AND OUTPUTS A POINTER
; TO THE CORRESPONDING DATA (SLOT ADDRESS+2)
; INPUT    - D0.W : ID TO SEARCH
; OUTPUT   - A0   : POINTER TO THE DATA OR 0 IF NOT FOUND
; MODIFIES - NONE (ASIDE OF OUTPUT)
; -----------------------------------------------------------------------------
            LEA     DMMDATA,A0
DMMFLOOP    CMP.W   (A0)+,D0
            BEQ     DMMFFND
            ADD.L   #DMMBSIZE-2,A0
DMMFCOM     CMP.L   #DMMDATA+DMMBSIZE*DMMBNUM-1,A0
            BLT     DMMFLOOP
            MOVE.L  #0,A0
DMMFFND     RTS

; -----------------------------------------------------------------------------
DMMNEXTO
; SEARCHES THE NEXT MEMORY SLOT WITH THE SPECIFIED ID AND OUTPUTS A POINTER
; TO THE CORRESPONDING DATA (SLOT ADDRESS+2)
; INPUT    - D0.W : ID TO SEARCH
;            A0   : POINTER WITHIN THE CURRENT SLOT
; OUTPUT   - A0   : POINTER TO THE DATA OR 0 IF NOT FOUND
; MODIFIES - NONE (ASIDE OF OUTPUT)
; -----------------------------------------------------------------------------
            MOVE.L  D0,-(A7)
            MOVE.L  A0,D0
            AND.L   #-DMMBSIZE,D0           ; TAKE ADVANTAGE OF ALIGNMENT
            ADD.L   #DMMBSIZE,D0
            MOVE.L  D0,A0
            MOVE.L  (A7)+,D0
            BRA     DMMFCOM

; -----------------------------------------------------------------------------
DMMALLOC
; SEARCHES THE FIRST FREE (SYS OWNED) SLOT, ASSIGNS TO THE SPECIFIED OWNER
; AND RETURNS A POINTER TO THE CORRESPONDING DATA (SLOT ADDRESS + 2)
; INPUT    - D0.W : ID TO ASSIGN
; OUTPUT   - A0   : POINTER TO THE DATA OR 0 IF NOT FREE SPACE
; MODIFIES - NONE (ASIDE OF OUTPUT)
; -----------------------------------------------------------------------------
            MOVE.W  D0,-(A7)
            CLR.W   D0
            JSR     DMMFRSTO
            MOVE.W  (A7)+,D0
            CMP.L   #0,A0
            BEQ     .END
            MOVE.W  D0,-2(A0)
.END        RTS

; -----------------------------------------------------------------------------
DMMFREE
; FREES THE SLOT TO WHICH THE PROVIDED POINTER BELONGS BY SETTING ITS OWNED TO
; SYSTEM (0)
; INPUT    - A0   : POINTER BELONGING TO THE SLOT TO FREE
; OUTPUT   - NONE
; MODIFIES - NONE
; -----------------------------------------------------------------------------
            MOVEM.L D0/A0,-(A7)
            MOVE.L  A0,D0
            AND.L   #-DMMBSIZE,D0           ; TAKE ADVANTAGE OF ALIGNMENT
            MOVE.L  D0,A0
            CLR.W   (A0)
            MOVEM.L (A7)+,D0/A0
            RTS            



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
