* QED TEXT EDITOR by Jan Bredenbeek
* Start: 27 June 1988
* Release 1.00: August 1988
* Release 1.01: September 1988 (stable)
* Release 2.00b1: September 1994 (UNSTABLE!)
* Release 2.00b2: January 2018
* Release 2.01  : 25 September 2018
* Release 2.02  : 03 October 2018
* Release 2.03  : 26 May 2021
* Release 2.03a : 28 May 2021
* Licenced under GPL v3 Licence (2017)
* See https://github.com/janbredenbeek/QED for latest version from the author
* This should be assembled and linked using the QMAC Macro Assembler and Linker
* (see http://www.dilwyn.me.uk/asm/index.html)
*
* Main program part

         INCLUDE  WIN1_MACRO_LIB             Macro definitions
         INCLUDE  WIN1_QDOS_IN_MAC           QDOS definitions
         INCLUDE  WIN3_QEDv2_QED_IN          QED Definitions

* External references         
         
         XREF     MK_LNTBL,INSRT_LN,DEL_LNTB,ENT_LINE,GETSCRLN,MOV_TXT
         XREF     STRIPSPC,COPYLINE,DSP_PAGE,DSP_BUF,DSP_LINE,OPEN_DEF
         XREF     ERRMSG,DISPSTAT,ITOD,READNUM,FINDLINE,EL_ERR,FIND_DSP
         XREF     ENT_LIN1,DS_NUM,DS_NUM1,FIND_DS1,NO_LNTBL,NEXT_ENV
         XREF     REP_CMD,ENT_CMD,ED_COMLN,SKIPSPC,UCASETBL,CUP,CDOWN
         XREF     GET_INDT,RET_KEY,CMD_T,CMD_B,CMPTABS,CL_COPY

* Start of main code         
         
         SECTION  CODE

         BRA.L    ED_START          ; long branch now! (v2.03+)
         DC.W     0                 ; NEW: config version (v2.03+)
         DC.W     $4AFB
         STRING$  {'QED'}
         DS.W     0                 Get the following data word aligned
         
* Configuration data (modified by QEDCONFIG_BAS)
         
WINDEF   DC.W     480,200,16,5      (14-21) Outline window
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
DEFWIN   DC.W     480,200,16,5      ; Default window size if configured fails

         XDEF     REPORT_P,REPORT_I,CMDLN_P,CMDLN_I

* Skip spaces on command line
* D0: remaining length, A0 ptr to current character

SKIPCMD  TST.W    D0
         BLE.S    SK_END
         CMPI.B   #' ',(A0)
         BHI.S    SK_END
         SUBQ.W   #1,D0
         ADDQ.L   #1,A0
         BRA      SKIPCMD
SK_END   TST.W    D0
         RTS

; SD.EXTOP routine to get SD.YINC. Do not assume it's 10!

GET_YINC MOVE.W   $28(A0),D1
         MOVEQ    #0,D0
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
         LEA      WINDEF,A2       ; Configured window size
         SUBQ.W   #8,A7             ; Temp space for window parms
WIN_AGN  MOVE.L   A7,A1
         MOVE.L   (A2),(A1)+        ; Window LHS x,y
         MOVE.L   4(A2),(A1)+       ; Window size
         MOVE.W   D2,D0             ; Border size
         SUB.W    D0,-(A1)          ; Discount border size from window LHS y
         ADD.W    D0,D0             ; Border width = 2 times size
         SUB.W    D0,-(A1)          ; Discount border width from window LHS x
         ADD.W    D0,-(A1)          ; Add border height * 2 to window height
         ADD.W    D0,D0             ; Double again to get total border width
         ADD.W    D0,-(A1)          ; And add this to window width
         MOVEQ    #-1,D3
         QDOS     SD.WDEF           ; Now define guardian window size & pos
         TST.L    D0                ; test for error
         BEQ.S    SET_BORD          ; if OK, continue
         MOVE.L   D0,D3             ; error code to D3
         CMPI.L   #ERR.OR,D3        ; 'Out of range'?
         BNE      EXIT_ERR          ; Exit if other error
         MOVEQ    #4,D1             ; Use default green border
         MOVEQ    #1,D2             ; ... with a width of 1 pixel
         LEA      DEFWIN,A2         ; Default window which WILL fit in 512x256
         BRA      WIN_AGN           ; ... and try again

SET_BORD MOVE.B   BORD_PRM+2,D1     ; Get paper colour for guardian window
         QDOS     SD.SETPA
         MOVE.B   BORD_PRM+2,D1     ; Again for strip colour
         QDOS     SD.SETST
         MOVE.B   BORD_PRM+3,D1     ; And ink colour
         QDOS     SD.SETIN

; Now open main editing window         
         
         MOVEQ    #-1,D1
         MOVEQ    #0,D3
         LEA      CONNAME,A0
         QDOS     IO.OPEN
         MOVE.L   D0,D3
         BNE      EXIT_ERR
         MOVE.L   A0,TXTWIN(A6)     ; channel ID
         MOVE.L   (A2),(A7)         ; copy definition from guardian window parms
         MOVE.L   4(A2),4(A7)
         MOVE.B   CSIZE,D1
         MOVEQ    #0,D2
         MOVEQ    #-1,D3
         QDOS     SD.SETSZ          ; set character size (only width)
         LEA      GET_YINC,A2       ; get character height in pixels
         QDOS     SD.EXTOP
         MOVE.W   D1,CH_YINC(A6)    ; set variable
         SUB.W    D1,2(A7)          ; subtract 1 row to allow for status line
         MOVEQ    #0,D1             ; no border
         MOVEQ    #0,D2
         MOVE.L   A7,A1
         QDOS     SD.WDEF           ; set size/position
         SUBQ.W   #8,A7
         MOVE.L   A7,A1
         QDOS     SD.CHENQ          ; get width/height in characters
         MOVE.L   (A7)+,WINWID(A6)  ; store width and height
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
         MOVE.W   CH_YINC(A6),2(A7) ; just one text line...
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
         MOVE.L   DEFMARGN,LEFTMAR(A6)  ; left margin AND right margin
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
         SF       COOKED(A6)
ED_CMDLP BSR      SKIPCMD           ; Skip spaces
         BLE.S    ED_CMDEN          ; End of command string reached
         CMPI.B   #'-',(A0)         ; Options start with '-'
         BEQ.S    ED_CMDOP
         CMPI.B   #'/',(A0)         ; or '/'
         BEQ.S    ED_CMDOP          ; Jump if option found
         TST.B    D1
         BNE.S    ED_FORK           ; But if new filename, start off current
         ST       D1                ; Signal "Filename found"
ED_CMDOP MOVE.B   (A0),(A1)+        ; Copy into cmdbuf
         SUBQ.W   #1,D0             ; Decrement length
         BLE.S    ED_CMDEN          ; Jump if end reached
         CMPI.B   #' ',(A0)+        ; Loop back unless char was a space
         BHI      ED_CMDOP
         BRA      ED_CMDLP
ED_FORK  ST       D2
         MOVE.B   #LF,(A1)+         ; Terminate command line
         MOVEM.L  D0/D2/A0,-(A7)
         BSR      ED_LOAD           ; Load file
         TST.L    D0                ; Loaded one?
         BEQ.S    ED_FORK2          ; yes, fork environment
         MOVEM.L  (A7)+,D0/D2/A0
         BRA      ED_NFILE          ; else look for next file

ED_FORK2 BSR.S    FORK              ; fork environment
         MOVE.L   D0,D3             ; test error status
         MOVEM.L  (A7)+,D0/D2/A0
         BEQ      ED_NFILE          ; if OK, loop back for next file
EXIT_ERR MOVEQ    #-1,D1            ; error exit
         QDOS     MT.FRJOB

ED_CMDEN MOVE.B   #LF,(A1)+         ; end of command line reached, terminate
         BSR      ED_LOAD           ; load last file
         MOVE.L   D0,D3
         BEQ.S    ED_DSP            ; if OK, display it
         TST.L    NEXTFILE(A6)      ; do we have other files?
         BEQ      EXIT_ERR          ; if not, error exit
ED_DSP   BSR      NEXT_ENV          ; switch to next file
         BSR      DSP_PAGE          ; display it
         BRA      MAINLOOP          ; jump to main loop

* Fork off another file

         XDEF     FORK

FORK     BSR.S    SAV_ENV           ; Save current file environment
         BNE.S    F_NOMEM
         MOVE.L   ENVSAV(A6),A2     ; Get ptr to save area
         CLR.L    ENVSAV(A6)
         TST.L    NEXTFILE(A6)
         BNE.S    FORK_2
         MOVE.L   A2,NEXTFILE(A6)   ; If no next file, make current file next
FORK_2   BSR.S    SAV_ENV           ; Create save area for next file
         BNE.S    F_NOMEM2
         MOVE.L   ENVSAV(A6),(A2)   ; And make next file "next" after current
         MOVEQ    #0,D0
         RTS
F_NOMEM2 MOVE.L   A2,ENVSAV(A6)
F_NOMEM  TST.L    D0
         RTS

* Save current file environment. Allocates workspace in CHP if necessary.

         XDEF     SAV_ENV

SAV_ENV  MOVE.L   ENVSAV(A6),A0
         MOVE.L   A0,D0             ; do we already have a save area?
         BNE.S    SE_2              ; yes, copy environment
         MOVE.L   #ENV_END-NEXTFILE+27,D1 ; allow for registers too
         MOVEQ    #-1,D2
         MOVEM.L  A2/A3,-(A7)
         QDOS     MT.ALCHP          ; allocate space for save area
         MOVEM.L  (A7)+,A2/A3
         TST.L    D0
         BNE.S    SE_END
         MOVE.L   A0,ENVSAV(A6)     ; store pointer
SE_2     MOVE.L   #ENV_END-NEXTFILE,D0
         LEA      NEXTFILE(A6),A1
SE_SAV   MOVE.L   (A1)+,(A0)+       ; copy environment to save area
         SUBQ.L   #4,D0
         BGT      SE_SAV
         MOVEM.L  D4-D7/A4-A5,(A0)  ; save registers too (24 bytes)
         MOVEQ    #0,D0
SE_END   RTS

* Commandline option table
* For each option:
*   - First byte: 0 no parameter, -1 nonzero parameter, -2 numeric parameter
*   - Second byte: option letter
*   - Third and fourth byte: variable offset to set

ED_OPTAB 
;        DC.B     -2,'@'            ; Start at line n
;        DC.W     STARTLN
         DC.B     -2,'B'            ; Workspace in KB
         DC.W     WORKSPC
         DC.B     0,'C'             ; Cooked mode
         DC.W     COOKED
         DC.B     0,'E'             ; TAB expansion
         DC.W     TABEXPND
         DC.B     -1,'I'            ; TAB increment (changed!)
         DC.W     TABINC
         DC.B     -2,'O'            ; Workspace overhead
         DC.W     WORKSPOV
;         DC.B     -1,'L'            ; Left margin
;         DC.W     LEFTMAR
;         DC.B     -1,'R'            ; Right margin
;         DC.W     RIGHTMAR
         DC.B     0,'T'             ; TAB compression (changed!)
         DC.W     TABCOMPR
         DC.B     0,'W'
         DC.W     WORDWRAP
         DC.W     0

* Load a complete file
* Filename and options must be in CMDBUF

         XDEF     ED_LOAD

ED_LOAD  SUBA.L   A5,A5             ; No line table yet
         CLR.L    TXTBASE(A6)       ; Pre-set variables
         CLR.W    FILENAME(A6)
         CLR.W    WORKSPC(A6)
         CLR.W    WORKSPOV(A6)
         CLR.W    STARTLN(A6)
         SF       MSGPRNTD(A6)
         SF       STPRINTD(A6)
         LEA      CMDBUF(A6),A2
ED_FNLP  BSR      SKIPSPC           ; Point to next non-space
         BEQ      ED_TSTFN          ; EOL reached
         CMPI.B   #'-',(A2)         ; '-' or '/' marks an option
         BEQ.S    ED_OPT
         CMPI.B   #'/',(A2)
         BEQ.S    ED_OPT
         LEA      FILENAME+2(A6),A1 ; else, it's a filename
         MOVEQ    #0,D0             ; length
ED_FNCP  MOVE.B   (A2)+,(A1)+       ; copy next character
         ADDQ.W   #1,D0             ; bump length counter
         CMPI.B   #' ',(A2)         ; Space or EOL?
         BLS.S    ED_ENDFN          ; Yes, end of name reached
         CMPI.W   #44,D0            ; Allow for max 44 chars
         BLT      ED_FNCP           ; Loop back
;;         MOVE.W   D0,FILENAME(A6) ; ???
         ERRMSG   {'Filename too long - any key to continue '}
         MOVEQ    #ERR.BN,D0
         BRA      ED_L_ERR
ED_ENDFN MOVE.W   D0,FILENAME(A6)   ; Store length
         BRA      ED_FNLP           ; Loop back for next
ED_OPT   ADDQ.L   #1,A2             ; Option found - skip '-' or '/'
         MOVEQ    #0,D1
         MOVE.B   (A2)+,D1          ; Get option letter
         CMPI.B   #LF,D1            ; EOL?
         BEQ.S    ED_TSTFN          ; Go processing filename
         LEA      UCASETBL,A1
         MOVE.B   (A1,D1.W),D1      ; Convert to uppercase
         LEA      ED_OPTAB,A1       ; Option table
ED_OPTLP MOVE.W   (A1)+,D2          ; LSB = letter, MSB = type
         BEQ      ED_FNLP           ; Null means end reached
         MOVE.W   (A1)+,D3          ; Get variable offset
         CMP.B    D1,D2             ; Option letters match?
         BNE      ED_OPTLP          ; No, next table entry
         TST.W    D2                ; A negative type means number follows
         BMI.S    ED_OPT2
         CMPI.B   #'-',(A2)
         SNE      (A6,D3.W)         ; else, (re)set variable
         CMPI.B   #' ',(A2)         ; space or EOL after?
         BLS      ED_FNLP           ; yes, loop back (treat as +)
         ADDQ.L   #1,A2             ; else, skip it
         BRA      ED_FNLP           ; loop back
ED_OPT2  EXG      A1,A2             ; A number follows
         BSR      READNUM
         EXG      A1,A2
         BTST     #8,D2
         BEQ.S    ED_OPT3           ; Type -2 allows any paramater
         TST.W    D1                ; but -1 does not allow zero or negative
         BLE      ED_FNLP
ED_OPT3  MOVE.W   D1,(A6,D3.W)      ; Enter parameter value
         BRA      ED_FNLP           ; Loop for next

ED_TSTFN TST.W    FILENAME(A6)      ; Do we have a file name?
         BNE      OP_WRKFL          ; Yes
         MOVE.L   GUARDWIN(A6),A0   ; else, ask for it
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
         TST.W    WORKSPC(A6)       ; Ask for workspace if needed
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
GETWRK1  CMPI.B   #'K',(A1)
         BEQ.S    GETWRK_K
         CMPI.B   #'k',(A1)
         BNE.S    GETWRK_A
GETWRK_K MULU     #1024,D1
GETWRK_A MOVEQ    #-1,D2
         QDOS     MT.ALCHP
         TST.L    D0
         BEQ.S    GETWRK2
         MOVE.L   GUARDWIN(A6),A0
         PRINT    {'Too large'}
         BRA      GET_WRK
GETWRK2  MOVE.L   A0,TXTBASE(A6)
         LEA      -$10(A0,D1.L),A0
         MOVE.L   A0,TXTMAX(A6)

; Open work file

OP_WRKFL LEA      FILENAME(A6),A0
         MOVEQ    #1,D3             ; existing file
         BSR      OPEN_DEF          ; try opening it
         TST.L    TXTBASE(A6)       ; Workspace already allocated?
         BNE.S    RD_WRKFL          ; Yes
         MOVEM.L  D0/A0,-(A7)       ; else, allocate it
         TST.W    WORKSPC(A6)       ; Explicit workspace size specified?
         BNE.S    OP_DEFLT          ; yes, skip
         TST.L    D0                ; could we open the file?
         BNE.S    OP_DEFLT          ; no, use specified or default
         MOVEQ    #4,D2
         MOVEQ    #-1,D3
         CLR.L    -(A7)
         MOVE.L   A7,A1
         QDOS     FS.HEADR
         MOVE.L   (A7)+,D1          ; file length
         MOVE.W   WORKSPOV(A6),D0   ; specified workspace overhead
         IF EQ THEN
            MOVE.W   DEFWRKOV,D0    ; or take default
         ENDIF
         MULU     #1024,D0          ; convert to KB
         ADD.L    D0,D1             ; add overhead
         BRA.S    OP_ALLOC
OP_DEFLT MOVE.W   WORKSPC(A6),D1    ; specified workspace (-Bn)
         IF EQ THEN
            MOVE.W   DEFWRKSP,D1    ; or take default
         ENDIF
         MULU     #1024,D1          ; convert to KB
OP_ALLOC MOVEQ    #-1,D2
         QDOS     MT.ALCHP
         TST.L    D0
         BEQ.S    SETWRKSP
         ERRMSG   {'No room for workspace'}
         MOVEM.L  (A7)+,D0/A0
         MOVE.L   #ERR.OM,-(A7)     ; signal 'out of memory'
         TST.L    D0                ; file open successful?
         BEQ      RDW_CLOS          ; yes, close it again
         BRA      ED_L_ERR          ; exit
SETWRKSP MOVE.L   A0,TXTBASE(A6)    ; set base of workspace
         LEA      -$10(A0,D1.L),A0  ; allow for 16 bytes spare
         MOVE.L   A0,TXTMAX(A6)     ; End of workspace
         MOVEM.L  (A7)+,D0/A0       ; restore file open status
RD_WRKFL TST.L    D0                ; Existing file?
         BNE      NEW_WRKF          ; No
         MOVE.L   A0,-(A7)          ; else, load it
         ERRMSG   {'Reading '}
         MOVE.L   CMDWIN(A6),A0
         LEA      FILENAME(A6),A1
         MOVE.W   UT_MTEXT,A2
         JSR      (A2)
         SF       MSGPRNTD(A6)
         MOVE.L   (A7)+,A0
         TST.B    COOKED(A6)        ; Cooked flag?
         BNE.S    ED_COOKD          ; Yes
         MOVEQ    #4,D2
         MOVEQ    #-1,D3
         CLR.L    -(A7)
         MOVE.L   A7,A1             ; Read first 4 bytes of header
         QDOS     FS.HEADR
         MOVE.L   (A7)+,D2          ; must be length of file
         TST.L    D0
         BNE.S    RDW_FERR          ; but exit with errors
         MOVE.L   TXTBASE(A6),A1
         LEA      (A1,D2.L),A2
         CMPA.L   TXTMAX(A6),A2     ; does it fit into the buffer?
         BHI.S    RDW_BF            ; no, bail out
         MOVE.L   A2,TXTEND(A6)     ; set TXTEND
         QDOS     FS.LOAD           ; and load the whole file
         TST.L    D0                ; error?
         BNE.S    RDW_FERR          ; yes, report and close
         BRA.S    RDW_OK            ; else close and build line table

ED_COOKD BSR      RD_COOKD          ; read cooked (CR/LF, TAB handling etc)
         CMPI.L   #ERR.BO,D0        ; buffer overflow?
         BEQ.S    RDW_BF            ; yes, report
         TST.L    D0                ; other I/O error?
         BNE.S    RDW_FERR          ; yes, report it
RDW_OK   QDOS     IO.CLOSE          ; FIX: close after cooked read!
         BRA.S    GETLNTBL          ; go building line table

RDW_FERR MOVE.L   D0,-(A7)          ; generic file I/O error
         ERRMSG   {'File I/O error'}
         BRA.S    RDW_CLOS
RDW_BF   MOVE.L   #ERR.BO,-(A7)     ; file too large for buffer
         ERRMSG   {'File too large'}
RDW_CLOS QDOS     IO.CLOSE
ED_L_ERR MOVE.L   TXTBASE(A6),A0
         MOVE.L   A0,D0             ; reclaim any buffer space
         IF NE THEN
            QDOS     MT.RECHP
         ENDIF
         MOVE.L   CMDWIN(A6),A0     ; wait for a key and return
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
         BSR      MK_LNTBL          ; build line table
         MOVEQ    #-1,D3
         MOVE.L   TXTWIN(A6),A0
         MOVEQ    #0,D4             X POS ON WINDOW
         MOVEQ    #0,D5             Y POS ON WINDOW
         MOVEQ    #0,D6             COLUMN
         MOVEQ    #0,D7             LINE
         LEA      LINEBUF(A6),A3
         MOVE.L   TXTBASE(A6),A4    ; A4 points to text
         MOVE.B   #LF,CMDBUF(A6)
         MOVEQ    #0,D0
         RTS

* Read a file in "Cooked" mode (consider TABs and CR/LF)

RD_COOKD MOVE.L   TXTBASE(A6),A1
         MOVE.L   A1,TXTEND(A6)     ; Collapse text buffer
         MOVEQ    #-1,D3
RDC_LOOP TST.B    TABCOMPR(A6)      ; TAB compression on?
         BNE.S    RDC_DIR           ; yes, go ahead
         TST.B    TABEXPND(A6)      ; TAB expansion on?
         BNE.S    RDC_EXP           ; yes, skip to next section
RDC_DIR  MOVE.L   TXTMAX(A6),D2
         SUB.L    A1,D2             ; Check available space
         BLS      RDC_BO            ; out of space
         CMPI.L   #$7FFF,D2
         BLS.S    RDC_DIR2
         MOVE.L   #$7FFF,D2         ; read at most 32767 bytes at a time
RDC_DIR2 QDOS     IO.FLINE          ; read in next line (LF terminated)
         TST.L    D0                ; OK?
         BEQ.S    RDC_DIR3          ; Yes, skip
         CMPI.L   #ERR.EF,D0        ; test for EOF
         BNE      RDC_END           ; exit with other errors
         TST.W    D1                ; zero length?
         BEQ      RDC_END           ; yes, real EOF
         MOVE.B   #LF,(A1)+         ; last line had no EOL, correct this!
         ADDQ.W   #1,D1
RDC_DIR3 SUBA.W   D1,A1             ; go back to start
         SUBQ.W   #1,D1             ; only LF?
         BLE.S    RDC_DIRN          ; yes, skip
         CMPI.B   #CR,-1(A1,D1.W)   ; CR before LF?
         BNE.S    RDC_COMP          ; no
         SUBQ.W   #1,D1             ; discount any CR at end
RDC_COMP BSR      CMPTABS           ; compress any tabs
RDC_DIRN ADDA.W   D1,A1             ; go to new EOL
         MOVE.B   #LF,(A1)+         ; ensure line end has LF
         MOVE.L   A1,TXTEND(A6)     ; set new TXTEND
         BRA      RDC_DIR           ; loop back

; no TAB compression but TAB expansion
; this section reads in via LINEBUF, may need some optimisations later

RDC_EXP  MOVE.L   A1,A3             ; save current pointer
RDC_EXPL LEA      LINEBUF(A6),A1    ; read line in LINEBUF
         MOVE.W   #255,D2
         MOVEQ    #-1,D3
         QDOS     IO.FLINE          ; get next line
         TST.L    D0                ; OK?
         BEQ.S    RDC_EXP2          ; yes, process line
         CMPI.L   #ERR.BO,D0        ; buffer overflow?
         BEQ.S    RDC_EXP3          ; yes, process but no CR check
         CMPI.L   #ERR.EF,D0        ; EOF?
         BNE.S    RDC_END           ; no, other error
         TST.W    D1                ; any bytes read?
         BEQ.S    RDC_END           ; no, real EOF
         MOVE.B   #LF,(A1)+         ; last line had no EOL, correct this
         ADDQ.W   #1,D1
RDC_EXP2 CMPI.W   #1,D1             ; discount EOL
         BLE.S    RDC_EXP3          ; skip with empty line
         CMPI.B   #CR,-2(A1)        ; does it have a CR before LF?
         BNE.S    RDC_EXP3          ; no, skip
         MOVE.B   -(A1),-1(A1)      ; else move the LF down
         SUBQ.W   #1,D1             ; and discount the CR
RDC_EXP3 MOVE.L   A1,D2             ; end of line in LINEBUF
         SUBA.W   D1,A1             ; go back to the start
         MOVE.L   TXTMAX(A6),D3
         SUB.L    A3,D3             ; enough space left?
         BLE.S    RDC_BO            ; no, bail out
         BSR      CL_COPY           ; copy line to text buffer
         SUB.L    A1,D2             ; reached the end of LINEBUF?
         BNE.S    RDC_BO            ; no, line is too long
         MOVE.L   A3,TXTEND(A6)     ; set new TXTEND
         BRA      RDC_EXPL          ; and loop back
RDC_BO   MOVEQ    #ERR.BO,D0        ; buffer full error
RDC_END  CMPI.L   #ERR.EF,D0        ; check for EOF
         BNE.S    RDC_RTS           ; exit with other errors
         MOVEQ    #0,D0             ; cancel EOF, is not an error
RDC_RTS  RTS

*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
* Print a message at the centre of the screen (used for signon)
*--------------------------------------------------------------

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
         STRING$  {'Copyright  1988-2021 by Jan Bredenbeek'}
         DC.W     0
         SECTION  CODE

*++++++++++++++++++++
* Main execution loop
*--------------------

         XDEF     MAIN_ERR

MAIN_ERR MOVE.L   ERR_SP(A6),A7     ; error return, reset SP
MAINLOOP MOVE.L   TXTWIN(A6),A0
         MOVE.W   D4,D1             ; D4 holds column in window
         MOVE.W   D5,D2             ; D5 holds row in window
         MOVEQ    #-1,D3
         QDOS     SD.POS            ; set cursor position
         TST.B    MSGPRNTD(A6)      ; any message printed in status window?
         IF EQ THEN
            BSR      DISPSTAT       ; if not, display regular status
         ENDIF
         MOVEQ    #0,D3
         QDOS     IO.PEND           ; any character pending in input?
         MOVEQ    #-1,D3
         TST.L    D0
         BEQ.S    MAIN_KEY          ; yes, don't print cursor (faster!)
         QDOS     SD.CURE           ; else, enable cursor
MAIN_KEY QDOS     IO.FBYTE          ; now wait for a keypress...
         SF       MSGPRNTD(A6)      ; clear flag
         MOVE.B   D1,D2             ; save keypress
         QDOS     SD.CURS           ; disable cursor again
         MOVE.B   D2,D1             ; now consider keypress

; accept control chars but reject NUL - some keyboards generate this when
; composing accented chars!

         BEQ      MAINLOOP
         CMPI.B   #TAB,D1
         BEQ.S    MAINCTRL
         CMPI.B   #LF,D1
         BEQ.S    MAINCTRL
         CMPI.B   #ESC,D1
         BEQ.S    MAINCTRL          ; lookup any of these codes
         CMPI.B   #$BF,D1           ; printable character?
         BLS.S    ENT_CHR           ; yes
         CMPI.B   #$FC,D1           ; Shift-SPACE?
         BEQ.S    SH_SPACE          ; yes, replace by normal space
MAINCTRL LEA      KEYTBL-2,A1       ; lookup any other codes
LOOK_KEY ADDQ.W   #2,A1             ; next entry
         MOVE.W   (A1)+,D0          ; get code (lower byte)
         BEQ      MAINLOOP          ; zero marks end - loop back
         CMP.B    D0,D1             ; found code?
         BNE      LOOK_KEY          ; no, loop around
         ADDA.W   (A1),A1           ; else, add offset to handler
         JSR      (A1)              ; call handler
         BRA      MAINLOOP          ; and loop for next key

SH_SPACE MOVEQ    #' ',D1           ; replace shift-space with space
ENT_CHR  BSR      COPYLINE          ; copy line to line buffer if needed
         TST.B    WORDWRAP(A6)      ; wordwrap on?
         BEQ      NO_WRAP           ; no, just add character
         CMP.W    RIGHTMAR(A6),D6   ; against right margin?
         BNE      NO_WRAP           ; no, skip
         MOVE.W   D6,D0             ; current column position
         CMPI.B   #' ',D1           ; space typed?
         BEQ.S    WRAP_NL           ; yes, go wrapping
WRAP_FSP CMPI.B   #' ',-1(A3,D0.W)  ; search from current column down for space
         BEQ.S    WRAP_NL
         CMPI.B   #TAB,-1(A3,D0.W)  ; now include TAB too!
         BEQ.S    WRAP_NL
         SUBQ.W   #1,D0             ; go back a column...
         BNE      WRAP_FSP          ; until we hit the start
         BRA.S    NO_WRAP           ; oops... nothing to wrap here!
WRAP_NL  MOVE.W   D6,D2
         SUB.W    D0,D2             ; get number of characters to wrap
         SUB.W    D2,D4             ; go left this number of columns
         MOVE.W   D0,D6             ; set new column in line
         MOVE.W   D6,LINELEN(A6)    ; and new line length
         MOVE.B   D1,-(A7)          ; save current keystroke
         MOVE.W   D2,D1
         ADDQ.W   #1,D2
         BCLR     #0,D2
         SUBA.W   D2,A7             ; make room on stack (evened up!)
         MOVE.L   A7,A1
         MOVE.W   D1,D0
         BRA.S    WRAP_SVE
WRAP_SVL MOVE.B   (A3,D6.W),(A1)+   ; save text to be wrapped on stack
         ADDQ.W   #1,D6
WRAP_SVE DBF      D0,WRAP_SVL
         MOVE.W   LINELEN(A6),D6    ; new line length
         MOVEM.W  D1-D2,-(A7)       ; save lengths (original + evened up)
         MOVE.W   D4,D1
         IF LT THEN
            MOVEQ    #0,D1
         ENDIF
         QDOS     SD.TAB            ; set cursor to last whitespace on window
         QDOS     SD.CLRRT          ; and clear the columns on the right of it
         BSR      NEWLINE           ; insert newline
         BSR      COPYLINE          ; copy line to buffer
         MOVE.W   D4,D1
         MOVE.W   D5,D2
         QDOS     SD.POS            ; set cursor position
         MOVE.W   (A7)+,D2          ; length of wrapped text
         LEA      2(A7),A1          ; point to text
         BRA.S    WRAP_RSE
WRAP_RSL MOVE.B   (A1)+,D1          ; and add every character to the new line
         BSR.S    ADDCHR
WRAP_RSE DBF      D2,WRAP_RSL
         ADDA.W   (A7)+,A7          ; tidyup stack
         MOVE.B   (A7)+,D1          ; original keystroke
         CMPI.B   #' ',D1           ; was it a space?
         BEQ      MAINLOOP          ; yes, ignore it
NO_WRAP  BSR.S    ADDCHR            ; else, add to new line
         BRA      MAINLOOP

; Add character to current line

         XDEF     ADDCHR

ADDCHR   MOVEM.L  D2/A1,-(A7)
         MOVE.W   LINELEN(A6),D2
         CMPI.W   #254,D2
         BGE.S    ADDC_ERR
         CMPI.W   #254,D6
         BGE.S    ADDC_ERR
         LEA      (A3,D6.W),A1      ; current position in buffer
         SUB.W    D6,D2             ; how many characters after current?
         BEQ.S    ST_CHAR           ; none, just store
         BGT.S    AC_MOVE           ; move up
         NEG.W    D2
         ADD.W    D2,LINELEN(A6)
         SUBA.W   D2,A1
AC_FILSP MOVE.B   #' ',(A1)+        ; fill up with spaces
         SUBQ.W   #1,D2
         BNE      AC_FILSP
         BRA.S    ST_CHAR
AC_MOVE  TST.B    OVERWMOD(A6)      ; overwrite mode?
         BNE.S    OV_CHAR           ; yes
         ADDA.W   D2,A1             ; go to end of line
         MOVE.W   D2,D0
ADDC_LP  MOVE.B   -(A1),1(A1)       ; and move rest up
         SUBQ.W   #1,D0
         BNE      ADDC_LP
ST_CHAR  ADDQ.W   #1,LINELEN(A6)    ; one more character
OV_CHAR  MOVE.B   D1,(A1)           ; enter it
         TST.W    D2                ; at end of line?
         BEQ.S    ADDC_PR2          ; yes, skip
         TST.B    OVERWMOD(A6)
         BNE.S    ADDC_PR2          ; skip too when overwriting
         BSR      DSP_BUF           ; else, redisplay buffer
         BRA.S    ADDC_END
ADDC_PR2 MOVE.B   D1,-(A7)          ; save character
         MOVE.W   D4,D1
         MOVE.W   D5,D2
         QDOS     SD.POS            ; set current position
         MOVE.B   (A7)+,D1
         QDOS     IO.SBYTE          ; and display new character
ADDC_END BSR      RIGHT             ; move cursor right
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
         DC.W     K_SHF5
         DC.W     CH_TABCP-*
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
         BEQ.S    SPLIT_LN          ; Jump if INSERT mode
         BSR      COPYLINE
         CMP.W    MAXLINE(A6),D7
         BHS.S    SPL_NWLN          ; But if at end of file, create a new line
NL_LEFT  BSR      ENT_LINE
         BSR      GET_INDT
         SUB.W    D6,D1
         BSR      HCUR
         BRA      DOWN

* Split current line at cursor position

         XDEF     SPLIT_LN

SPLIT_LN BSR      COPYLINE
         BSR      STRIPSPC
         MOVE.W   D1,D2             ; D2 = line length
         SUB.W    D6,D2             ; D2 = no. of characters after cursor
         BGE.S    SPL_LLN
SPL_NWLN MOVEQ    #0,D2
SPL_LLN  SUB.W    D2,LINELEN(A6)    ; Chop off line after cursor
         MOVE.W   LINELEN(A6),-(A7)
         BSR      ENT_LIN1          ; Enter line + extra LF
         SUBQ.B   #1,(A5,D7.W)      ; Discount extra LF from line length
         MOVEQ    #1,D1
         BSR      INSRT_LN          ; Insert extra line entry...
         BLT      MAIN_ERR
         MOVE.B   #1,1(A5,D7.W)     ; ...initially blank
         BSR      GET_INDT          ; Get position of new left margin
         ADD.W    D2,D1             ; D1 = length of remaining line
         CMPI.W   #254,D1
         IF HI THEN
            MOVE.W   #254,D1        ; Ensure length is OK
         ENDIF
         MOVE.W   (A7)+,D0          ; Get start of line after cursor
         MOVE.W   D1,LINELEN(A6)    ; Store new length
         SUB.W    D2,D1             ; Restore indent position
         MOVEM.W  D1-D2,-(A7)
         TST.W    D2                ; Any characters to move?
         BEQ.S    SPL_SPC           ; no
         LEA      (A3,D0.W),A1      ; Point to first char in buffer
         SUB.W    D0,D1             ; Subtract "old" from "new" pos
         BEQ.S    SPL_SPC           ; It's already in the right place
         BLT.S    SPL_DOWN          ; We'll have to move down if <0
         ADDA.W   D2,A1             ; If >0, move up
SPL_UP   MOVE.B   -(A1),(A1,D1.W)
         SUBQ.W   #1,D2
         BGT      SPL_UP
         BRA.S    SPL_SPC
SPL_DOWN MOVE.B   (A1)+,-1(A1,D1.W)
         SUBQ.W   #1,D2
         BGT      SPL_DOWN
SPL_SPC  MOVE.W   (A7),D1           ; Finally insert the spaces now
         BEQ.S    SPL_TAS           ; ...if any
         MOVE.L   A3,A1
SPL_SPCL MOVE.B   #' ',(A1)+
         SUBQ.W   #1,D1
         BGT      SPL_SPCL
SPL_TAS  TST.W    2(A7)
         IF NE THEN
            QDOS     SD.CLRRT       ; and clear any chars right from the cursor
         ENDIF
         MOVEM.W  (A7)+,D1-D2
         SUB.W    D6,D1             ; Find how many columns to move cursor
         BSR.S    HCUR              ; move cursor, panning if needed
         MOVE.W   D5,D1
         ADDQ.W   #1,D1             ; Go one line down on the screen
         CMP.W    WINLEN(A6),D1
         BGE.S    SPL_SCUP          ; ...unless we're already at the bottom
         MOVE.W   D1,D5             ; set new row position
         MOVE.W   CH_YINC(A6),D1    ; But if not, scroll remaining part down
         QDOS     SD.SCRBT
         BRA.S    SPL_DLIN
SPL_SCUP MOVE.W   CH_YINC(A6),D1    ; We're at the bottom so scroll up
         NEG.W    D1
         QDOS     SD.SCROL
         MOVEQ    #0,D0
         SUB.W    D5,D7
         MOVE.B   (A5,D7.W),D0      ; get length of top line in window
         ADD.W    D5,D7
         ADDA.L   D0,A4             ; ...and adjust top line pointer
SPL_DLIN ADDQ.W   #1,D7             ; Go to next line
         TAS      EDIT_LN(A6)       ; signal 'new line in buffer'
         BSR      ENT_LINE          ; FIX: commit remaining part too!
         BRA      DSP_BUF           ; ...and finally display the new line

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

HCUR     MOVE.W   D1,-(A7)          ; save direction
         SUB.W    D6,D4             ;
         ADD.W    D1,D6             ; get new absolute column pos
         BLT.S    HCUR_L            ; do not allow < 0
         CMPI.W   #254,D6
         BLE.S    HCUR_2
         MOVE.W   #254,D6           ; and do not allow > 254
         BRA.S    HCUR_2
HCUR_L   MOVEQ    #0,D6
HCUR_2   ADD.W    D6,D4             ; D4 now holds new column pos on screen
         BLT.S    HCUR_SL           ; if <0, pan left
         CMP.W    WINWID(A6),D4     ; still in window?
         BLT.S    HCUR_END          ; yes, done
         MOVEQ    #-10,D4           ; else, pan
         ADD.W    WINWID(A6),D4
         BRA.S    HCUR_3
HCUR_SL  MOVEQ    #10,D4
HCUR_3   CMP.W    D4,D6
         BGE.S    HCUR_4
         MOVE.W   D6,D4
HCUR_4   BSR      DSP_PAGE          ; redraw screen
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
         MOVE.W   CH_YINC(A6),D1
         NEG.W    D1
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
         MOVE.W   CH_YINC(A6),D1
         NEG.W    D1
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
         MOVE.W   CH_YINC(A6),D1
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
         MOVE.W   CH_YINC(A6),D1
         NEG.W    D1
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
RES_STAT BSR      DSP_PAGE
         SF       STPRINTD(A6)
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
