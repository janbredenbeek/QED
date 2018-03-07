* QED TEXT EDITOR by Jan Bredenbeek
* Start: 27 June 1988
* Release 1.00: August 1988
* Release 1.01: September 1988 (stable)
* Release 2.00b1: September 1994 (UNSTABLE!)
* Release 2.00b2: January 2018
* Licenced under GPL v3 Licence (2017)
* See https://github.com/janbredenbeek/QED for latest version from the author
* This should be assembled and linked using the GST Macro Assembler and Linker
* (see http://www.dilwyn.me.uk/asm/index.html)
*
* Main program part

         INCLUDE  WIN1_MACRO_LIB             Macro definitions
         INCLUDE  WIN1_QDOS_IN_MAC           QDOS definitions
         INCLUDE  WIN2_QEDv2_QED_IN          QED Definitions

* External references         
         
         XREF     MK_LNTBL,INSRT_LN,DEL_LNTB,ENT_LINE,GETSCRLN,MOV_TXT
         XREF     STRIPSPC,COPYLINE,DSP_PAGE,DSP_BUF,DSP_LINE,OPEN_DEF
         XREF     ERRMSG,DISPSTAT,ITOD,READNUM,FINDLINE,EL_ERR,FIND_DSP
         XREF     ENT_LIN1,DS_NUM,DS_NUM1,FIND_DS1,NO_LNTBL,NEXT_ENV
         XREF     REP_CMD,ENT_CMD,ED_COMLN,SKIPSPC,UCASETBL,CUP,CDOWN
         XREF     GET_INDT,RET_KEY,CMD_T,CMD_B,CMPTABS,CL_COPY

* Start of main code         
         
         SECTION  CODE

         BRA.S    ED_START
         DC.L     0
         DC.W     $4AFB
         STRING$  {'QED'}
         DS.W     0                 Get the following data word aligned
         
* Configuration data (modified by QEDCONFIG_BAS)
         
WINDEF   DC.W     480,210,16,5      (14-21) Outline window
DEFMARGN DC.W     0,79              (22-25) Default margins
DFTABINC DC.W     9                 (26-27) Default TAB increment
DEFWRKSP DC.W     12                (28-29) Default workspace size (KB)
DEFWRKOV DC.W     4                 (30-31) Default workspace overhead (KB)
BORD_PRM DC.B     4,1,0,7           (32-35) Border colour and size
TXTWIN_P DC.B     0                 (36) Text window paper colour
TXTWIN_I DC.B     7                 (37) Text window ink colour
REPORT_P DC.B     2                 (38) Report (status) window paper colour
REPORT_I DC.B     7                 (39) Report (status) window ink colour
CMDLN_P  DC.B     4                 (40) Command line paper colour
CMDLN_I  DC.B     0                 (41) Command line ink colour
CSIZE    DC.B     0                 (42) Character size
DFOVRMOD DC.B     0                 (43) Default overwrite mode
DEFWRAP  DC.B     -1                (44) Default wordwrap mode
DEFAINDT DC.B     -1                (45) Default indent mode
DEFTABEX DC.B     -1                (46) Default TAB expansion mode
DEFTABCP DC.B     0                 (47) Default TAB compression mode
ARROWCMD DC.B     0                 (48) Default arrow command
HELPFNAM STRING$  'win1_QED_HELP'   (50-97) Name of Help file
         DS.B     46-(*-HELPFNAM)   Allow for spare
CONNAME  STRING$  'CON'             Name of CON device

         XDEF     REPORT_P,REPORT_I,CMDLN_P,CMDLN_I

SKIPCMD  TST.W    D0
         BLE.S    SK_END
         CMPI.B   #' ',(A0)
         BHI.S    SK_END
         SUBQ.W   #1,D0
         ADDQ.L   #1,A0
         BRA      SKIPCMD
SK_END   TST.W    D0
         RTS

* INITIALISATION PROCEDURE

ED_START ADDA.L   A4,A6             ; A6 = start of dataspace
         MOVE.L   A7,ERR_SP(A6)     ; Set error return stack pointer
         MOVEQ    #-1,D1
         MOVEQ    #-1,D2
         QDOS     MT.DMODE          ; read mode
         TST.B    D1
         IF NE THEN
            MOVEQ    #0,D1
            MOVEQ    #-1,D2
            QDOS     MT.DMODE       ; if MODE 8, change to MODE 4
         ENDIF
         SF       REDIR(A6)
         MOVE.L   A7,A0
         MOVE.W   (A0)+,D0
         BEQ.S    NO_REDIR
         ST       REDIR(A6)         ; Signal 'input file redirected' (currently not used)
NO_REDIR MOVEQ    #-1,D1
         MOVEQ    #0,D3
         LEA      CONNAME,A0        ; open guardian console window
         QDOS     IO.OPEN
         MOVE.L   D0,D3             ; error code
         BNE      EXIT_ERR          ; if error, commit suicide with error message
         MOVE.L   A0,GUARDWIN(A6)   ; Guardian window (outline)
         MOVE.B   BORD_PRM,D1       ; Border colour
         MOVEQ    #0,D2
         MOVE.B   BORD_PRM+1,D2     ; Border size
         MOVEQ    #-1,D3
         MOVE.L   A7,A1
         MOVE.L   WINDEF+4,-(A7)    ; Window LHS x,y
         MOVE.L   WINDEF,-(A7)      ; Window size
         MOVE.W   D2,D0             ; Border size
         SUB.W    D0,-(A1)          ; Discount border size from window LHS y
         ADD.W    D0,D0             ; Border width = 2 times size
         SUB.W    D0,-(A1)          ; Discount border width from window LHS x
         ADD.W    D0,-(A1)          ; Add border height * 2 to window height
         ADD.W    D0,D0             ; Double again to get total border width
         ADD.W    D0,-(A1)          ; And add this to window width
         QDOS     SD.WDEF           ; Now define guardian window size & pos
         MOVE.L   D0,D3             ; NEW: test for error
         BNE      EXIT_ERR
         LEA      BORD_PRM+2,A2
         MOVE.B   (A2),D1           ; Get paper colour for guardian window
         QDOS     SD.SETPA
         MOVE.B   (A2)+,D1          ; Again for strip colour
         QDOS     SD.SETST
         MOVE.B   (A2),D1           ; And ink colour
         QDOS     SD.SETIN

; Now open main editing window         
         
         MOVEQ    #-1,D1
         MOVEQ    #0,D3
         LEA      CONNAME,A0
         QDOS     IO.OPEN
         MOVE.L   D0,D3
         BNE      EXIT_ERR
         MOVE.L   A0,TXTWIN(A6)     ; channel ID
         MOVE.L   WINDEF,(A7)       ; copy definition from guardian window parms
         MOVE.L   WINDEF+4,4(A7)
         SUBI.W   #10,2(A7)         ; but subtract 10 to allow for command/status line
         MOVEQ    #0,D1
         MOVEQ    #0,D2
         MOVEQ    #-1,D3
         MOVE.L   A7,A1
         QDOS     SD.WDEF           ; set size/position
         MOVE.B   CSIZE,D1
         MOVEQ    #0,D2
         QDOS     SD.SETSZ          ; set character size (only width)
         SUBQ.W   #8,A7
         MOVE.L   A7,A1
         QDOS     SD.CHENQ          ; get width/height in characters
         MOVE.L   (A7)+,WINWID(A6)  ; store
         ADDQ.W   #4,A7             ; skipover extra words
         LEA      TXTWIN_P,A2
         MOVE.B   (A2),D1           ; set paper/ink
         QDOS     SD.SETPA
         MOVE.B   (A2)+,D1
         QDOS     SD.SETST
         MOVE.B   (A2),D1
         QDOS     SD.SETIN
         
; Finally, open command/status window
         
         MOVEQ    #-1,D1
         MOVEQ    #0,D3
         LEA      CONNAME,A0
         QDOS     IO.OPEN
         TST.L    D0
         BNE      EXIT_ERR
         MOVE.L   A0,CMDWIN(A6)
         MOVE.W   2(A7),D0          ; height of text (editing) window
         ADD.W    D0,6(A7)          ; add to LHS position
         MOVE.W   #10,2(A7)         ; just one text line...
         MOVEQ    #0,D1
         MOVEQ    #0,D2
         MOVEQ    #-1,D3
         MOVE.L   A7,A1
         QDOS     SD.WDEF
         ADDQ.W   #8,A7
         MOVE.B   CSIZE,D1          ; make character size same as text window
         IF NE THEN
            MOVEQ    #1,D1
         ENDIF
         MOVEQ    #0,D2
         QDOS     SD.SETSZ
         
; Now set some variables to their configured default
         
ED_CMDLN CLR.L    ENVSAV(A6)        ; Pointer to saved file environment
         CLR.L    NEXTFILE(A6)      ; Pointer to next file in file list
         MOVE.L   DEFMARGN,LEFTMAR(A6)  ; left margin
         MOVE.W   DFTABINC,TABINC(A6)   ; TAB distance
         MOVE.B   DFOVRMOD,OVERWMOD(A6) ; Overwrite mode (-1) or not (0)
         MOVE.B   DEFWRAP,WORDWRAP(A6)  ; Word wrap (-1) or not (0)
         MOVE.B   DEFAINDT,AUTOINDT(A6) ; Auto indent (-1) or not (0)
         MOVE.B   DEFTABEX,TABEXPND(A6) ; Tab expansion (-1) or not (0)
         MOVE.B   DEFTABCP,TABCOMPR(A6) ; Tab compression (-1) or not (0)
         
; Clear window and print signon
         
         MOVE.L   GUARDWIN(A6),A0
         QDOS     SD.CLEAR
         MOVEQ    #3,D1
         MOVEQ    #1,D2
         QDOS     SD.SETSZ          ; in HUGE characters!
         LEA      SIGNON1,A1        ; Program name
         BSR      P_MIDDLE          ; print at centre of window
         MOVEQ    #1,D1
         MOVEQ    #0,D2
         QDOS     SD.SETSZ
         MOVEQ    #0,D1
         MOVEQ    #3,D2
         QDOS     SD.POS
         LEA      SIGNON2,A1        ; Copyright message
         BSR      P_MIDDLE
         MOVE.W   (A7),D0
         LSL.W    #2,D0
         LEA      2(A7,D0.W),A0     ; Get ptr to command line
         MOVE.W   (A0)+,D0          ; And its length
         SF       D2
ED_NFILE LEA      CMDBUF(A6),A1
         SF       D1                ; No filename found yet
ED_CMDLP BSR      SKIPCMD
         BLE.S    ED_CMDEN
         CMPI.B   #'-',(A0)         ; Options start with '-'
         BEQ.S    ED_CMDOP
         CMPI.B   #'/',(A0)         ; or '/'
         BEQ.S    ED_CMDOP          ; Jump if option found
         TST.B    D1
         BNE.S    ED_FORK           ; But if new filename, start off current
         ST       D1                ; Signal "Filename found"
ED_CMDOP MOVE.B   (A0)+,(A1)+
         SUBQ.W   #1,D0             ; Copy into cmdbuf
         BLE.S    ED_CMDEN
         CMPI.B   #' ',(A0)
         BHI      ED_CMDOP
         BRA      ED_CMDLP
ED_FORK  ST       D2
         MOVE.B   #LF,(A1)+
         MOVEM.L  D0/D2/A0,-(A7)
         BSR      ED_LOAD
         TST.L    D0
         BEQ.S    ED_FORK2
         MOVEM.L  (A7)+,D0/D2/A0
         BRA      ED_NFILE
ED_FORK2 BSR.S    FORK
         MOVE.L   D0,D3
         MOVEM.L  (A7)+,D0/D2/A0
         BEQ      ED_NFILE
EXIT_ERR MOVEQ    #-1,D1
         QDOS     MT.FRJOB

ED_CMDEN MOVE.B   #LF,(A1)+
         BSR      ED_LOAD
         MOVE.L   D0,D3
         BEQ.S    ED_DSP
         TST.L    NEXTFILE(A6)
         BEQ      EXIT_ERR
ED_DSP   BSR      NEXT_ENV
         BSR      DSP_PAGE
         BRA      MAINLOOP

* Fork off another file

         XDEF     FORK

FORK     BSR.S    SAV_ENV           Save current file environment
         BNE.S    F_NOMEM
         MOVE.L   ENVSAV(A6),A2     Get ptr to save area
         CLR.L    ENVSAV(A6)
         TST.L    NEXTFILE(A6)
         BNE.S    FORK_2
         MOVE.L   A2,NEXTFILE(A6)   If no next file, make current file next
FORK_2   BSR.S    SAV_ENV           Create save area for next file
         BNE.S    F_NOMEM2
         MOVE.L   ENVSAV(A6),(A2)   And make next file "next" after current
         MOVEQ    #0,D0
         RTS
F_NOMEM2 MOVE.L   A2,ENVSAV(A6)
F_NOMEM  TST.L    D0
         RTS

* Save current file environment. Allocates workspace in CHP if necessary.

         XDEF     SAV_ENV

SAV_ENV  MOVE.L   ENVSAV(A6),A0
         MOVE.L   A0,D0
         BNE.S    SE_2
         MOVE.L   #ENV_END-NEXTFILE+27,D1
         MOVEQ    #-1,D2
         MOVEM.L  A2/A3,-(A7)
         QDOS     MT.ALCHP
         MOVEM.L  (A7)+,A2/A3
         TST.L    D0
         BNE.S    SE_END
         MOVE.L   A0,ENVSAV(A6)
SE_2     MOVE.L   #ENV_END-NEXTFILE,D0
         LEA      NEXTFILE(A6),A1
SE_SAV   MOVE.L   (A1)+,(A0)+
         SUBQ.L   #4,D0
         BGT      SE_SAV
         MOVEM.L  D4-D7/A4-A5,(A0)
         MOVEQ    #0,D0
SE_END   RTS

* Commandline option table

ED_OPTAB DC.B     -2,'@'            Start at line n
         DC.W     STARTLN
         DC.B     -2,'B'            Workspace in KB
         DC.W     WORKSPC
         DC.B     0,'C'             Cooked mode
         DC.W     COOKED
         DC.B     -2,'O'            Workspace overhead
         DC.W     WORKSPOV
         DC.B     -1,'T'            TAB increment
         DC.W     TABINC
         DC.W     0

* Load a complete file

         XDEF     ED_LOAD

ED_LOAD  SUBA.L   A5,A5
         CLR.L    TXTBASE(A6)
         CLR.W    FILENAME(A6)
         CLR.W    WORKSPC(A6)
         CLR.W    WORKSPOV(A6)
         CLR.W    STARTLN(A6)
         SF       COOKED(A6)
         SF       MSGPRNTD(A6)
         SF       STPRINTD(A6)
         LEA      CMDBUF(A6),A2
ED_FNLP  BSR      SKIPSPC
         BEQ      ED_TSTFN
         CMPI.B   #'-',(A2)
         BEQ.S    ED_OPT
         CMPI.B   #'/',(A2)
         BEQ.S    ED_OPT
         LEA      FILENAME+2(A6),A1
         MOVEQ    #0,D0
ED_FNCP  MOVE.B   (A2)+,(A1)+
         ADDQ.W   #1,D0
         CMPI.B   #' ',(A2)
         BLS.S    ED_ENDFN
         CMPI.W   #44,D0
         BLT      ED_FNCP
         MOVE.W   D0,FILENAME(A6)
         ERRMSG   {'Filename too long - any key to continue '}
         MOVEQ    #ERR.BN,D0
         BRA      ED_L_ERR
ED_ENDFN MOVE.W   D0,FILENAME(A6)
         BRA      ED_FNLP
ED_OPT   ADDQ.L   #1,A2
         MOVEQ    #0,D1
         MOVE.B   (A2)+,D1
         CMPI.B   #LF,D1
         BEQ.S    ED_TSTFN
         LEA      UCASETBL,A1
         MOVE.B   (A1,D1.W),D1
         LEA      ED_OPTAB,A1
ED_OPTLP MOVE.W   (A1)+,D2
         BEQ      ED_FNLP
         MOVE.W   (A1)+,D3
         CMP.B    D1,D2
         BNE      ED_OPTLP
         TST.W    D2
         BMI.S    ED_OPT2
         ST       (A6,D3.W)
         BRA      ED_FNLP
ED_OPT2  EXG      A1,A2
         BSR      READNUM
         EXG      A1,A2
         BTST     #8,D2
         BEQ.S    ED_OPT3
         TST.W    D1
         BLE      ED_FNLP
ED_OPT3  MOVE.W   D1,(A6,D3.W)
         BRA      ED_FNLP

ED_TSTFN TST.W    FILENAME(A6)
         BNE      OP_WRKFL
         MOVE.L   GUARDWIN(A6),A0
         PRINT    {LF,LF,'File name: '}
         MOVEQ    #0,D1
         MOVEQ    #44,D2
         LEA      FILENAME+2(A6),A1
         REPEAT
            QDOS     IO.EDLIN
            TST.L    D0
         UNTIL    EQ
         SUBQ.W   #1,D1
         BLE.S    ED_ABORT
         CMPI.B   #LF,-(A1)
         BEQ.S    ED_CONTN
ED_ABORT MOVEQ    #ERR.NC,D0
         RTS
ED_CONTN SUBA.W   D1,A1
         MOVE.W   D1,-(A1)
         TST.W    WORKSPC(A6)
         BNE.S    OP_WRKFL
GET_WRK  PRINT    {LF,'Workspace size (ENTER for default): '}
         MOVEQ    #0,D1
         MOVEQ    #10,D2
         LEA      CMDBUF(A6),A1
         REPEAT
            QDOS     IO.EDLIN
            TST.L    D0
         UNTIL    EQ
         CMPI.B   #LF,-(A1)
         BNE      ED_ABORT
         SUBQ.W   #1,D1
         BLE.S    OP_WRKFL
         LEA      CMDBUF(A6),A1
         BSR      READNUM
         TST.W    D1
         BGT.S    GETWRK1
         PRINT    {'Invalid number'}
         BRA      GET_WRK
GETWRK1  MOVEQ    #-1,D2
         QDOS     MT.ALCHP
         TST.L    D0
         BEQ.S    GETWRK2
         MOVE.L   GUARDWIN(A6),A0
         PRINT    {'Too large'}
         BRA      GET_WRK
GETWRK2  MOVE.L   A0,TXTBASE(A6)
         LEA      -$10(A0,D1.L),A0
         MOVE.L   A0,TXTMAX(A6)
OP_WRKFL LEA      FILENAME(A6),A0
         MOVEQ    #1,D3
         BSR      OPEN_DEF
         TST.L    TXTBASE(A6)
         BNE.S    RD_WRKFL
         MOVEM.L  D0/A0,-(A7)
         TST.L    D0
         IF EQ THEN
            MOVEQ    #4,D2
            MOVEQ    #-1,D3
            CLR.L    -(A7)
            MOVE.L   A7,A1
            QDOS     FS.HEADR
            MOVE.L   (A7)+,D1
            MOVEQ    #0,D0
            MOVE.W   WORKSPOV(A6),D0
            IF EQ THEN
               MOVE.W   DEFWRKOV,D0
            ENDIF
            SWAP     D0
            LSR.L    #6,D0
            ADD.L    D0,D1
         ELSE
            MOVEQ    #0,D1
            MOVE.W   WORKSPC(A6),D1
            IF EQ THEN
               MOVE.W   DEFWRKSP,D1
            ENDIF
            SWAP     D1
            LSR.L    #6,D1
         ENDIF
         MOVEQ    #-1,D2
         QDOS     MT.ALCHP
         TST.L    D0
         BEQ.S    SETWRKSP
         ERRMSG   {'No room for workspace'}
         MOVEM.L  (A7)+,D0/A0
         MOVE.L   #ERR.OM,-(A7)
         TST.L    D0
         BEQ      RDW_CLOS
         BRA      ED_L_ERR
SETWRKSP MOVE.L   A0,TXTBASE(A6)
         LEA      -$10(A0,D1.L),A0
         MOVE.L   A0,TXTMAX(A6)
         MOVEM.L  (A7)+,D0/A0
RD_WRKFL TST.L    D0
         BNE      NEW_WRKF
         MOVE.L   A0,-(A7)
         ERRMSG   {'Reading '}
         MOVE.L   CMDWIN(A6),A0
         LEA      FILENAME(A6),A1
         MOVE.W   UT_MTEXT,A2
         JSR      (A2)
         SF       MSGPRNTD(A6)
         MOVE.L   (A7)+,A0
         TST.B    COOKED(A6)
         BNE.S    ED_COOKD
         MOVEQ    #4,D2
         MOVEQ    #-1,D3
         CLR.L    -(A7)
         MOVE.L   A7,A1
         QDOS     FS.HEADR
         MOVE.L   (A7)+,D2
         TST.L    D0
         BNE.S    RDW_FERR
         MOVE.L   TXTBASE(A6),A1
         LEA      (A1,D2.L),A2
         CMPA.L   TXTMAX(A6),A2
         BHI.S    RDW_BF
         MOVE.L   A2,TXTEND(A6)
         QDOS     FS.LOAD
         TST.L    D0
         BNE.S    RDW_FERR
         QDOS     IO.CLOSE
         BRA.S    GETLNTBL
ED_COOKD BSR      RD_COOKD
         TST.L    D0
         BEQ.S    GETLNTBL
         CMPI.L   #ERR.BO,D0
         BEQ.S    RDW_BF
RDW_FERR MOVE.L   D0,-(A7)
         ERRMSG   {'File I/O error'}
         BRA.S    RDW_CLOS
RDW_BF   MOVE.L   #ERR.BO,-(A7)
         ERRMSG   {'File too large'}
RDW_CLOS QDOS     IO.CLOSE
ED_L_ERR MOVE.L   TXTBASE(A6),A0
         MOVE.L   A0,D0
         IF NE THEN
            QDOS     MT.RECHP
         ENDIF
         MOVE.L   CMDWIN(A6),A0
         PRINT    {' - press any key '}
         MOVEQ    #-1,D3
         QDOS     SD.CURE
         QDOS     IO.FBYTE
         QDOS     SD.CURS
         MOVE.L   (A7)+,D0
         RTS
NEW_WRKF ERRMSG   {'Creating new file '}
         MOVE.L   CMDWIN(A6),A0
         LEA      FILENAME(A6),A1
         MOVE.W   UT_MTEXT,A2
         JSR      (A2)
         MOVE.L   TXTBASE(A6),TXTEND(A6)
GETLNTBL LEA      BLKSTART(A6),A1
         MOVE.L   #-1,(A1)+         CLEAR BLKSTART AND BLKEND
         CLR.L    (A1)+             CLEAR RTLIN1 AND RTLIN2
         CLR.W    (A1)+             CLEAR RTLIN3
         SF       EDIT_LN(A6)
         SF       EDIT_TXT(A6)
         CLR.W    FINDSTR(A6)       MAKE FIND STRING NULL
         BSR      MK_LNTBL
         MOVEQ    #-1,D3
         MOVE.L   TXTWIN(A6),A0
         MOVEQ    #0,D4             X POS ON WINDOW
         MOVEQ    #0,D5             Y POS ON WINDOW
         MOVEQ    #0,D6             COLUMN
         MOVEQ    #0,D7             LINE
         LEA      LINEBUF(A6),A3
         MOVE.L   TXTBASE(A6),A4
         MOVE.B   #LF,CMDBUF(A6)
         MOVEQ    #0,D0
         RTS

* Read a file in "Cooked" mode

RD_COOKD MOVE.L   TXTBASE(A6),A1
         MOVE.L   A1,TXTEND(A6)
         MOVEQ    #-1,D3
RDC_LOOP TST.B    TABCOMPR(A6)
         BNE.S    RDC_DIR
         TST.B    TABEXPND(A6)
         BNE.S    RDC_EXP
RDC_DIR  MOVE.L   TXTMAX(A6),D2
         SUB.L    A1,D2
         BLS      RDC_BO
         CMPI.L   #$7FFF,D2
         BLS.S    RDC_DIR2
         MOVE.L   #$7FFF,D2
RDC_DIR2 QDOS     IO.FLINE
         TST.L    D0
         BNE.S    RDC_END
         SUBA.W   D1,A1
         SUBQ.W   #1,D1
         BLE.S    RDC_DIRN
         CMPI.B   #CR,-1(A1,D1.W)
         BNE.S    RDC_COMP
         SUBQ.W   #1,D1
RDC_COMP BSR      CMPTABS
RDC_DIRN ADDA.W   D1,A1
         MOVE.B   #LF,(A1)+
         MOVE.L   A1,TXTEND(A6)
         BRA      RDC_DIR
RDC_EXP  MOVE.L   A1,A3
RDC_EXPL LEA      LINEBUF(A6),A1
         MOVE.W   #255,D2
         MOVEQ    #-1,D3
         QDOS     IO.FLINE
         CMPI.L   #ERR.BO,D0
         BEQ.S    RDC_EXP3
         TST.L    D0
         BNE.S    RDC_END
RDC_EXP2 CMPI.W   #1,D1
         BLE.S    RDC_EXP3
         CMPI.B   #CR,-2(A1)
         BNE.S    RDC_EXP3
         MOVE.B   -(A1),-1(A1)
         SUBQ.W   #1,D1
RDC_EXP3 MOVE.L   A1,D2
         SUBA.W   D1,A1
         MOVE.L   TXTMAX(A6),D3
         SUB.L    A3,D3
         BLE.S    RDC_BO
         BSR      CL_COPY
         SUB.L    A1,D2
         BNE.S    RDC_BO
         MOVE.L   A3,TXTEND(A6)
         BRA      RDC_EXPL
RDC_BO   MOVEQ    #ERR.BO,D0
RDC_END  CMPI.L   #ERR.EF,D0
         BNE.S    RDC_RTS
         MOVEQ    #0,D0
RDC_RTS  RTS

P_MIDDLE MOVE.W   (A1)+,D2
         BEQ.S    PM_END
         MOVE.L   A1,A2
         SUBQ.W   #8,A7
         MOVE.L   A7,A1
         QDOS     SD.CHENQ
         MOVE.W   (A7),D1
         ADDQ.W   #8,A7
         SUB.W    D2,D1
         LSR.W    #1,D1
         QDOS     SD.TAB
         MOVE.L   A2,A1
         QDOS     IO.SSTRG
         MOVEQ    #LF,D1
         QDOS     IO.SBYTE
         MOVEQ    #3,D0
         ADD.W    -(A2),D0
         BCLR     #0,D0
         LEA      (A2,D0.W),A1
         BRA      P_MIDDLE
PM_END   RTS

         SECTION  MSG
SIGNON1  STRING$  {'QED'}
         DC.W     0
SIGNON2  STRING$  {'QL Text Editor'}
         STRING$  {'Version [version]'}
         STRING$  {'Copyright  1988-93 by Jan Bredenbeek'}
         STRING$  {'Hilversum, Holland'}
         DC.W     0
         SECTION  CODE

         XDEF     MAIN_ERR

MAIN_ERR MOVE.L   ERR_SP(A6),A7
MAINLOOP MOVE.L   TXTWIN(A6),A0
         MOVE.W   D4,D1
         MOVE.W   D5,D2
         MOVEQ    #-1,D3
         QDOS     SD.POS
         TST.B    MSGPRNTD(A6)
         IF EQ THEN
            BSR      DISPSTAT
         ENDIF
         MOVEQ    #0,D3
         QDOS     IO.PEND
         MOVEQ    #-1,D3
         TST.L    D0
         BEQ.S    MAIN_KEY
         QDOS     SD.CURE
MAIN_KEY QDOS     IO.FBYTE
         SF       MSGPRNTD(A6)
         MOVE.B   D1,D2
         QDOS     SD.CURS
         MOVE.B   D2,D1
         CMPI.B   #TAB,D1
         BEQ.S    MAINCTRL
         CMPI.B   #LF,D1
         BEQ.S    MAINCTRL
         CMPI.B   #$BF,D1
         BLS.S    ENT_CHR
         CMPI.B   #$FC,D1           Shift-SPACE
         BEQ.S    SH_SPACE
MAINCTRL LEA      KEYTBL-2,A1
LOOK_KEY ADDQ.W   #2,A1
         MOVE.W   (A1)+,D0
         BEQ      MAINLOOP
         CMP.B    D0,D1
         BNE      LOOK_KEY
         ADDA.W   (A1),A1
         JSR      (A1)
         BRA      MAINLOOP
SH_SPACE MOVEQ    #' ',D1
ENT_CHR  BSR      COPYLINE
         TST.B    WORDWRAP(A6)
         BEQ      NO_WRAP
         CMP.W    RIGHTMAR(A6),D6
         BNE      NO_WRAP
         MOVE.W   D6,D0
         CMPI.B   #' ',D1
         BEQ.S    WRAP_NL
WRAP_FSP CMPI.B   #' ',-1(A3,D0.W)
         BEQ.S    WRAP_NL
         SUBQ.W   #1,D0
         BNE      WRAP_FSP
         BRA.S    NO_WRAP
WRAP_NL  MOVE.W   D6,D2
         SUB.W    D0,D2
         SUB.W    D2,D4
         MOVE.W   D0,D6
         MOVE.W   D6,LINELEN(A6)
         MOVE.B   D1,-(A7)
         MOVE.W   D2,D1
         ADDQ.W   #1,D2
         BCLR     #0,D2
         SUBA.W   D2,A7
         MOVE.L   A7,A1
         MOVE.W   D1,D0
         BRA.S    WRAP_SVE
WRAP_SVL MOVE.B   (A3,D6.W),(A1)+
         ADDQ.W   #1,D6
WRAP_SVE DBF      D0,WRAP_SVL
         MOVE.W   LINELEN(A6),D6
         MOVEM.W  D1-D2,-(A7)
         MOVE.W   D4,D1
         IF LT THEN
            MOVEQ    #0,D1
         ENDIF
         QDOS     SD.TAB
         QDOS     SD.CLRRT
         BSR      NEWLINE
         BSR      COPYLINE
         MOVE.W   D4,D1
         MOVE.W   D5,D2
         QDOS     SD.POS
         MOVE.W   (A7)+,D2
         LEA      2(A7),A1
         BRA.S    WRAP_RSE
WRAP_RSL MOVE.B   (A1)+,D1
         BSR.S    ADDCHR
WRAP_RSE DBF      D2,WRAP_RSL
         ADDA.W   (A7)+,A7
         MOVE.B   (A7)+,D1
         CMPI.B   #' ',D1
         BEQ      MAINLOOP
NO_WRAP  BSR.S    ADDCHR
         BRA      MAINLOOP

         XDEF     ADDCHR

ADDCHR   MOVEM.L  D2/A1,-(A7)
         MOVE.W   LINELEN(A6),D2
         CMPI.W   #254,D2
         BGE.S    ADDC_ERR
         CMPI.W   #254,D6
         BGE.S    ADDC_ERR
         LEA      (A3,D6.W),A1
         SUB.W    D6,D2
         BEQ.S    ST_CHAR
         BGT.S    AC_MOVE
         NEG.W    D2
         ADD.W    D2,LINELEN(A6)
         SUBA.W   D2,A1
AC_FILSP MOVE.B   #' ',(A1)+
         SUBQ.W   #1,D2
         BNE      AC_FILSP
         BRA.S    ST_CHAR
AC_MOVE  TST.B    OVERWMOD(A6)
         BNE.S    OV_CHAR
         ADDA.W   D2,A1
         MOVE.W   D2,D0
ADDC_LP  MOVE.B   -(A1),1(A1)
         SUBQ.W   #1,D0
         BNE      ADDC_LP
ST_CHAR  ADDQ.W   #1,LINELEN(A6)
OV_CHAR  MOVE.B   D1,(A1)
         TST.W    D2
         BEQ.S    ADDC_PR2
         TST.B    OVERWMOD(A6)
         BNE.S    ADDC_PR2
         BSR      DSP_BUF
         BRA.S    ADDC_END
ADDC_PR2 MOVE.B   D1,-(A7)
         MOVE.W   D4,D1
         MOVE.W   D5,D2
         QDOS     SD.POS
         MOVE.B   (A7)+,D1
         QDOS     IO.SBYTE
ADDC_END BSR      RIGHT
         MOVEM.L  (A7)+,D2/A1
         RTS
ADDC_ERR BSR.S    LIN2LONG
         MOVEM.L  (A7)+,D2/A1
         RTS
LIN2LONG ERRMSG   {'Line too long'}
         RTS

KEYTBL   DC.W     K_TAB
         DC.W     DO_TAB-*
         DC.W     K_ENTER
         DC.W     NEWLINE-*
         DC.W     K_ESC
         DC.W     UNDO-*
         DC.W     K_LEFT
         DC.W     LEFT-*
         DC.W     K_LEFT+K.ALT
         DC.W     ALEFT-*
         DC.W     K_LEFT+K.CTRL
         DC.W     CLEFT-*
         DC.W     K_LEFT+K.CTRL+K.ALT
         DC.W     CALEFT-*
         DC.W     K_LEFT+K.SHIFT
         DC.W     SLEFT-*
         DC.W     K_LEFT+K.SHIFT+K.ALT
         DC.W     TOP_SCR-*
         DC.W     K_LEFT+K.SHIFT+K.CTRL
         DC.W     SCLEFT-*
         DC.W     K_RIGHT
         DC.W     RIGHT-*
         DC.W     K_RIGHT+K.ALT
         DC.W     ARIGHT-*
         DC.W     K_RIGHT+K.CTRL
         DC.W     CRIGHT-*
         DC.W     K_RIGHT+K.CTRL+K.ALT
         DC.W     CARIGHT-*
         DC.W     K_RIGHT+K.SHIFT
         DC.W     SRIGHT-*
         DC.W     K_RIGHT+K.SHIFT+K.ALT
         DC.W     BOT_SCR-*
         DC.W     K_RIGHT+K.SHIFT+K.CTRL
         DC.W     SCRIGHT-*
         DC.W     K_UP
         DC.W     UP-*
         DC.W     K_UP+K.ALT
         DC.W     AUP-*
         DC.W     K_UP+K.CTRL
         DC.W     CUP-*
         DC.W     K_UP+K.CTRL+K.ALT
         DC.W     CMD_T-*
         DC.W     K_UP+K.SHIFT
         DC.W     SUP-*
         DC.W     K_UP+K.SHIFT+K.ALT         HOME on QPC2 w/ SMSQ keyboard
         DC.W     SAUP-*
         DC.W     K_DOWN
         DC.W     DOWN-*
         DC.W     K_DOWN+K.ALT
         DC.W     ADOWN-*
         DC.W     K_DOWN+K.CTRL
         DC.W     CDOWN-*
         DC.W     K_DOWN+K.CTRL+K.ALT
         DC.W     CMD_B-*
         DC.W     K_DOWN+K.SHIFT
         DC.W     SDOWN-*
         DC.W     K_DOWN+K.SHIFT+K.ALT       END on QPC2 w/ SMSQ keyboard
         DC.W     SADOWN-*
         DC.W     K_F1
         DC.W     HELP-*
         DC.W     K_SHF1
         DC.W     CH_AINDT-*
         DC.W     K_F2
         DC.W     REP_CMD-*
         DC.W     K_SHF2
         DC.W     CH_WRDWR-*
         DC.W     K_F3
         DC.W     ENT_CMD-*
         DC.W     K_SHF3
         DC.W     ED_COMLN-*
         DC.W     K_F4
         DC.W     CH_MODE-*
         DC.W     K_SHF4
         DC.W     CH_TABEX-*
         DC.W     K_F5
         DC.W     REFILL-*
         DC.W     $FD               Shift-TAB
         DC.W     SH_TAB-*
         DC.W     0

DO_TAB   MOVEQ    #0,D1
         MOVE.W   D6,D1
         DIVU     TABINC(A6),D1
         SWAP     D1
         NEG.W    D1
         ADD.W    TABINC(A6),D1
         TST.B    OVERWMOD(A6)
         BNE      HCUR
         MOVE.W   D1,D2
         BSR      COPYLINE
TAB_LOOP MOVEQ    #' ',D1
         BSR      ADDCHR
         SUBQ.W   #1,D2
         BNE      TAB_LOOP
TAB_RTS  RTS

SH_TAB   MOVEQ    #0,D1
         MOVE.W   D6,D1
         BEQ      TAB_RTS
         DIVU     TABINC(A6),D1
         SWAP     D1
         TST.W    D1
         IF EQ THEN
            MOVE.W   TABINC(A6),D1
         ENDIF
         NEG.W    D1
         TST.B    OVERWMOD(A6)
         BNE      HCUR
         BSR      COPYLINE
         BRA      BACK_D1

* Handle ENTER-keypress

NEWLINE  TST.B    OVERWMOD(A6)
         BEQ.S    SPLIT_LN          Jump if INSERT mode
         BSR      COPYLINE
         CMP.W    MAXLINE(A6),D7
         BHS.S    SPL_NWLN          But if at end of file, create a new line
NL_LEFT  BSR      ENT_LINE
         BSR      GET_INDT
         SUB.W    D6,D1
         BSR      HCUR
         BRA      DOWN

* Split current line at cursor position

         XDEF     SPLIT_LN

SPLIT_LN BSR      COPYLINE
         BSR      STRIPSPC
         MOVE.W   D1,D2             D2 = line length
         SUB.W    D6,D2             D2 = no. of characters after cursor
         BGE.S    SPL_LLN
SPL_NWLN MOVEQ    #0,D2
SPL_LLN  SUB.W    D2,LINELEN(A6)    Chop off line after cursor
         MOVE.W   LINELEN(A6),-(A7)
         BSR      ENT_LIN1          Enter line + extra LF
         SUBQ.B   #1,(A5,D7.W)      Discount extra LF from line length
         MOVEQ    #1,D1
         BSR      INSRT_LN          Insert extra line entry...
         BLT      MAIN_ERR
         MOVE.B   #1,1(A5,D7.W)     ...initially blank
         BSR      GET_INDT          Get position of new left margin
         ADD.W    D2,D1             D1 = length of remaining line
         CMPI.W   #254,D1
         IF HI THEN
            MOVE.W   #254,D1        Ensure length is OK
         ENDIF
         MOVE.W   (A7)+,D0          Get start of line after cursor
         MOVE.W   D1,LINELEN(A6)    Store new length
         SUB.W    D2,D1             Restore indent position
         MOVEM.W  D1-D2,-(A7)
         TST.W    D2                Any characters to move?
         BEQ.S    SPL_SPC           no
         LEA      (A3,D0.W),A1      Point to first char in buffer
         SUB.W    D0,D1             Subtract "old" from "new" pos
         BEQ.S    SPL_SPC           It's already in the right place
         BLT.S    SPL_DOWN          We'll have to move down if <0
         ADDA.W   D2,A1             If >0, move up
SPL_UP   MOVE.B   -(A1),(A1,D1.W)
         SUBQ.W   #1,D2
         BGT      SPL_UP
         BRA.S    SPL_SPC
SPL_DOWN MOVE.B   (A1)+,-1(A1,D1.W)
         SUBQ.W   #1,D2
         BGT      SPL_DOWN
SPL_SPC  MOVE.W   (A7),D1           Finally insert the spaces now
         BEQ.S    SPL_TAS           ...if any
         MOVE.L   A3,A1
SPL_SPCL MOVE.B   #' ',(A1)+
         SUBQ.W   #1,D1
         BGT      SPL_SPCL
SPL_TAS  TAS      EDIT_LN(A6)       Signal "line is in buffer"
         TST.W    2(A7)
         IF NE THEN
            QDOS     SD.CLRRT       and clear any chars right from the cursor
         ENDIF
         MOVEM.W  (A7)+,D1-D2
         SUB.W    D6,D1             Find how many columns to move cursor
         BSR.S    HCUR
         MOVE.W   D5,D1
         ADDQ.W   #1,D1             Go one line down on the screen
         CMP.W    WINLEN(A6),D1
         BGE.S    SPL_SCUP          ...unless we're already at the bottom
         MOVE.W   D1,D5
         MOVEQ    #10,D1            But if not, scroll remaining part down
         QDOS     SD.SCRBT
         BRA.S    SPL_DLIN
SPL_SCUP MOVEQ    #-10,D1           We're at the bottom so scroll up
         QDOS     SD.SCROL
         MOVEQ    #0,D0
         SUB.W    D5,D7
         MOVE.B   (A5,D7.W),D0
         ADD.W    D5,D7
         ADDA.L   D0,A4             ...and adjust top line pointer
SPL_DLIN ADDQ.W   #1,D7             Go to next line
         BRA      DSP_BUF           ...and finally display the new line

         XDEF     UNDO

UNDO     SF       EDIT_LN(A6)
         SUB.W    D4,D6
         MOVE.W   D4,-(A7)
         MOVEQ    #0,D4
         BSR      GETSCRLN
         BSR      DSP_LINE
         QDOS     SD.CLRRT
         MOVE.W   (A7)+,D4
         ADD.W    D4,D6
         RTS

         XDEF     LEFT,ALEFT,SLEFT,RIGHT,ARIGHT,SRIGHT

LEFT     MOVEQ    #-1,D1
         BRA.S    HCUR
ALEFT    MOVE.W   D6,D1
         NEG.W    D1
         BRA.S    HCUR
SLEFT    BSR.S    WORDLEFT
         BRA.S    HCUR
RIGHT    MOVEQ    #1,D1
         BRA.S    HCUR
ARIGHT   BSR      COPYLINE
         BSR      STRIPSPC
         SUB.W    D6,D1
         BRA.S    HCUR
SRIGHT   BSR.S    WORDRGHT

* This is the common entry point for all horizontal cursor operations. D1 
* holds the number of columns to move left (< 0) or right (> 0).

HCUR     MOVE.W   D1,-(A7)
         SUB.W    D6,D4
         ADD.W    D1,D6
         BLT.S    HCUR_L
         CMPI.W   #254,D6
         BLE.S    HCUR_2
         MOVE.W   #254,D6
         BRA.S    HCUR_2
HCUR_L   MOVEQ    #0,D6
HCUR_2   ADD.W    D6,D4
         BLT.S    HCUR_SL
         CMP.W    WINWID(A6),D4
         BLT.S    HCUR_END
         MOVEQ    #-10,D4
         ADD.W    WINWID(A6),D4
         BRA.S    HCUR_3
HCUR_SL  MOVEQ    #10,D4
HCUR_3   CMP.W    D4,D6
         BGE.S    HCUR_4
         MOVE.W   D6,D4
HCUR_4   BSR      DSP_PAGE
HCUR_END MOVE.W   (A7)+,D1
         RTS

WORDINIT BSR      COPYLINE
         BSR      STRIPSPC
         MOVE.W   D6,D0
         CMP.W    D1,D0
         BLE.S    WI_END
         MOVE.W   D1,D0
WI_END   MOVEQ    #' ',D2
         RTS

WORDLEFT BSR      WORDINIT
WL_LOOP1 SUBQ.W   #1,D0
         BLE.S    WL_LEFT
         CMP.B    (A3,D0.W),D2
         BEQ      WL_LOOP1
WL_LOOP2 CMP.B    -1(A3,D0.W),D2
         BEQ.S    WORD_END
         SUBQ.W   #1,D0
         BGT      WL_LOOP2
WL_LEFT  MOVEQ    #0,D0
         BRA.S    WORD_END
WORDRGHT BSR      WORDINIT
WR_LOOP1 CMP.W    D1,D0
         BEQ.S    WORD_END
         CMP.B    (A3,D0.W),D2
         BEQ.S    WR_LOOP2
         ADDQ.W   #1,D0
         BRA      WR_LOOP1
WR_LOOP2 ADDQ.W   #1,D0
         CMP.W    D1,D0
         BEQ.S    WORD_END
         CMP.B    (A3,D0.W),D2
         BEQ      WR_LOOP2
WORD_END MOVE.W   D0,D1
         SUB.W    D6,D1
         RTS

CLEFT    BSR      COPYLINE
         MOVEQ    #-1,D1
         BRA.S    TESTJOIN
SCLEFT   BSR      WORDLEFT
TESTJOIN TST.W    D6
         BEQ.S    DEL_JOIN
BACK_D1  BSR      HCUR
         NEG.W    D1
         BRA.S    DEL_D1

         XDEF     CRIGHT,SCRIGHT,DEL_D1

CRIGHT   BSR      COPYLINE
         MOVEQ    #1,D1
         BRA.S    DEL_D1
CARIGHT  BSR      COPYLINE
         MOVE.W   LINELEN(A6),D1
         SUB.W    D6,D1
         BRA.S    DEL_D1
SCRIGHT  BSR      WORDRGHT
DEL_D1   MOVE.W   LINELEN(A6),D0
         SUB.W    D6,D0
         BLE.S    DC_END
         SUB.W    D1,D0
         IF LT THEN
            MOVEQ    #0,D0
         ENDIF
         MOVE.W   D0,LINELEN(A6)
         ADD.W    D6,LINELEN(A6)
         LEA      (A3,D6.W),A1
         BRA.S    DC_MVE
DC_MVL   MOVE.B   (A1,D1.W),(A1)+
DC_MVE   DBF      D0,DC_MVL
         BSR      DSP_BUF
         QDOS     SD.CLRRT
         BSR      STRIPSPC
DC_END   RTS

         XDEF     JOIN_LN

DEL_JOIN TST.W    D7
         BEQ      TOP_FILE
         BSR      UP
JOIN_LN  CMP.W    MAXLINE(A6),D7
         BEQ.S    JOIN_END
         BSR      ARIGHT
         BSR      ENT_LINE
         BSR      GETSCRLN
         MOVE.L   A1,-(A7)
         MOVEQ    #0,D2
         MOVE.B   (A5,D7.W),D2
         SUBQ.B   #1,D2
         ADDA.W   D2,A1
         ADD.B    1(A5,D7.W),D2
         BCS.S    JL_2LONG
         MOVEQ    #-1,D1
         BSR      MOV_TXT
         MOVEQ    #1,D1
         BSR      DEL_LNTB
         MOVE.B   D2,(A5,D7.W)
         MOVE.L   (A7)+,A1
         BSR      DSP_LINE
         MOVEQ    #-10,D1
         QDOS     SD.SCRBT
         BSR.S    DSPBOTLN
JOIN_END RTS
JL_2LONG ADDQ.L   #4,A7
         BRA      LIN2LONG

         XDEF     CALEFT

CALEFT   SF       EDIT_LN(A6)
         BSR      GETSCRLN
         TST.W    MAXLINE(A6)
         BNE.S    DELL_1
         MOVE.B   #LF,(A1)+
         MOVE.L   A1,TXTEND(A6)
         MOVE.B   #1,(A5,D7.W)
         QDOS     SD.CLRLN
         RTS
DELL_1   MOVEQ    #0,D1
         MOVE.B   (A5,D7.W),D1
         NEG.L    D1
         BSR      MOV_TXT
         MOVEQ    #1,D1
         BSR      DEL_LNTB
         CMP.W    MAXLINE(A6),D7
         BLE.S    DELL_2
         QDOS     SD.CLRLN
         BRA.S    UP
DELL_2   QDOS     SD.PROW
         MOVEQ    #-10,D1
         TST.L    D0
         BNE.S    DELL_3
         QDOS     SD.SCRBT
         QDOS     SD.NROW
         BRA.S    DSPBOTLN
DELL_3   QDOS     SD.SCROL
DSPBOTLN MOVEM.W  D4-D7,-(A7)
         MOVE.W   WINLEN(A6),D0
         SUBQ.W   #1,D0
         SUB.W    D5,D0
         ADD.W    D0,D7
         CMP.W    MAXLINE(A6),D7
         BHI.S    DSPBTEND
         ADD.W    D0,D5
         SUB.W    D4,D6
         MOVEQ    #0,D4
         BSR      GETSCRLN
         BSR      DSP_LINE
DSPBTEND MOVEM.W  (A7)+,D4-D7
         RTS

         XDEF     UP,DOWN

UP       BSR      ENT_LINE
         TST.W    D5
         BEQ.S    SCROL_UP
         SUBQ.W   #1,D5
         SUBQ.W   #1,D7
         RTS
DOWN     BSR      ENT_LINE
         MOVE.W   D5,D1
         ADDQ.W   #1,D1
         CMP.W    WINLEN(A6),D1
         BGE.S    SCROL_DN
         CMP.W    MAXLINE(A6),D7
         BEQ      END_FILE
         MOVE.W   D1,D5
         ADDQ.W   #1,D7
         MOVEQ    #0,D0
         RTS

AUP      MOVE.B   ARROWCMD,D0
         BNE      PAGE_UP
         BRA.S    SCROL_UP
SAUP     MOVE.B   ARROWCMD,D0       HOME on QPC2 w/ SMSQ/E keyboard
         BEQ      ALEFT
SCROL_UP CMP.W    D5,D7
         BEQ.S    TOP_FILE
         BSR      ENT_LINE
         MOVEQ    #10,D1
         QDOS     SD.SCROL
         MOVEM.W  D4-D6,-(A7)
         SUB.W    D5,D7
         SUBQ.W   #1,D7
         MOVEQ    #0,D0
         MOVE.B   (A5,D7.W),D0
         SUBA.W   D0,A4
         SUB.W    D4,D6
         MOVEQ    #0,D4
         MOVEQ    #0,D5
         MOVE.L   A4,A1
         BSR      DSP_LINE
         MOVEM.W  (A7)+,D4-D6
         ADD.W    D5,D7
         RTS
TOP_FILE ERRMSG   {'Top of file'}
         BRA      MAIN_ERR

ADOWN    MOVE.B   ARROWCMD,D0
         BNE      PAGE_DWN
         BRA.S    SCROL_DN
SADOWN   MOVE.B   ARROWCMD,D0       END on QPC2 w/ SMSQ/E keyboard
         BEQ      ARIGHT
SCROL_DN MOVE.W   WINLEN(A6),D0
         SUB.W    D5,D0
         MOVE.W   D7,D1
         ADD.W    D0,D1
         CMP.W    MAXLINE(A6),D1
         BHI.S    END_FILE
         BSR      ENT_LINE
         MOVEQ    #-10,D1
         QDOS     SD.SCROL
         MOVE.W   D7,D1
         SUB.W    D5,D1
         ADDQ.W   #1,D7
         MOVEQ    #0,D0
         MOVE.B   (A5,D1.W),D0
         ADDA.W   D0,A4
         BSR      DSPBOTLN
         MOVEQ    #-1,D0
         RTS
         XDEF     END_FILE
END_FILE ERRMSG   {'End of file'}
         BRA      MAIN_ERR

SUP      MOVE.B   ARROWCMD,D0
         BEQ.S    PAGE_UP
TOP_SCR  BSR      ENT_LINE
         SUB.W    D5,D7
         MOVEQ    #0,D5
         BRA      ALEFT
PAGE_UP  BSR      ENT_LINE
         MOVEQ    #0,D2
         SUB.W    D5,D7
         MOVE.W   D7,D1
         ADDQ.W   #1,D1
         SUB.W    WINLEN(A6),D1
         BPL.S    SHFT_FND
         MOVEQ    #0,D1
         MOVEQ    #-1,D2
         BRA.S    SHFT_FND

SDOWN    MOVE.B   ARROWCMD,D0
         BEQ.S    PAGE_DWN
BOT_SCR  BSR      ENT_LINE
         MOVE.W   WINLEN(A6),D1
         SUB.W    D5,D1
         SUBQ.W   #1,D1
         ADD.W    D7,D1
         CMP.W    MAXLINE(A6),D1
         IF HI THEN
            MOVE.W   MAXLINE(A6),D1
         ENDIF
         SUB.W    D7,D1
         ADD.W    D1,D5
         ADD.W    D1,D7
         BRA      ARIGHT
PAGE_DWN BSR      ENT_LINE
         MOVEQ    #0,D2
         MOVE.W   WINLEN(A6),D0
         SUBQ.W   #1,D0
         SUB.W    D5,D7
         MOVE.W   D7,D1
         ADD.W    D0,D1
         ADD.W    D0,D1
         CMP.W    MAXLINE(A6),D1
         BLS.S    SHFT_SUB
         MOVEQ    #1,D2
         MOVE.W   MAXLINE(A6),D1
SHFT_SUB SUB.W    D0,D1
         BGE.S    SHFT_FND
         MOVEQ    #0,D1
SHFT_FND MOVE.W   D5,-(A7)
         MOVEQ    #0,D5
         BSR      FINDLINE
         MOVE.W   (A7)+,D5
         MOVE.L   A1,A4
         MOVE.W   D1,D7
         ADD.W    D5,D7
         BSR      DSP_PAGE
         TST.B    D2
         BLT      TOP_FILE
         BGT      END_FILE
         RTS

         XDEF     CH_MODE,CH_AINDT,CH_WRDWR,CH_TABCP,CH_TABEX

CH_MODE  MOVE.W   #OVERWMOD,D0
         BRA.S    CH_VAR
CH_AINDT MOVE.W   #AUTOINDT,D0
         BRA.S    CH_VAR
CH_WRDWR MOVE.W   #WORDWRAP,D0
         BRA.S    CH_VAR
CH_TABCP MOVE.W   #TABCOMPR,D0
         BRA.S    CH_VAR
CH_TABEX MOVE.W   #TABEXPND,D0
CH_VAR   NOT.B    (A6,D0.W)
         BRA.S    RES_STAT

REFILL   MOVE.B   BORD_PRM,D1
         MOVEQ    #0,D2
         MOVE.B   BORD_PRM+1,D2
         MOVE.L   GUARDWIN(A6),A0
         QDOS     SD.BORDR
         BSR      NEXT_ENV
         BSR      DSP_PAGE
RES_STAT SF       STPRINTD(A6)
         RTS

HELP     ERRMSG   {'Loading HELP file...'}
         LEA      HELPFNAM,A0
         MOVEQ    #1,D3
         BSR      OPEN_DEF
         BNE      HELP_ERR
         MOVE.L   A0,A2
         MOVE.L   TXTWIN(A6),A0
         MOVEQ    #-1,D3
         QDOS     SD.CLEAR
         MOVE.B   CSIZE,D0
         IF NE THEN
            MOVEQ    #1,D1
            MOVEQ    #0,D2
            QDOS     SD.SETSZ
         ENDIF
         SUBA.W   #84,A7
         MOVE.L   A7,A1
         QDOS     SD.CHENQ
HELP_LP  MOVE.W   WINLEN(A6),2(A7)
HELP_LN  EXG      A0,A2
         MOVEQ    #80,D2
         LEA      4(A7),A1
         QDOS     IO.FLINE
         EXG      A0,A2
         TST.L    D0
         BNE.S    HELP_END
         MOVE.W   D1,D2
         SUBQ.W   #1,D2
         CMP.W    (A7),D2
         BLE.S    HELP_DSP
         MOVE.W   (A7),D2
HELP_DSP LEA      4(A7),A1
         QDOS     IO.SSTRG
         MOVEQ    #LF,D1
         QDOS     IO.SBYTE
         SUBQ.W   #1,2(A7)
         BGT      HELP_LN
         ERRMSG   {'Any key to continue or ESC to exit '}
         SF       MSGPRNTD(A6)
         MOVE.L   A0,-(A7)
         MOVE.L   CMDWIN(A6),A0
         QDOS     SD.CURE
         QDOS     IO.FBYTE
         MOVE.B   D1,D2
         QDOS     SD.CURS
         QDOS     SD.CLEAR
         MOVE.L   (A7)+,A0
         CMPI.B   #K_ESC,D2
         BNE      HELP_LP
         BRA.S    HELP_CL
HELP_END BSR      RET_KEY
HELP_CL  ADDA.W   #84,A7
         EXG      A0,A2
         QDOS     IO.CLOSE
         MOVE.B   CSIZE,D1
         MOVEQ    #0,D2
         MOVEQ    #-1,D3
         MOVE.L   TXTWIN(A6),A0
         QDOS     SD.SETSZ
         BRA      DSP_PAGE
HELP_ERR ERRMSG   {'Can''t find HELP file'}
         BRA      MAIN_ERR

         END
