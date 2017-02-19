* QED TEXT EDITOR by Jan Bredenbeek
* Start: 27 June 1988
* Release 1.00: August 1988
* Release 1.01: September 1988 (stable)
* Licenced under GPL v3 Licence (2017)
* See https://github.com/janbredenbeek/QED for latest version from the author
* This should be assembled and linked using the GST Macro Assembler and Linker
* (see http://www.dilwyn.me.uk/asm/index.html)
*
* Main program part
*
         INCLUDE  FLP1_MACRO_LIB             Macro definitions
         INCLUDE  FLP1_QDOS_IN_MAC           QDOS definitions
         INCLUDE  FLP2_QED_DEF               QED Definitions

* External references         
         
         XREF     MK_LNTBL,INSRT_LN,DEL_LNTB,ENT_LINE,GETSCRLN,MOV_TXT
         XREF     STRIPSPC,COPYLINE,DSP_PAGE,DSP_BUF,DSP_LINE,OPENFILE
         XREF     ERRMSG,DISPSTAT,ITOD,READNUM,FINDLINE,EL_ERR,FIND_DSP
         XREF     ENT_LIN1,DS_NUM,DS_NUM1,FIND_DS1,NO_LNTBL

* Start of code
         
         SECTION  CODE

         BRA.S    ED_START
         DC.L     0
         DC.W     $4AFB
         STRING$  {'QED'}
         DS.W     0                 Get the following data word aligned
         
* Configuration data (modified by QEDCONFIG_BAS)         
         
WINDEF   DC.W     480,210,16,5      Outline window
DEFMARGN DC.W     0,79              Default margins
DFTABINC DC.W     9                 Default TAB increment
DEFWRKSP DC.W     12                Default workspace size (KB)
BORD_PRM DC.B     4,1,0,7           Border colour and size
TXTWIN_P DC.B     0                 Text window paper colour
TXTWIN_I DC.B     7                 Text window ink colour
REPORT_P DC.B     2                 Report (status) window paper colour
REPORT_I DC.B     7                 Report (status) window ink colour
CMDLN_P  DC.B     4                 Command line paper colour
CMDLN_I  DC.B     0                 Command line ink colour
CSIZE    DC.B     0                 Character size
HELPFNAM STRING$  'mdv1_QED_HELP'   Name of Help file
         DS.B     46-(*-HELPFNAM)   Allow for spare
CONNAME  STRING$  'CON'             Name of CON device

         XDEF     REPORT_P,REPORT_I

* INITIALISATION PROCEDURE

ED_START ADDA.L   A4,A6
         MOVE.W   (A7)+,D0
         LSL.W    #2,D0
         ADDA.W   D0,A7
         MOVE.W   (A7)+,D0
         LEA      FILENAME(A6),A1
         MOVE.W   D0,(A1)+
         ADDQ.W   #1,D0
         LSR.W    #1,D0
         BRA.S    ED_CNAME
ED_CNAML MOVE.W   (A7)+,(A1)+
ED_CNAME DBF      D0,ED_CNAML
         MOVE.L   A7,ERR_SP(A6)
         MOVEQ    #-1,D1
         MOVEQ    #-1,D2
         QDOS     MT.DMODE
         TST.B    D1
         IF NE THEN
            MOVEQ    #0,D1
            MOVEQ    #-1,D2
            QDOS     MT.DMODE
         ENDIF
         MOVEQ    #-1,D1
         MOVEQ    #0,D3
         LEA      CONNAME,A0
         QDOS     IO.OPEN
         MOVE.L   A0,GUARDWIN(A6)
         MOVE.B   BORD_PRM,D1
         MOVEQ    #0,D2
         MOVE.B   BORD_PRM+1,D2
         MOVEQ    #-1,D3
         MOVE.L   A7,A1
         MOVE.L   WINDEF+4,-(A7)
         MOVE.L   WINDEF,-(A7)
         MOVE.W   D2,D0
         SUB.W    D0,-(A1)
         ADD.W    D0,D0
         SUB.W    D0,-(A1)
         ADD.W    D0,-(A1)
         ADD.W    D0,D0
         ADD.W    D0,-(A1)
         QDOS     SD.WDEF
         LEA      BORD_PRM+2,A2
         MOVE.B   (A2),D1
         QDOS     SD.SETPA
         MOVE.B   (A2)+,D1
         QDOS     SD.SETST
         MOVE.B   (A2),D1
         QDOS     SD.SETIN
         QDOS     SD.CLEAR
         MOVEQ    #-1,D1
         MOVEQ    #0,D3
         LEA      CONNAME,A0
         QDOS     IO.OPEN
         MOVE.L   A0,TXTWIN(A6)
         MOVE.L   WINDEF,(A7)
         MOVE.L   WINDEF+4,4(A7)
         SUBI.W   #10,2(A7)
         MOVEQ    #0,D1
         MOVEQ    #0,D2
         MOVEQ    #-1,D3
         MOVE.L   A7,A1
         QDOS     SD.WDEF
         MOVE.B   CSIZE,D1
         MOVEQ    #0,D2
         QDOS     SD.SETSZ
         SUBQ.W   #8,A7
         MOVE.L   A7,A1
         QDOS     SD.CHENQ
         MOVE.L   (A7)+,WINWID(A6)
         ADDQ.W   #4,A7
         LEA      TXTWIN_P,A2
         MOVE.B   (A2),D1
         QDOS     SD.SETPA
         MOVE.B   (A2)+,D1
         QDOS     SD.SETST
         MOVE.B   (A2),D1
         QDOS     SD.SETIN
         MOVEQ    #-1,D1
         MOVEQ    #0,D3
         LEA      CONNAME,A0
         QDOS     IO.OPEN
         MOVE.L   A0,CMDWIN(A6)
         MOVE.W   2(A7),D0
         ADD.W    D0,6(A7)
         MOVE.W   #10,2(A7)
         MOVEQ    #0,D1
         MOVEQ    #0,D2
         MOVEQ    #-1,D3
         MOVE.L   A7,A1
         QDOS     SD.WDEF
         ADDQ.W   #8,A7
         MOVE.B   CSIZE,D1
         IF NE THEN
            MOVEQ    #1,D1
         ENDIF
         MOVEQ    #0,D2
         QDOS     SD.SETSZ
         CLR.L    TXTBASE(A6)
         SF       MSGPRNTD(A6)
         SF       STPRINTD(A6)
         MOVE.L   GUARDWIN(A6),A0
         MOVEQ    #3,D1
         MOVEQ    #1,D2
         QDOS     SD.SETSZ
         LEA      SIGNON1,A1
         BSR      P_MIDDLE
         MOVEQ    #1,D1
         MOVEQ    #0,D2
         QDOS     SD.SETSZ
         MOVEQ    #0,D1
         MOVEQ    #3,D2
         QDOS     SD.POS
         LEA      SIGNON2,A1
         BSR      P_MIDDLE
         TST.W    FILENAME(A6)
         BNE      OP_WRKFL
         PRINT    {LF,LF,'File name: '}
         MOVEQ    #44,D2
         LEA      FILENAME+2(A6),A1
         QDOS     IO.FLINE
         SUBA.W   D1,A1
         SUBQ.W   #1,D1
         MOVE.W   D1,-(A1)
GET_WRK  PRINT    {LF,'Workspace size (ENTER for default): '}
         MOVEQ    #10,D2
         LEA      CMDBUF(A6),A1
         QDOS     IO.FLINE
         TST.L    D0
         BNE      GET_WRK
         SUBQ.W   #1,D1
         BEQ.S    OP_WRKFL
         MOVEQ    #0,D4
         MOVEQ    #$DF,D0
         AND.B    -2(A1),D0
         IF D0 EQ.B #'K' THEN
            MOVEQ    #10,D4
         ENDIF
         LEA      CMDBUF(A6),A1
         BSR      READNUM
         TST.W    D1
         BGT.S    GETWRK1
         PRINT    {'Invalid number'}
         BRA      GET_WRK
GETWRK1  LSL.L    D4,D1
         MOVEQ    #-1,D2
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
         BSR      OPENFILE
         TST.L    TXTBASE(A6)
         BNE.S    RD_WRKFL
         MOVEM.L  D0/A0,-(A7)
         TST.L    D0
         IF EQ THEN
            MOVEQ    #4,D2
            SUBA.W   D2,A7
            MOVEQ    #-1,D3
            MOVE.L   A7,A1
            QDOS     FS.HEADR
            MOVE.L   (A7)+,D1
            ADDI.L   #4096,D1
         ELSE
            MOVEQ    #0,D1
            MOVE.W   DEFWRKSP,D1
            SWAP     D1
            LSR.L    #6,D1
         ENDIF
         MOVEQ    #-1,D2
         QDOS     MT.ALCHP
         TST.L    D0
         BEQ.S    SETWRKSP
         SUBA.L   A0,A0
         PRINT    {'QED: No room for workspace',LF}
         MOVEQ    #-1,D1
         MOVEQ    #ERR.OM,D3
         QDOS     MT.FRJOB
SETWRKSP MOVE.L   A0,TXTBASE(A6)
         LEA      -$10(A0,D1.L),A0
         MOVE.L   A0,TXTMAX(A6)
         MOVEM.L  (A7)+,D0/A0
RD_WRKFL TST.L    D0
         BNE.S    NEW_WRKF
         MOVEQ    #4,D2
         SUBA.W   D2,A7
         MOVEQ    #-1,D3
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
         MOVEM.L  D2-D3/A0-A1,-(A7)
         ERRMSG   {'Reading '}
         MOVE.L   CMDWIN(A6),A0
         LEA      FILENAME(A6),A1
         MOVE.W   UT_MTEXT,A2
         JSR      (A2)
         SF       MSGPRNTD(A6)
         MOVEM.L  (A7)+,D2-D3/A0-A1
         QDOS     FS.LOAD
         TST.L    D0
         BNE.S    RDW_FERR
         QDOS     IO.CLOSE
         BRA.S    GETLNTBL
RDW_FERR ERRMSG   {'File I/O error'}
         BRA.S    RDW_CLOS
RDW_BF   ERRMSG   {'File too large'}
RDW_CLOS QDOS     IO.CLOSE
         BRA.S    CL_WORK
NEW_WRKF ERRMSG   {'Creating new file'}
CL_WORK  MOVE.L   TXTBASE(A6),TXTEND(A6)
GETLNTBL LEA      LEFTMAR(A6),A1
         MOVE.L   DEFMARGN,(A1)+    SET DEFAULT MARGINS
         MOVE.W   DFTABINC,(A1)+    SET DEFAULT TAB DISTANCE
         MOVE.L   #-1,(A1)+         CLEAR BLKSTART AND BLKEND
         CLR.L    (A1)+             CLEAR RTLIN1 AND RTLIN2
         CLR.L    (A1)+             CLEAR RTLIN3, EDIT_LN AND EDIT_TXT
         SF       (A1)+             CLEAR OVERWMOD
         CLR.W    FINDSTR(A6)       MAKE FIND STRING NULL
         BSR      MK_LNTBL
         MOVE.L   TXTWIN(A6),A0
         MOVEQ    #0,D4             X POS ON WINDOW
         MOVEQ    #0,D5             Y POS ON WINDOW
         MOVEQ    #0,D6             COLUMN
         MOVEQ    #0,D7             LINE
         LEA      LINEBUF(A6),A3
         MOVE.L   TXTBASE(A6),A4
         BSR      DSP_PAGE
         MOVE.B   #LF,CMDBUF(A6)
         BRA.S    MAINLOOP

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
         STRING$  {'Copyright  1988 by Jan Bredenbeek'}
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
         CMPI.B   #$20,D1
         BLO.S    MAINCTRL
         CMPI.B   #$BF,D1
         BLS.S    ENT_CHR
MAINCTRL LEA      KEYTBL-2,A1
LOOK_KEY ADDQ.W   #2,A1
         MOVE.W   (A1)+,D0
         BEQ      MAINLOOP
         CMP.B    D0,D1
         BNE      LOOK_KEY
         ADDA.W   (A1),A1
         JSR      (A1)
         BRA      MAINLOOP
ENT_CHR  BSR      COPYLINE
         CMP.W    RIGHTMAR(A6),D6
         BNE      NO_WRAP
         CMP.W    LINELEN(A6),D6
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
ADDC_ERR ERRMSG   {'Line too long'}
         MOVEM.L  (A7)+,D2/A1
         RTS

KEYTBL   DC.W     K_TAB
         DC.W     TAB-*
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
         DC.W     K_RIGHT+K.SHIFT+K.CTRL
         DC.W     SCRIGHT-*
         DC.W     K_UP
         DC.W     UP-*
         DC.W     K_UP+K.ALT
         DC.W     AUP-*
         DC.W     K_UP+K.CTRL
         DC.W     CUP-*
         DC.W     K_UP+K.SHIFT
         DC.W     SUP-*
         DC.W     K_DOWN
         DC.W     DOWN-*
         DC.W     K_DOWN+K.ALT
         DC.W     ADOWN-*
         DC.W     K_DOWN+K.CTRL
         DC.W     CDOWN-*
         DC.W     K_DOWN+K.SHIFT
         DC.W     SDOWN-*
         DC.W     K_F1
         DC.W     HELP-*
         DC.W     K_F2
         DC.W     REP_CMD-*
         DC.W     K_F3
         DC.W     ENT_CMD-*
         DC.W     K_SHF3
         DC.W     ED_COMLN-*
         DC.W     K_F4
         DC.W     CH_MODE-*
         DC.W     K_F5
         DC.W     REFILL-*
         DC.W     0

TAB      MOVEQ    #0,D2
         MOVE.W   D6,D2
         DIVU     TABINC(A6),D2
         SWAP     D2
         NEG.W    D2
         ADD.W    TABINC(A6),D2
GO_TAB   BSR      COPYLINE
TAB_LOOP MOVEQ    #' ',D1
         BSR      ADDCHR
         SUBQ.W   #1,D2
         BNE      TAB_LOOP
         RTS

NEWLINE  TST.B    OVERWMOD(A6)
         BEQ.S    SPLIT_LN
         BSR      ENT_LINE
         CMP.W    MAXLINE(A6),D7
         BLT.S    NL_LEFT
         MOVE.L   TXTEND(A6),A1
         MOVEQ    #1,D1
         BSR      MOV_TXT
         BNE      EL_ERR
         MOVE.B   #LF,(A1)
         MOVEQ    #1,D1
         BSR      INSRT_LN
         MOVE.B   #1,1(A5,D7.W)
NL_LEFT  BSR      ALEFT
         BSR      DOWN
         BRA.S    SPLTLN_T

SPLIT_LN BSR      COPYLINE
         BSR      STRIPSPC
         MOVE.W   D1,D2
         LEA      (A3,D2.W),A1
         MOVE.W   LEFTMAR(A6),D1
         ADDQ.W   #1,D1
         ADD.W    D2,D1
         CMPI.W   #255,D1
         BGT      ADDC_ERR
         SUB.W    D2,D1
         SUB.W    D6,D2
         IF LT THEN
            MOVEQ    #0,D2
         ENDIF
         MOVE.W   D2,D0
         ADD.W    D1,D2
         ADD.W    D1,LINELEN(A6)
         BRA.S    NL_ILF_E
NL_ILF_L MOVE.B   -(A1),(A1,D1.W)
NL_ILF_E DBF      D0,NL_ILF_L
         MOVE.B   #LF,(A1)+
         MOVE.W   D1,-(A7)
NL_FILSP SUBQ.W   #1,D1
         BLE.S    NL_ENTER
         MOVE.B   #' ',(A1)+
         BRA      NL_FILSP
NL_ENTER BSR      ENT_LIN1
         SUB.B    D2,(A5,D7.W)
         MOVEQ    #1,D1
         BSR      INSRT_LN
         MOVE.B   D2,1(A5,D7.W)
         SUB.W    (A7)+,D2
         IF NE THEN
            QDOS     SD.CLRRT
         ENDIF
         MOVEQ    #10,D1
         QDOS     SD.SCRBT
         BSR.S    ALEFT
         BSR      DOWN
         IF EQ THEN
            BSR      GETSCRLN
            BSR      DSP_LINE
         ENDIF
SPLTLN_T MOVE.W   LEFTMAR(A6),D1
         BRA.S    HCUR

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
         BSR      HCUR
         NEG.W    D1
         BRA.S    DEL_D1
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
         BCS      ADDC_ERR
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

UP       BSR      ENT_LINE
         TST.W    D5
         BEQ.S    AUP
         SUBQ.W   #1,D5
         SUBQ.W   #1,D7
         RTS
DOWN     BSR      ENT_LINE
         MOVE.W   D5,D1
         ADDQ.W   #1,D1
         CMP.W    WINLEN(A6),D1
         BGE.S    ADOWN
         CMP.W    MAXLINE(A6),D7
         BEQ.S    END_FILE
         MOVE.W   D1,D5
         ADDQ.W   #1,D7
         MOVEQ    #0,D0
         RTS

AUP      CMP.W    D5,D7
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

ADOWN    MOVE.W   WINLEN(A6),D0
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

SUP      BSR      ENT_LINE
         MOVEQ    #0,D2
         SUB.W    D5,D7
         MOVE.W   D7,D1
         ADDQ.W   #1,D1
         SUB.W    WINLEN(A6),D1
         BPL.S    SHFT_FND
         MOVEQ    #0,D1
         MOVEQ    #-1,D2
         BRA.S    SHFT_FND

SDOWN    BSR      ENT_LINE
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

CH_MODE  NOT.B    OVERWMOD(A6)
         BRA.S    RES_STAT
REFILL   MOVE.B   BORD_PRM,D1
         MOVEQ    #0,D2
         MOVE.B   BORD_PRM+1,D2
         MOVE.L   GUARDWIN(A6),A0
         QDOS     SD.BORDR
         BSR      DSP_PAGE
RES_STAT SF       STPRINTD(A6)
         RTS

CMD_COLR MOVE.L   CMDWIN(A6),A0
         MOVE.B   CMDLN_P,D1
         QDOS     SD.SETPA
         MOVE.B   CMDLN_P,D1
         QDOS     SD.SETST
         MOVE.B   CMDLN_I,D1
         QDOS     SD.SETIN
         QDOS     SD.CLEAR
         MOVEQ    #'>',D1
         QDOS     IO.SBYTE
         LEA      CMDBUF(A6),A1
         MOVEQ    #0,D1
CMDLENLP CMPI.B   #LF,(A1,D1.W)
         BEQ.S    CMDCOL_E
         ADDQ.W   #1,D1
         BRA      CMDLENLP
CMDCOL_E RTS

REP_CMD  BSR      CMD_COLR
         MOVE.W   D1,D2
DSPCMDLN QDOS     IO.SSTRG
         BRA.S    EXEC_CMD

ENT_CMD  MOVE.B   #LF,CMDBUF(A6)
ED_COMLN BSR      CMD_COLR
         ADDA.W   D1,A1
         MOVE.W   #256,D2
         QDOS     IO.EDLIN
         MOVE.B   #LF,-(A1)
EXEC_CMD SF       MSGPRNTD(A6)
         SF       STPRINTD(A6)
         CLR.L    -(A7)
         LEA      CMDBUF(A6),A2
CMD_GTCT BSR      SKIPSPC
         CMPI.B   #LF,(A2)
         BEQ      CMD_END
         MOVEQ    #1,D1
         CMPI.B   #'0',(A2)
         BLO.S    CMD_BRAC
         CMPI.B   #'9',(A2)
         BHI.S    CMD_BRAC
         BSR      GETNUM
CMD_NXTB BSR      SKIPSPC
CMD_BRAC MOVE.W   D1,-(A7)
         CMPI.B   #'(',(A2)
         BNE.S    CMD_FRST
         ADDQ.W   #1,A2
         MOVE.L   A2,-(A7)
         BRA      CMD_GTCT
CMD_FRST MOVE.B   (A2)+,D1
         BSR      UP_ALPHA
         BNE      CMD_ERR
         LSL.W    #8,D1
         MOVE.B   (A2),D1
         BSR      UP_ALPHA
         BNE.S    CMD_1LET
         ADDQ.W   #1,A2
         CMPI.W   #'RP',D1
         BNE.S    CMD_LOOK
         ADDQ.W   #2,A7
         MOVEQ    #0,D1
         BRA      CMD_NXTB
CMD_1LET MOVE.B   #' ',D1
CMD_LOOK BSR      SKIPSPC
         LEA      CMDTBL-2,A1
CMD_LOOP ADDQ.W   #2,A1
         MOVE.W   (A1)+,D0
         BEQ.S    CMD_UNKN
         CMP.W    D1,D0
         BNE      CMD_LOOP
         ADDA.W   (A1),A1
         MOVEM.L  A1-A2,-(A7)
CMD_CALL MOVE.L   TXTWIN(A6),A0
         MOVE.W   D4,D1
         MOVE.W   D5,D2
         MOVEQ    #-1,D3
         QDOS     SD.POS
         MOVEM.L  (A7),A1-A2
         JSR      (A1)
         BSR      TST_ESC
         TST.W    8(A7)
         BEQ      CMD_CALL
         SUBQ.W   #1,8(A7)
         BNE      CMD_CALL
         ADDA.W   #10,A7
CMD_NEXT BSR.S    SKIPSPC
         MOVE.B   (A2)+,D1
         CMPI.B   #LF,D1
         BEQ.S    CMD_END
         CMPI.B   #';',D1
         BEQ      CMD_GTCT
         CMPI.B   #')',D1
         BNE.S    CMD_ERR
         TST.L    (A7)
         BEQ.S    CMD_BMIS
         TST.W    4(A7)
         BEQ.S    REP_BRAC
         SUBQ.W   #1,4(A7)
         BNE.S    REP_BRAC
         ADDQ.W   #6,A7
         BRA      CMD_NEXT
REP_BRAC MOVE.L   (A7),A2
         BRA      CMD_GTCT
CMD_END  TST.L    (A7)+
         BNE.S    CMD_BMIS
         RTS
CMD_ERR  LEA      SYNTXMSG,A1
         BRA.S    CMD_MSG
CMD_UNKN LEA      UNKNMSG,A1
         BRA.S    CMD_MSG
CMD_BMIS LEA      BMISMSG,A1
         BRA.S    CMD_MSG
CMD_ESC  MOVE.L   TXTWIN(A6),A0
         MOVEQ    #0,D3
CMDE_CLR QDOS     IO.FBYTE
         TST.L    D0
         BEQ      CMDE_CLR
         LEA      ESCMSG,A1
CMD_MSG  BSR      ERRMSG
         BRA      MAIN_ERR

         SECTION  MSG
SYNTXMSG STRING$  {'Syntax error'}
UNKNMSG  STRING$  {'Unknown command'}
BMISMSG  STRING$  {'Mismatched ()'}
ESCMSG   STRING$  {'Commands interrupted'}
         SECTION  CODE

SKIPSPC  CMPI.B   #' ',(A2)
         BNE.S    SKPSP_EN
         ADDQ.W   #1,A2
         BRA      SKIPSPC
SKPSP_EN RTS

UP_ALPHA CMPI.B   #$60,D1
         BLT.S    ALPHA_1
         SUBI.B   #$20,D1
ALPHA_1  CMPI.B   #'A',D1
         BLO.S    NO_ALPHA
         CMPI.B   #'Z',D1
         BHI.S    NO_ALPHA
         MOVEQ    #0,D0
         RTS
NO_ALPHA MOVEQ    #-1,D0
         RTS

TST_ESC  MOVEM.L  D1/D5/D7/A3,-(A7)
         LEA      ESC_CMD,A3
         QDOS     MT.IPCOM
         LSR.B    #4,D1
         MOVEM.L  (A7)+,D1/D5/D7/A3
         BCS      CMD_ESC
         RTS
ESC_CMD  DC.B     9,1,0,0,0,0,1,2

GETNUM   EXG      A1,A2
         BSR      READNUM
         EXG      A1,A2
         TST.W    D1
         BEQ.S    BAD_NUM
         RTS
BAD_NUM  ERRMSG   {'Nonzero number expected'}
         BRA      MAIN_ERR

GETSTR   MOVE.B   (A2),D2
         CMPI.B   #LF,D2
         BEQ.S    NO_ARG
         CMPI.B   #';',D2
         BEQ.S    NO_ARG
         CMPI.B   #')',D2
         BEQ.S    NO_ARG
         ADDQ.W   #1,A2
         CMPI.B   #'!',D2
         BLT.S    BAD_DLIM
         CMPI.B   #'0',D2
         BLO.S    GS_FIRST
         CMPI.B   #'9',D2
         BLS.S    BAD_DLIM
         CMPI.B   #'A',D2
         BLO.S    GS_FIRST
         CMPI.B   #'Z',D2
         BLS.S    BAD_DLIM
         CMPI.B   #'a',D2
         BLO.S    GS_FIRST
         CMPI.B   #'z',D2
         BLS.S    BAD_DLIM
GS_FIRST MOVE.L   A2,A1
GS_LOOP  MOVE.B   (A2)+,D1
         CMPI.B   #LF,D1
         BEQ      CMD_ERR
         CMP.B    D2,D1
         BNE      GS_LOOP
         MOVE.L   A2,D1
         SUB.L    A1,D1
         SUBQ.W   #1,D1
         MOVEQ    #0,D0
         RTS
NO_ARG   MOVEQ    #-1,D0
         RTS
BAD_DLIM ERRMSG   {'Bad string delimiter'}
         BRA      MAIN_ERR

CMDTBL   DC.W     'A '
         DC.W     CMD_A-*
         DC.W     'B '
         DC.W     CMD_B-*
         DC.W     'BE'
         DC.W     CMD_BE-*
         DC.W     'BF'
         DC.W     CMD_BF-*
         DC.W     'BS'
         DC.W     CMD_BS-*
         DC.W     'CE'
         DC.W     ARIGHT-*
         DC.W     'CL'
         DC.W     LEFT-*
         DC.W     'CR'
         DC.W     RIGHT-*
         DC.W     'CS'
         DC.W     ALEFT-*
         DC.W     'D '
         DC.W     CALEFT-*
         DC.W     'DB'
         DC.W     CMD_DB-*
         DC.W     'DC'
         DC.W     CRIGHT-*
         DC.W     'DW'
         DC.W     SCRIGHT-*
         DC.W     'E '
         DC.W     CMD_E-*
         DC.W     'EQ'
         DC.W     CMD_EQ-*
         DC.W     'F '
         DC.W     CMD_F-*
         DC.W     'I '
         DC.W     CMD_I-*
         DC.W     'IB'
         DC.W     CMD_IB-*
         DC.W     'IF'
         DC.W     CMD_IF-*
         DC.W     'J '
         DC.W     JOIN_LN-*
         DC.W     'M '
         DC.W     CMD_M-*
         DC.W     'N '
         DC.W     DOWN-*
         DC.W     'NW'
         DC.W     SRIGHT-*
         DC.W     'P '
         DC.W     UP-*
         DC.W     'PW'
         DC.W     SLEFT-*
         DC.W     'Q '
         DC.W     CMD_Q-*
         DC.W     'R '
         DC.W     CMD_R-*
         DC.W     'RT'
         DC.W     CMD_RT-*
         DC.W     'S '
         DC.W     SPLIT_LN-*
         DC.W     'SA'
         DC.W     CMD_SA-*
         DC.W     'SB'
         DC.W     CMD_SB-*
         DC.W     'SH'
         DC.W     CMD_SH-*
         DC.W     'SL'
         DC.W     CMD_SL-*
         DC.W     'SR'
         DC.W     CMD_SR-*
         DC.W     'ST'
         DC.W     CMD_ST-*
         DC.W     'T '
         DC.W     CMD_T-*
         DC.W     'TY'
         DC.W     INS_STR-*
         DC.W     'U '
         DC.W     UNDO-*
         DC.W     'WB'
         DC.W     CMD_WB-*
         DC.W     'X '
         DC.W     CMD_X-*
         DC.W     0

CMD_RT   LEA      RTLIN1(A6),A1
         MOVE.W   (A1),D1
         MOVE.L   2(A1),(A1)+
         CLR.W    (A1)
         BRA      FIND_DSP

STORE_LN MOVE.L   RTLIN1(A6),RTLIN2(A6)
         MOVE.W   D7,RTLIN1(A6)
         RTS

CMD_T    MOVEQ    #0,D1
         BRA.S    CMD_NWLN
CMD_B    MOVE.W   MAXLINE(A6),D1
         BRA.S    CMD_NWLN
CMD_M    BSR      GETNUM
         SUBQ.W   #1,D1
         BRA.S    CMD_NWLN
CMD_SB   BSR      GETBLOCK
         EXG      D1,D2
         SUB.W    D5,D7
         MOVEQ    #0,D5
CMD_NWLN BSR      STORE_LN
         BRA      FIND_DSP

CMD_SL   MOVEQ    #LEFTMAR,D2
         BRA.S    CMD_GTNM
CMD_SR   MOVEQ    #RIGHTMAR,D2
CMD_GTNM BSR      GETNUM
         SUBQ.W   #1,D1
         MOVE.W   D1,(A6,D2.W)
         RTS
CMD_ST   BSR      GETNUM
         MOVE.W   D1,TABINC(A6)
         RTS

CMD_BS   MOVE.W   D7,BLKSTART(A6)
         RTS
CMD_BE   MOVE.W   D7,BLKEND(A6)
         RTS

ASK_QUIT MOVE.L   A5,D0
         BEQ.S    AQ_TST
         BSR      ENT_LINE
AQ_TST   TST.B    EDIT_TXT(A6)
         BEQ.S    AQ_RTS
         ERRMSG   {'Type Y to confirm: '}
         SF       MSGPRNTD(A6)
         MOVE.L   CMDWIN(A6),A0
         QDOS     SD.CURE
         QDOS     IO.FBYTE
         MOVEQ    #$DF,D2
         AND.B    D1,D2
         QDOS     SD.CURS
         CMPI.B   #'Y',D2
         BEQ.S    AQ_RTS
         ADDQ.W   #4,A7
AQ_RTS   RTS

CMD_Q    BSR.S    ASK_QUIT
         BRA.S    KILL_QED
CMD_X    BSR.S    SA_CURR
KILL_QED MOVE.L   GUARDWIN(A6),A0
         MOVEQ    #-1,D3
         MOVEQ    #0,D1
         MOVEQ    #0,D2
         QDOS     SD.BORDR
         QDOS     SD.CLEAR
         MOVEQ    #-1,D1
         MOVEQ    #0,D3
         QDOS     MT.FRJOB

CMD_SA   BSR      GETSTR
         BNE.S    SA_CURR
         BSR.S    COPY_STK
         BRA.S    SA_SAVE
SA_CURR  CLR.W    -(A7)
         LEA      FILENAME(A6),A0
SA_SAVE  MOVE.L   A5,D0
         BEQ.S    SA_SAV1
         BSR      ENT_LINE
SA_SAV1  MOVE.L   TXTBASE(A6),A1
         MOVE.L   TXTEND(A6),D1
         SUB.L    A1,D1
         BSR.S    SA_BLOCK
         ADDA.W   (A7)+,A7
         SF       EDIT_TXT(A6)
         RTS

COPY_STK MOVE.L   (A7)+,A0
         MOVE.W   D1,D0
         ADDQ.W   #3,D0
         BCLR     #0,D0
         SUBA.W   D0,A7
         MOVE.W   D1,(A7)
         MOVE.W   D0,-(A7)
         MOVE.L   A0,-(A7)
         LEA      8(A7),A0
         BRA.S    CSL_END
CSL_LOOP MOVE.B   (A1)+,(A0)+
CSL_END  DBF      D1,CSL_LOOP
         LEA      6(A7),A0
         RTS

CMD_WB   BSR      GETSTR
         BNE      EXPT_STR
         BSR      COPY_STK
         BSR.S    GETBLOCK
         BSR.S    SA_BLOCK
         ADDA.W   (A7)+,A7
         RTS

* SAVE D1 BYTES AT (A1) TO FILE (A0)

SA_BLOCK MOVEM.L  D1/A0-A2,-(A7)
         MOVEQ    #3,D3
         BSR      OPENFILE
         BNE.S    FL_ERROR
         MOVE.L   A0,-(A7)
         ERRMSG   {'Writing '}
         MOVE.L   CMDWIN(A6),A0
         MOVE.L   8(A7),A1
         MOVE.W   UT_MTEXT,A2
         JSR      (A2)
         SF       MSGPRNTD(A6)
         MOVE.L   (A7)+,A0
         MOVE.L   (A7),D2
         MOVEQ    #-1,D3
         MOVE.L   8(A7),A1
SA_LOOP  MOVE.L   D2,-(A7)
         CMPI.L   #$7FFE,D2
         BLE.S    SA_SEND
         MOVE.W   #$7FFE,D2
SA_SEND  QDOS     IO.SSTRG
         MOVE.L   (A7)+,D2
         TST.L    D0
         BNE.S    SA_CLOSE
         ANDI.L   #$FFFF,D1
         SUB.L    D1,D2
         BGT      SA_LOOP
SA_CLOSE MOVE.L   D0,-(A7)
         QDOS     IO.CLOSE
         MOVEM.L  (A7)+,D0-D1/A0-A2
         TST.L    D0
         BNE.S    FL_ERROR
         RTS
FL_ERROR ERRMSG   {'FILE ERROR: '}
         MOVE.L   CMDWIN(A6),A0
         MOVE.W   UT_ERR,A2
         JSR      (A2)
         BRA.S    ERR2

GETBLOCK MOVEM.W  BLKSTART(A6),D1-D2
         TST.W    D1
         BLT.S    NOBLOCK
         TST.W    D2
         BLT.S    NOBLOCK
         CMP.W    D1,D2
         BLT.S    BADBLOCK
         BSR      ENT_LINE
         BSR      FINDLINE
         MOVE.L   A1,-(A7)
         EXG      D1,D2
         BSR      FINDLINE
         MOVEQ    #0,D0
         MOVE.B   (A5,D1.W),D0
         MOVE.L   A1,D1
         MOVE.L   (A7)+,A1
         SUB.L    A1,D1
         ADD.L    D0,D1
         RTS

EXPT_STR ERRMSG   {'String expected'}
         BRA.S    ERR2
NOBLOCK  ERRMSG   {'No block defined'}
         BRA.S    ERR2
BADBLOCK ERRMSG   {'Block start > block end'}
         BRA.S    ERR2
IF_NOMEM QDOS     IO.CLOSE
         ERRMSG   {'No room for file'}
ERR2     BRA      MAIN_ERR

CMD_IF   BSR      GETSTR
         BNE      EXPT_STR
         BSR      ENT_LINE
         BSR      COPY_STK
         MOVEQ    #1,D3
         BSR      OPENFILE
         BNE      FL_ERROR
         MOVEQ    #4,D2
         SUBA.W   D2,A7
         MOVEQ    #-1,D3
         MOVE.L   A7,A1
         QDOS     FS.HEADR
         MOVE.L   (A7)+,D2
         TST.L    D0
         BNE.S    IF_CLOSE
         BSR      GETSCRLN
         MOVE.L   D2,D1
         BSR      MOV_TXT
         BNE      IF_NOMEM
         MOVEM.L  D2-D3/A0-A2,-(A7)
         ERRMSG   {'Inserting '}
         MOVE.L   CMDWIN(A6),A0
         LEA      22(A7),A1
         MOVE.W   UT_MTEXT,A2
         JSR      (A2)
         SF       MSGPRNTD(A6)
         MOVEM.L  (A7)+,D2-D3/A0-A2
IF_LOOP  MOVE.L   D2,-(A7)
         CMPI.L   #$7FFE,D2
         BLE.S    IF_FETCH
         MOVE.W   #$7FFE,D2
IF_FETCH QDOS     IO.FSTRG
         MOVE.L   (A7)+,D2
         TST.L    D0
         BNE.S    IF_CLOSE
         ANDI.L   #$FFFF,D1
         SUB.L    D1,D2
         BGT      IF_LOOP
IF_CLOSE MOVEM.L  D0/A1-A3,-(A7)
         QDOS     IO.CLOSE
         MOVE.L   A5,A0
         QDOS     MT.RECHP
         BSR      MK_LNTBL
         MOVEM.L  (A7)+,D0/A1-A3
         ADDA.W   (A7)+,A7
         TST.L    D0
         BNE      FL_ERROR
         BRA      DSP_PAGE

CMD_IB   BSR      GETBLOCK
         MOVE.L   A1,A0
         CMP.W    D2,D7
         BLE.S    IB_MVMEM
         CMP.W    BLKEND(A6),D7
         BLE.S    IB_BADBL
IB_MVMEM BSR      GETSCRLN
         BSR      MOV_TXT
         BNE      EL_ERR
         CMPA.L   A1,A0
         BLO.S    IB_COPY
         ADDA.L   D1,A0
IB_COPY  MOVE.B   (A0)+,(A1)+
         SUBQ.L   #1,D1
         BGT      IB_COPY
         MOVE.W   BLKEND(A6),D1
         SUB.W    D2,D1
         ADDQ.W   #1,D1
         BSR      INSRT_LN
         CMP.W    D7,D2
         BLT.S    IB_COPYL
         ADD.W    D1,D2
IB_COPYL MOVE.W   D2,BLKSTART(A6)
         MOVE.W   D2,D0
         ADD.W    D1,D0
         SUBQ.W   #1,D0
         MOVE.W   D0,BLKEND(A6)
         MOVE.W   D7,D0
IB_LLOOP MOVE.B   (A5,D2.W),(A5,D0.W)
         ADDQ.W   #1,D0
         ADDQ.W   #1,D2
         SUBQ.W   #1,D1
         BGT      IB_LLOOP
         BRA      DSP_PAGE
IB_BADBL ERRMSG   {'"IB" position must be outside block'}
         BRA      MAIN_ERR

CMD_DB   BSR      GETBLOCK
         BSR      STORE_LN
         MOVEQ    #0,D5
         MOVE.W   D2,D7
         MOVE.L   A1,A4
         NEG.L    D1
         BSR      MOV_TXT
         MOVE.W   BLKEND(A6),D1
         SUB.W    D2,D1
         ADDQ.W   #1,D1
         BSR      DEL_LNTB
         MOVE.W   D2,D1
         BRA      FIND_DSP

CMD_R    BSR      ASK_QUIT
         BSR      GETSTR
         CMPI.W   #44,D1
         BGT.S    BADFNAM
         MOVEM.L  D1/A1,-(A7)
         MOVE.L   TXTWIN(A6),A0
         MOVEQ    #-1,D3
         QDOS     SD.CLEAR
         MOVEM.L  (A7)+,D1/A1
         LEA      FILENAME(A6),A0
         MOVE.W   D1,(A0)+
         BRA.S    R_COPY_E
R_COPY_L MOVE.B   (A1)+,(A0)+
R_COPY_E DBF      D1,R_COPY_L
         MOVE.L   A5,D0
         BEQ.S    R_CLTXT
         MOVE.L   D0,A0
         QDOS     MT.RECHP
R_CLTXT  MOVE.L   TXTBASE(A6),A0
         CLR.L    TXTBASE(A6)
         QDOS     MT.RECHP
         MOVE.L   ERR_SP(A6),A7
         BRA      OP_WRKFL
BADFNAM  ERRMSG   {'Invalid file name'}
         BRA      MAIN_ERR

CMD_SH   QDOS     SD.CLEAR
         MOVE.L   A2,-(A7)
         PRINT    {'Editing file : '}
         LEA      FILENAME(A6),A1
         JSR      (A2)
         PRINT    {LF,'"Find" string: "'}
         LEA      FINDSTR(A6),A1
         JSR      (A2)
         PRINT    {'"',LF,'Tab distance : '}
         MOVE.W   TABINC(A6),D1
         MOVEQ    #5,D2
         BSR      DS_NUM
         PRINT    {LF,'Left margin  : '}
         MOVE.W   LEFTMAR(A6),D1
         MOVEQ    #5,D2
         BSR      DS_NUM1
         PRINT    {LF,'Right margin : '}
         MOVE.W   RIGHTMAR(A6),D1
         MOVEQ    #5,D2
         BSR      DS_NUM1
         PRINT    {LF,'Block start  : '}
         MOVE.W   BLKSTART(A6),D1
         BSR      PRBLOKN
         PRINT    {LF,'Block end    : '}
         MOVE.W   BLKEND(A6),D1
         BSR      PRBLOKN
         PRINT    {LF,'Buffer size  : '}
         MOVE.L   TXTMAX(A6),D1
         SUB.L    TXTBASE(A6),D1
         LSL.L    #6,D1
         SWAP     D1
         MOVEQ    #5,D2
         BSR      DS_NUM
         PRINT    {'K',LF,'Buffer usage : '}
         MOVE.L   A7,A1
         SUBA.L   A6,A1
         SUBA.W   #32,A7
         MOVE.L   TXTEND(A6),D1
         SUB.L    TXTBASE(A6),D1
         BSR.S    PUT_FP
         MOVE.L   TXTMAX(A6),D1
         SUB.L    TXTBASE(A6),D1
         BSR.S    PUT_FP
         MOVE.W   RI_EXEC,A2
         MOVEQ    #$10,D0
         JSR      (A2)
         SUBQ.W   #6,A1
         MOVE.L   #$08076400,(A6,A1.L)
         CLR.W    4(A6,A1.L)
         MOVEQ    #$0E,D0
         JSR      (A2)
         MOVEQ    #2,D0
         JSR      (A2)
         MOVE.W   (A6,A1.L),D1
         ADDA.W   #32,A7
         MOVEQ    #5,D2
         BSR      DS_NUM
         MOVEQ    #'%',D1
         QDOS     IO.SBYTE
         MOVE.L   (A7)+,A2
         BSR.S    RET_KEY
         BRA      DSP_PAGE
RET_KEY  ERRMSG   {'Any key to continue '}
         SF       MSGPRNTD(A6)
         MOVE.L   CMDWIN(A6),A0
         QDOS     SD.CURE
         QDOS     IO.FBYTE
         QDOS     SD.CURS
         RTS

PRBLOKN  MOVEQ    #5,D2
         TST.W    D1
         BGE      DS_NUM1
         PRINT    {'Unset'}
         RTS

PUT_FP   MOVEQ    #0,D0
         TST.L    D1
         BEQ.S    PUT_FP_2
         MOVE.W   #$0820,D0
PUT_FP_L SUBQ.W   #1,D0
         ADD.L    D1,D1
         BVC      PUT_FP_L
         ROXR.L   #1,D1
PUT_FP_2 SUBQ.W   #6,A1
         MOVE.W   D0,(A6,A1.L)
         MOVE.L   D1,2(A6,A1.L)
         RTS

CMD_A    BSR      ARIGHT
         BSR      SPLIT_LN
         BRA.S    INS_STR
CMD_I    BSR      ALEFT
         BSR      SPLIT_LN
         BSR      UP
INS_STR  BSR      COPYLINE
         MOVE.W   D4,D1
         MOVE.W   D5,D2
         QDOS     SD.POS
         BSR      GETSTR
         BNE.S    AI_END
         MOVE.W   D1,D2
AI_LOOP  SUBQ.W   #1,D2
         BLT.S    AI_END
         MOVE.B   (A1)+,D1
         BSR      ADDCHR
         BRA      AI_LOOP
AI_END   RTS

F_GTSTR  BSR      GETSTR
         BNE.S    F_GTST_E
         LEA      FINDSTR(A6),A0
         MOVE.W   D1,(A0)+
         BRA.S    F_COPY_E
F_COPY_L MOVE.B   (A1)+,(A0)+
F_COPY_E DBF      D1,F_COPY_L
F_GTST_E RTS

CMD_F    BSR      F_GTSTR
         BRA.S    F_FORWD
CMD_BF   BSR      F_GTSTR
         BRA      F_BACKWD

DSP_SRCH ERRMSG   {'Searching for "'}
         MOVE.L   CMDWIN(A6),A0
         LEA      FINDSTR(A6),A1
         MOVE.W   (A1)+,D2
         QDOS     IO.SSTRG
         MOVEQ    #'"',D1
         QDOS     IO.SBYTE
         SF       MSGPRNTD(A6)
         RTS

CUP      BSR      DSP_SRCH
         BRA.S    F_BACKWD
CDOWN    BSR      DSP_SRCH
         BRA.S    F_FORWD

S_INIT   MOVE.L   (A7)+,A0
         TST.W    FINDSTR(A6)
         BEQ.S    S_IN_END
         BSR      ENT_LINE
         BSR      STORE_LN
         MOVEM.L  D6-D7/A2-A3,-(A7)
         SUB.W    D6,D4
         LEA      UCASETBL,A3
         BSR      GETSCRLN
         MOVE.L   A1,A2
         MOVEQ    #0,D0
         MOVEQ    #0,D1
         MOVEQ    #0,D2
         MOVE.B   FINDSTR+2(A6),D2
         MOVE.B   (A3,D2.W),D2
         JMP      (A0)
S_IN_END RTS

F_FORWD  BSR      S_INIT
         ADDQ.W   #1,D6
         ADDA.W   D6,A1
FF_NEWLN MOVEQ    #0,D3
         MOVE.B   (A5,D7.W),D3
         SUBQ.W   #1,D3
         SUB.W    D6,D3
         SUB.W    FINDSTR(A6),D3
         BLT.S    FF_NXTLN
FF_FIRST MOVE.B   (A1)+,D1
         CMP.B    (A3,D1.W),D2
         DBEQ     D3,FF_FIRST
         BNE.S    FF_NXTLN
         BSR      CMPSTR
         BEQ.S    S_MATCH
         SUBQ.W   #1,D3
         BGE      FF_FIRST
FF_NXTLN MOVE.B   (A5,D7.W),D0
         ADDA.W   D0,A2
         MOVE.L   A2,A1
         MOVEQ    #0,D6
         ADDQ.W   #1,D7
         CMP.W    MAXLINE(A6),D7
         BLS      FF_NEWLN
         BRA      S_FAILED

F_BACKWD BSR      S_INIT
BF_NEWLN LEA      1(A2,D6.W),A1
         SUBA.W   FINDSTR(A6),A1
         MOVE.W   D6,D3
         SUB.W    FINDSTR(A6),D3
         BLT.S    BF_NXTLN
BF_FIRST MOVE.B   -(A1),D1
         CMP.B    (A3,D1.W),D2
         DBEQ     D3,BF_FIRST
         BNE.S    BF_NXTLN
         ADDQ.W   #1,A1
         BSR.S    CMPSTR
         BEQ.S    S_MATCH
         SUBQ.W   #1,A1
         SUBQ.W   #1,D3
         BGE      BF_FIRST
BF_NXTLN SUBQ.W   #1,D7
         BLT.S    S_FAILED
         MOVE.B   (A5,D7.W),D6
         SUBA.W   D6,A2
         SUBQ.W   #1,D6
         BRA      BF_NEWLN
S_MATCH  MOVE.L   A1,D6
         SUB.L    A2,D6
         SUBQ.W   #1,D6
         MOVE.W   D7,D1
         ADDQ.W   #4,A7
         MOVEM.L  (A7)+,D7/A2-A3
         ADD.W    D6,D4
         BLT.S    S_MATCH2
         MOVE.W   D4,D0
         ADD.W    FINDSTR(A6),D0
         SUBQ.W   #1,D0
         CMP.W    WINWID(A6),D0
         BLT.S    S_MATCH3
         MOVE.W   WINWID(A6),D4
         SUB.W    FINDSTR(A6),D4
         BGE.S    S_REDRW
S_MATCH2 MOVEQ    #0,D4
         BRA.S    S_REDRW
S_MATCH3 MOVE.W   D1,D0
         SUB.W    D7,D0
         SUB.W    D5,D7
         ADD.W    D0,D5
         BLT.S    S_MATCH4
         CMP.W    WINLEN(A6),D5
         BGE.S    S_MATCH5
         ADD.W    D5,D7
         BRA.S    S_END
S_MATCH4 MOVE.W   WINLEN(A6),D5
         SUBQ.W   #1,D5
         ADD.W    D5,D7
         BRA.S    S_REDRW
S_MATCH5 MOVEQ    #0,D5
S_REDRW  BSR      FIND_DS1
S_END    RTS
S_FAILED MOVEM.L  (A7)+,D6-D7/A2-A3
         ADD.W    D6,D4
         ERRMSG   {'Search failed'}
         BRA      MAIN_ERR

CMPSTR   MOVEM.L  D3/A1,-(A7)
         MOVE.W   FINDSTR(A6),D3
         SUBQ.W   #2,D3
         BLT.S    CS_MATCH
         LEA      FINDSTR+3(A6),A0
CS_LOOP  MOVE.B   (A0)+,D0
         MOVE.B   (A3,D0.W),D0
         MOVE.B   (A1)+,D1
         CMP.B    (A3,D1.W),D0
         DBNE     D3,CS_LOOP
         MOVEM.L  (A7)+,D3/A1
         RTS
CS_MATCH MOVEM.L  (A7)+,D3/A1
         CMP.B    D0,D0
         RTS

UCASETBL DC.B     0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
         DC.B     16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31
         DC.B     ' !"#$%&''()*+,-./0123456789:;<=>?'
         DC.B     '@ABCDEFGHIJKLMNOPQRSTUVWXYZ',$5B,'\]^_'
         DC.B     '`ABCDEFGHIJKLMNOPQRSTUVWXYZ{|}~'
         DC.B     $A0,$A1,$A2,$A3,$A4,$A5,$A6,$A7,$A8,$A9,$AA,$AB,$8C,$8D,$8E,$8F
         DC.B     $90,$91,$92,$93,$94,$95,$96,$97,$98,$99,$9A,$9B,$9C,$9D,$9E,$9F
         DC.B     $A0,$A1,$A2,$A3,$A4,$A5,$A6,$A7,$A8,$A9,$AA,$AB,$AC,$AD,$AE,$AF
         DC.B     $B0,$B1,$B2,$B3,$B4,$B5,$B6,$B7,$B8,$B9,$BA,$BB,$BC,$BD,$BE,$BF
         DC.B     $C0,$C1,$C2,$C3,$C4,$C5,$C6,$C7,$C8,$C9,$CA,$CB,$CC,$CD,$CE,$CF
         DC.B     $D0,$D1,$D2,$D3,$D4,$D5,$D6,$D7,$D8,$D9,$DA,$DB,$DC,$DD,$DE,$DF
         DC.B     $E0,$E1,$E2,$E3,$E4,$E5,$E6,$E7,$E8,$E9,$EA,$EB,$EC,$ED,$EE,$EF
         DC.B     $F0,$F1,$F2,$F3,$F4,$F5,$F6,$F7,$F8,$F9,$FA,$FB,$FC,$FD,$FE,$FF

CMD_E    SF       -(A7)
         BRA.S    EX_1
CMD_EQ   ST       -(A7)
EX_1     BSR      F_GTSTR
         SUBQ.W   #1,A2
         BSR      GETSTR
         BNE      CMD_ERR
         MOVEM.L  D1/A1,-(A7)
         BSR      F_FORWD
         MOVE.W   D4,D1
         MOVE.W   D5,D2
         MOVEQ    #-1,D3
         MOVE.L   TXTWIN(A6),A0
         QDOS     SD.POS
         TST.B    8(A7)
         BEQ.S    GO_EXCH
         ERRMSG   {'Exchange? (Y/N) '}
         SF       MSGPRNTD(A6)
         QDOS     SD.CURE
         QDOS     IO.FBYTE
         MOVEQ    #$DF,D2
         AND.B    D1,D2
         QDOS     SD.CURS
         CMPI.B   #'Y',D2
         BNE.S    EX_END
GO_EXCH  BSR      COPYLINE
         MOVE.W   FINDSTR(A6),D1
         BSR      DEL_D1
         MOVEM.L  (A7),D2/A1
         MOVE.B   OVERWMOD(A6),-(A7)
         SF       OVERWMOD(A6)
EX_LOOP  SUBQ.W   #1,D2
         BLT.S    EX_END1
         MOVE.B   (A1)+,D1
         BSR      ADDCHR
         BRA      EX_LOOP
EX_END1  MOVE.B   (A7)+,OVERWMOD(A6)
EX_END   ADDA.W   #10,A7
         RTS

HELP     ERRMSG   {'Loading HELP file...'}
         LEA      HELPFNAM,A0
         MOVEQ    #1,D3
         BSR      OPENFILE
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
