* QED TEXT EDITOR by Jan Bredenbeek
* Start: 27 June 1988
* Release 1.00: August 1988
* Release 1.01: September 1988 (stable)
* Release 2.00beta: September 1994 (UNSTABLE!)
* Licenced under GPL v3 Licence (2017)
* See https://github.com/janbredenbeek/QED for latest version from the author
* This should be assembled and linked using the GST Macro Assembler and Linker
* (see http://www.dilwyn.me.uk/asm/index.html)
*
* Support Routines
*

         INCLUDE  WIN1_MACRO_LIB
         INCLUDE  WIN1_QDOS_IN_MAC
         INCLUDE  WIN2_QEDv2_QED_IN

         XREF     MAIN_ERR,REPORT_P,REPORT_I,END_FILE

         SECTION  CODE

*CONSTRUCT LINE LENGTH TABLE

         XDEF     MK_LNTBL

MK_LNTBL MOVEM.L  D1/D3/A0-A2,-(A7)
         MOVEM.L  TXTBASE(A6),A1-A2
         MOVEQ    #-1,D1
         MOVEQ    #LF,D3
MKL_LP   LEA      255(A1),A0
MKL_LP1  CMPA.L   A2,A1
         BHS.S    MKL_EN1
         CMPA.L   A0,A1
         BHS.S    MKL_INC
         CMP.B    (A1)+,D3
         BNE      MKL_LP1
MKL_INC  ADDQ.W   #1,D1
         BVC      MKL_LP
         MOVE.L   A1,TXTEND(A6)
         ERRMSG   {'Too many lines (>32768) - Extra ignored'}
         MOVE.W   #32767,D1
MKL_EN1  TST.W    D1
         IF LT THEN
            MOVEQ    #0,D1
            MOVE.L   TXTBASE(A6),A1
            MOVE.B   D3,(A1)+
            MOVE.L   A1,TXTEND(A6)
         ENDIF
         MOVE.W   D1,MAXLINE(A6)
         ADDI.W   #256,D1
         BSR      ALLOC_LN
         BLE.S    MKL_END
MKL_TRNC ERRMSG   {'Long lines split'}
MKL_END  MOVEM.L  (A7)+,D1/D3/A0-A2
         TST.L    D0
         RTS

* INSERT D1 ENTRIES IN LINE TABLE

         XDEF     INSRT_LN

INSRT_LN MOVEQ    #0,D0
         MOVEM.L  D0/A1-A2,-(A7)
         MOVEQ    #-1,D0
         MOVE.L   D0,BLKSTART(A6)
         MOVE.W   MAXLINE(A6),D0
         ADD.W    D1,D0
         BVS.S    ILN_ERR2
         CMP.W    LNTBLSIZ(A6),D0
         BLO.S    ILN_MOVE
         MOVEM.L  D0-D3/A0/A3,-(A7)
         MOVE.L   A5,A0
         QDOS     MT.RECHP
         MOVE.L   (A7),D1
         ADDI.W   #256,D1
         BSR.S    ALLOC_LN
         MOVE.L   D0,24(A7)
         MOVEM.L  (A7)+,D0-D3/A0/A3
         BLT.S    ILN_ERR
ILN_MOVE MOVE.W   D0,MAXLINE(A6)
         SUB.W    D1,D0
         ADDQ.W   #1,D0
         LEA      (A5,D0.W),A1
         LEA      (A1,D1.W),A2
         SUB.W    D7,D0
         BRA.S    ILN_MVE
ILN_MVL  MOVE.B   -(A1),-(A2)
ILN_MVE  DBF      D0,ILN_MVL
         MOVEQ    #0,D0
ILN_END  MOVEM.L  (A7)+,D0/A1-A2
         TST.L    D0
         RTS
ILN_ERR2 ERRMSG   {'Too many lines (>32767)'}
         MOVEQ    #ERR.OR,D0
         BRA      ILN_END
ILN_ERR  ERRMSG   {'No room for line table'}
         SF       EDIT_LN(A6)
         SUBA.L   A5,A5
         MOVEQ    #ERR.OM,D0
         BRA      ILN_END

*ALLOCATE AND CONSTRUCT LINE LENGTH TABLE

ALLOC_LN MOVEM.L  D2-D4/A0-A3,-(A7)
         ANDI.L   #$FFFF,D1
         MOVEQ    #-1,D2
         QDOS     MT.ALCHP
         TST.L    D0
         BNE.S    ALN_ERR
         MOVE.L   A0,A5
         SUBI.W   #$10,D1
         MOVE.W   D1,LNTBLSIZ(A6)
         MOVEM.L  TXTBASE(A6),A1-A2
         MOVEQ    #0,D0
         MOVEQ    #0,D2
         MOVEQ    #LF,D3
         MOVE.L   #255,D4
ALN_NEWL MOVE.L   A1,A0
         LEA      (A0,D4.W),A3
ALN_LP   CMPA.L   A2,A1
         BHS.S    ALN_END
         CMPA.L   A3,A1
         BHS.S    ALN_LONG
         CMP.B    (A1)+,D3
         BNE      ALN_LP
ALN_LEN  MOVE.L   A1,D1
         SUB.L    A0,D1
         MOVE.B   D1,(A5,D2.W)
         ADDQ.W   #1,D2
         BRA      ALN_NEWL
ALN_LONG MOVEQ    #1,D0
         BRA      ALN_LEN
ALN_END  MOVE.L   A0,TXTEND(A6)
ALN_ERR  MOVEM.L  (A7)+,D2-D4/A0-A3
         TST.L    D0
         RTS

* DELETE D1 ENTRIES FROM LINE TABLE

         XDEF     DEL_LNTB

DEL_LNTB MOVEM.L  A1-A2,-(A7)
         MOVEQ    #-1,D0
         MOVE.L   D0,BLKSTART(A6)
         SUB.W    D1,MAXLINE(A6)
         LEA      (A5,D7.W),A2
         LEA      (A2,D1.W),A1
         MOVE.W   MAXLINE(A6),D0
         SUB.W    D7,D0
         ADDQ.W   #1,D0
         BRA.S    DLN_MVE
DLN_MVL  MOVE.B   (A1)+,(A2)+
DLN_MVE  DBF      D0,DLN_MVL
         MOVEM.L  (A7)+,A1-A2
         RTS

* Compress spaces into tabs
* Entry: D1 line length, A1 ptr to line
* Exit : D1 new line length, other regs preserved

         XDEF     CMPTABS

CMPTABS  TST.B    TABCOMPR(A6)
         BEQ      CT_RTS
         MOVEM.L  D0/D2-D4/A0-A1,-(A7)
         MOVE.L   A1,A0
         MOVEQ    #0,D2
         MOVEQ    #-1,D3
         MOVEQ    #0,D4
CT_LOOP  SUBQ.W   #1,D1
         BLT.S    CT_DOSPC
         MOVE.B   (A1)+,D0
         CMPI.B   #$27,D0           Single quote
         BEQ.S    CT_QUOTE
         CMPI.B   #$22,D0           Double quote
         BEQ.S    CT_QUOTE
         TST.B    D4
         BNE.S    CT_NOSPC
         CMPI.B   #' ',D0
         BEQ.S    CT_SPACE
         CMPI.B   #TAB,D0
         BEQ.S    CT_SPACE
CT_TEST  TST.W    D3
         BPL.S    CT_DOSPC
CT_NOSPC MOVE.B   D0,(A0)+
CT_INC   ADDQ.W   #1,D2
         BRA      CT_LOOP
CT_QUOTE TST.B    D4
         BNE.S    CT_QOUT
         MOVE.B   D0,D4
         BRA      CT_TEST
CT_QOUT  CMP.B    D0,D4
         BNE      CT_NOSPC
         MOVEQ    #0,D4
         BRA      CT_NOSPC
CT_SPACE TST.W    D3
         BPL.S    CT_SPC2
         MOVE.L   D2,D3
CT_SPC2  CMPI.B   #TAB,D0
         BNE      CT_INC
         BSR.S    DO_TAB
         BRA      CT_LOOP
CT_DOSPC TST.W    D3
         BMI.S    CT_END
         MOVE.L   D2,D0
         DIVU     TABINC(A6),D0
         DIVU     TABINC(A6),D3
         SUB.W    D3,D0
         BNE.S    CT_TABS
         SWAP     D0
         SWAP     D3
         SUB.W    D3,D0
         BRA.S    CT_SPCSN
CT_TABS  MOVE.B   #TAB,(A0)+
         SUBQ.W   #1,D0
         BGT      CT_TABS
         SWAP     D0
         BRA.S    CT_SPCSN
CT_SPCS  MOVE.B   #' ',(A0)+
CT_SPCSN DBF      D0,CT_SPCS
         MOVE.B   -1(A1),D0
         MOVEQ    #-1,D3
         TST.W    D1
         BGE      CT_NOSPC
CT_END   MOVE.L   A0,D1
         MOVEM.L  (A7)+,D0/D2-D4/A0-A1
         SUB.L    A1,D1
CT_RTS   RTS

* Advance to next tab position
* Entry: D2.L current column position
* Exit : D0   # of columns to advance
*        D2   new column position

DO_TAB   MOVE.L   D2,D0
         DIVU     TABINC(A6),D0
         SWAP     D0
         NEG.W    D0
         ADD.W    TABINC(A6),D0
         ADD.W    D0,D2
         RTS

*ENTER EDITED LINE INTO TEXT FILE

         XDEF     ENT_LINE,ENT_LIN1

ENT_LIN1 MOVEQ    #1,D0
         BRA.S    EL_TEST
ENT_LINE MOVEQ    #0,D0
EL_TEST  CMPA.W   #0,A5
         BEQ.S    NO_LNTBL
         TST.B    EDIT_LN(A6)
         BEQ.S    EL_RTS
         SF       EDIT_LN(A6)
         MOVEM.L  D0-D2/A1/A3,-(A7)
         MOVEQ    #0,D1
         MOVE.W   LINELEN(A6),D1
         MOVE.L   A3,A1
         BSR      CMPTABS
         MOVE.W   D1,LINELEN(A6)
         BSR      STRIPSPC
         MOVE.W   D1,D2
         ADD.W    D0,D1
         ADDQ.W   #1,D1
         MOVE.B   (A5,D7.W),D0
         SUB.L    D0,D1
         BSR.S    GETSCRLN
         BSR      MOV_TXT
         BNE.S    EL_ERR
         ADD.B    D1,(A5,D7.W)
         BRA.S    EL_COPYE
EL_COPYL MOVE.B   (A3)+,(A1)+
EL_COPYE DBF      D2,EL_COPYL
         TST.L    (A7)
         BEQ.S    EL_END
         MOVE.B   #LF,(A1)
EL_END   MOVEM.L  (A7)+,D0-D2/A1/A3
EL_RTS   RTS
         XDEF     EL_ERR,NO_LNTBL
EL_ERR   BSR      DSP_PAGE
         ERRMSG   {'No room for text'}
         BRA      MAIN_ERR
NO_LNTBL ERRMSG   {'No room for line table - SAVE first'}
         BRA      MAIN_ERR

* GET ADDR OF SCREEN LINE IN A1

         XDEF     GETSCRLN

GETSCRLN MOVEM.L  D0-D1,-(A7)
         MOVE.L   A4,A1
         MOVE.W   D5,D1
         BEQ.S    GSL_END
         MOVEQ    #0,D0
         SUB.W    D5,D7
GSL_LOOP MOVE.B   (A5,D7.W),D0
         ADDQ.W   #1,D7
         ADDA.W   D0,A1
         SUBQ.W   #1,D1
         BNE      GSL_LOOP
GSL_END  MOVEM.L  (A7)+,D0-D1
         RTS

* Get # of chars to be indented in D1 (either leftmargin or autoindent)

         XDEF     GET_INDT

GET_INDT MOVE.W   LEFTMAR(A6),D1
         TST.B    AUTOINDT(A6)
         BEQ.S    GI_END
         MOVEM.L  D0/D2/D7/A0-A1,-(A7)
         BSR      GETSCRLN
GI_FINDL MOVE.L   A1,A0
         MOVEQ    #0,D2
         MOVE.B   (A5,D7.W),D1
GI_LOOP  SUBQ.B   #1,D1
         BLS.S    GI_PREVL
         CMPI.B   #TAB,(A0)
         BEQ.S    GI_TAB
         ADDQ.W   #1,D2
         CMPI.B   #' ',(A0)+
         BEQ.S    GI_LOOP
         SUBQ.W   #1,D2
         BRA.S    GI_END1
GI_TAB   BSR      DO_TAB
         ADDQ.L   #1,A0
         BRA      GI_LOOP
GI_PREVL MOVEQ    #0,D2
         SUBQ.W   #1,D7
         BLO.S    GI_END1
         MOVE.B   (A5,D7.W),D2
         SUBA.L   D2,A1
         BRA      GI_FINDL
GI_END1  MOVE.W   D2,D1
         MOVEM.L  (A7)+,D0/D2/D7/A0-A1
GI_END   RTS

* MOVE TEXT FROM A1 TO TXTEND D1 BYTES FORWARD/BACKWARD

         XDEF     MOV_TXT

MOV_TXT  MOVEM.L  D1/A0-A2,-(A7)
         MOVE.L   TXTEND(A6),A0
         LEA      (A0,D1.L),A2
         CMPA.L   TXTMAX(A6),A2
         BHI      MT_OM
         ST       EDIT_TXT(A6)
         MOVE.L   A2,TXTEND(A6)
         MOVE.L   A0,D0
         SUB.L    A1,D0
         NEG.L    D1
         BGT.S    MT_RECLM
         BEQ.S    MT_OK
         ROR.L    #4,D0
         BRA.S    MT_ILP1E
MT_ILP1S MOVE.B   -(A0),-(A2)
         MOVE.B   -(A0),-(A2)
         MOVE.B   -(A0),-(A2)
         MOVE.B   -(A0),-(A2)
         MOVE.B   -(A0),-(A2)
         MOVE.B   -(A0),-(A2)
         MOVE.B   -(A0),-(A2)
         MOVE.B   -(A0),-(A2)
         MOVE.B   -(A0),-(A2)
         MOVE.B   -(A0),-(A2)
         MOVE.B   -(A0),-(A2)
         MOVE.B   -(A0),-(A2)
         MOVE.B   -(A0),-(A2)
         MOVE.B   -(A0),-(A2)
         MOVE.B   -(A0),-(A2)
         MOVE.B   -(A0),-(A2)
MT_ILP1E DBF      D0,MT_ILP1S
         CLR.W    D0
         ROL.L    #4,D0
         BRA.S    MT_ILP2E
MT_ILP2S MOVE.B   -(A0),-(A2)
MT_ILP2E DBF      D0,MT_ILP2S
         BRA.S    MT_OK
MT_RECLM LEA      (A1,D1.L),A2
         SUB.L    D1,D0
         BLE.S    MT_OK
         ROR.L    #4,D0
         BRA.S    MT_DLP1E
MT_DLP1S MOVE.B   (A2)+,(A1)+
         MOVE.B   (A2)+,(A1)+
         MOVE.B   (A2)+,(A1)+
         MOVE.B   (A2)+,(A1)+
         MOVE.B   (A2)+,(A1)+
         MOVE.B   (A2)+,(A1)+
         MOVE.B   (A2)+,(A1)+
         MOVE.B   (A2)+,(A1)+
         MOVE.B   (A2)+,(A1)+
         MOVE.B   (A2)+,(A1)+
         MOVE.B   (A2)+,(A1)+
         MOVE.B   (A2)+,(A1)+
         MOVE.B   (A2)+,(A1)+
         MOVE.B   (A2)+,(A1)+
         MOVE.B   (A2)+,(A1)+
         MOVE.B   (A2)+,(A1)+
MT_DLP1E DBF      D0,MT_DLP1S
         CLR.W    D0
         ROL.L    #4,D0
         BRA.S    MT_DLP2E
MT_DLP2S MOVE.B   (A2)+,(A1)+
MT_DLP2E DBF      D0,MT_DLP2S
MT_OK    MOVEQ    #0,D0
         BRA.S    MT_RTS
MT_OM    MOVEQ    #ERR.OM,D0
MT_RTS   MOVEM.L  (A7)+,D1/A0-A2
         RTS

* REMOVE TRAILING SPACES FROM BUFFER LINE
* EXIT: D1 LENGTH OF LINE WITHOUT TRAILING SPACES

         XDEF     STRIPSPC

STRIPSPC MOVE.W   LINELEN(A6),D1
         BEQ.S    SS_END
SS_LOOP  CMP.B    #' ',-1(A3,D1.W)
         BEQ.S    SS_STRIP
         CMP.B    #TAB,-1(A3,D1.W)
         BNE.S    SS_END
SS_STRIP SUBQ.W   #1,D1
         BNE      SS_LOOP
SS_END   MOVE.W   D1,LINELEN(A6)
         RTS

* COPY LINE TO EDIT BUFFER
* A3: START OF LINE, D7: LINE NUMBER

         XDEF     COPYLINE

COPYLINE MOVE.L   A5,D0
         BEQ      NO_LNTBL
         TAS      EDIT_LN(A6)
         BNE.S    CL_END
         MOVEM.L  D1/A1,-(A7)
         BSR      GETSCRLN
         MOVEQ    #0,D1
         MOVE.B   (A5,D7.W),D1
         CMPI.B   #LF,-1(A1,D1.W)
         IF EQ THEN
            SUBQ.W   #1,D1
         ENDIF
         MOVE.W   D1,LINELEN(A6)
         MOVE.L   A3,-(A7)
         TST.B    TABEXPND(A6)
         BEQ.S    CL_CP_E
         MOVE.L   D3,-(A7)
         MOVE.L   #255,D3
         BSR.S    CL_COPY
         MOVE.L   (A7)+,D3
         MOVE.W   D1,LINELEN(A6)
         BRA.S    CL_STRIP
CL_CP_L  MOVE.B   (A1)+,(A3)+
CL_CP_E  DBF      D1,CL_CP_L
CL_STRIP MOVE.L   (A7)+,A3
         BSR      STRIPSPC
         MOVEM.L  (A7)+,D1/A1
CL_END   RTS

* Copy line from (A1) to (A3) (length in D1)
* D3: Maximum size of destination buffer
* Expands TAB characters

         XDEF     CL_COPY

CL_COPY  MOVEM.L  D0/D2,-(A7)
         MOVEQ    #0,D2
         BRA.S    CL_COPYN
CL_COPYL CMPI.B   #TAB,(A1)
         BEQ.S    CLC_TAB
         MOVE.B   (A1)+,(A3)+
         ADDQ.W   #1,D2
         BRA.S    CL_COPYN
CLC_TAB  BSR      DO_TAB
         CMP.L    D3,D2
         BLS.S    CL_CPSPC
         SUB.W    D0,D2
         BRA.S    CL_COPYE
CL_CPSPC MOVE.B   #' ',(A3)+
         SUBQ.W   #1,D0
         BGT      CL_CPSPC
         ADDQ.L   #1,A1
CL_COPYN CMP.L    D3,D2
         DBHS     D1,CL_COPYL
CL_COPYE MOVE.W   D2,D1
         MOVEM.L  (A7)+,D0/D2
         RTS

* DISPLAY A PAGE OF TEXT
* A4: START OF TOP LINE

         XDEF     DSP_PAGE

DSP_PAGE MOVEM.L  D1/D4-D7/A1,-(A7)
         MOVE.L   TXTWIN(A6),A0
         MOVEQ    #-1,D3
         QDOS     SD.CLEAR
         MOVE.L   A4,A1
         SUB.W    D4,D6
         SUB.W    D5,D7
         MOVEQ    #0,D4
         MOVEQ    #0,D5
DSPP_LP  CMP.W    18(A7),D7         Current line?
         BNE.S    DSPP_LIN          No
         TST.B    EDIT_LN(A6)       Line is being edited?
         BEQ.S    DSPP_LIN          No
         BSR.S    DSP_BUF           Display buffer rather than line from file
         BRA.S    DSPP_NXT
DSPP_LIN BSR.S    DSP_LINE
DSPP_NXT MOVEQ    #0,D0
         MOVE.B   (A5,D7.W),D0
         ADDA.W   D0,A1
         ADDQ.W   #1,D7
         CMP.W    MAXLINE(A6),D7
         BHI.S    DSPP_END
         ADDQ.W   #1,D5
         CMP.W    WINLEN(A6),D5
         BLT      DSPP_LP
DSPP_END MOVEM.L  (A7)+,D1/D4-D7/A1
         RTS

* DISPLAY LINE NR. D7 AT ROW D5 ON SCREEN FROM COL. D4/D6

         XDEF     DSP_BUF,DSP_LINE

DSP_BUF  MOVEM.L  D1-D2/D4/D6/A1,-(A7)    DISPLAY LINE IN EDIT BUFFER
         LEA      LINEBUF(A6),A1
         MOVE.W   LINELEN(A6),D1
         BRA.S    DSPLIN_0
DSP_LINE MOVEM.L  D1-D2/D4/D6/A1,-(A7)    DISPLAY LINE AT (A1)
         MOVEQ    #0,D1
         MOVE.B   (A5,D7.W),D1
         CMPI.B   #LF,-1(A1,D1.W)
         BNE.S    DSPLIN_0
         SUBQ.W   #1,D1             Don't display trailing LF
DSPLIN_0 MOVEM.L  D1/A1,-(A7)
         MOVE.W   D4,D1
         MOVE.W   D5,D2
         MOVEQ    #-1,D3
         MOVE.L   TXTWIN(A6),A0
         QDOS     SD.POS
         MOVEM.L  (A7)+,D1/A1
         TST.B    TABEXPND(A6)      Should TABs be expanded?
         BNE.S    DS_TAB            Yes
         SUB.W    D6,D1             If not, code is straightforward
         BLE      DSPL_END
         MOVE.W   WINWID(A6),D2
         SUB.W    D4,D2
         BLE      DSPL_END
         CMP.W    D1,D2
         BLE.S    DSPLIN_1
         MOVE.W   D1,D2
DSPLIN_1 ADDA.W   D6,A1
         QDOS     IO.SSTRG
         BRA.S    DSPL_END

* the following code handles displaying of lines where TABs are required
* to be displayed as expected. First of all, we have to skip characters until
* we are at least at column D6.

DS_TAB   MOVEQ    #0,D2             Start at column zero.
         BRA.S    DST_NXT
DST_LP   CMPI.B   #TAB,(A1)+        TAB found?
         BEQ.S    DST_TAB           Yes
         ADDQ.W   #1,D2             if not, simply bump column by one
         BRA.S    DST_NXT
DST_TAB  BSR      DO_TAB            Advance D2 to next tab stop
DST_NXT  CMP.W    D6,D2             Are we now at column D6?
         DBGE     D1,DST_LP         If not loop back unless physical EOL
         SUB.W    D6,D2             D2 = columns to advance cursor (if any)
         BLE.S    DST_DSP
DST_CTAB ADD.W    D2,D4
         ADD.W    D2,D6
         MOVEM.L  D1/A1,-(A7)
         MOVE.W   D4,D1
         QDOS     SD.TAB
         MOVEM.L  (A7)+,D1/A1

* Now enter a loop to print each portion of the line between TABs

DST_DSP  CMP.W    WINWID(A6),D4     End of window reached?
         BGE.S    DSPL_END          Yes
         SUBQ.W   #1,D1             Decrease character count
         BLT.S    DSPL_END
         CMPI.B   #TAB,(A1)+        Is it a TAB?
         BNE.S    DST_NTAB          no
         MOVEQ    #0,D2
         MOVE.W   D6,D2             Get logical column pos
         BSR      DO_TAB            ...and move to next tab stop
         MOVE.W   D0,D2
         BRA      DST_CTAB          Jump back to advance cursor
DST_NTAB PEA      -1(A1)            Push original ptr
DST_NTLP SUBQ.W   #1,D1
         BLT.S    DST_NTEN
         CMPI.B   #TAB,(A1)+
         BNE      DST_NTLP
         ADDQ.W   #1,D1
         SUBQ.L   #1,A1
DST_NTEN MOVE.L   A1,D2
         MOVE.L   (A7)+,A1
         SUB.L    A1,D2
         MOVE.W   WINWID(A6),D0
         SUB.W    D4,D0
         CMP.W    D0,D2
         BLE.S    DST_NTOT
         MOVE.W   D0,D2
DST_NTOT MOVE.L   D1,-(A7)
         QDOS     IO.SSTRG
         MOVE.L   (A7)+,D1
         ADD.W    D2,D4
         ADD.W    D2,D6
         BRA      DST_DSP
DSPL_END MOVEM.L  (A7)+,D1-D2/D4/D6/A1
         RTS

* Open file with TK2 DATA_USE default
* Entry: D3 access key, (A0) filename

         XDEF     OPEN_DEF,OPENFILE

OPEN_DEF MOVEM.L  D1-D3/A0-A2,-(A7)
         MOVEQ    #-1,D1
         MOVEQ    #IO.DIR,D3        Valid directory name?
         QDOS     IO.OPEN
         TST.L    D0
         BEQ.S    OD_CLOSE          Yes
         MOVE.L   D0,-(A7)
         QDOS     MT.INF
         MOVE.L   (A7)+,D0
         LEA      $B0(A0),A0        Get TK2 DATA_USE ptr
         TST.L    (A0)
         BEQ.S    OF_END            Exit with error code if no TK2
         MOVE.L   (A0),A1           A1 points to dir string
         MOVE.L   12(A7),A0         Pointer to filename
         MOVE.W   (A0),D0
         MOVE.W   (A1)+,D1
         MOVE.W   D0,D2
         ADD.W    D1,D2
         CMPI.W   #44,D2
         BGT.S    OD_BADNM          Reject name if going to be too long
         MOVE.W   D2,(A0)+
         LEA      (A0,D1.W),A2
         BRA.S    OD_MOV1N
OD_MOV1L MOVE.B   (A0,D0.W),(A2,D0.W)  Move up filename in buffer
OD_MOV1N DBF      D0,OD_MOV1L
         BRA.S    OD_MOV2N
OD_MOV2L MOVE.B   (A1)+,(A0)+       Insert directory
OD_MOV2N DBF      D1,OD_MOV2L
         BRA.S    OF_AGAIN          Retry OPEN with default dir
OD_CLOSE QDOS     IO.CLOSE          Close directory channel
         BRA.S    OF_AGAIN          Try OPEN raw name
OD_BADNM MOVEQ    #ERR.BN,D0
         BRA.S    OF_END

* Open channel; D3 access key, A0 channel name
* Exit: D0 error code, A0 channel ID, other regs preserved

OPENFILE MOVEM.L  D1-D3/A0-A2,-(A7)
OF_AGAIN MOVEQ    #-1,D1
         MOVE.B   11(A7),D3         Get original name and key
         MOVE.L   12(A7),A0
         QDOS     IO.OPEN
         TST.L    D0
         BEQ.S    OF_OK             Exit if OK
         CMPI.L   #ERR.EX,D0        "Already exists"?
         BNE.S    OF_END            Exit if not
         CMPI.B   #IO.OVER,D3       Return an error if we didn't
         BNE.S    OF_END            request an overwrite
OF_DELET MOVEQ    #-1,D1            This code handles drivers which don't
         MOVE.L   12(A7),A0         support overwrite (old MDV etc)
         QDOS     IO.DELET          Delete old version
         BRA      OF_AGAIN          Loop back to open new
OF_OK    MOVE.L   A0,12(A7)
OF_END   MOVEM.L  (A7)+,D1-D3/A0-A2
         TST.L    D0
         RTS

*DISPLAY ERROR MESSAGE AT (A1)

         XDEF     ERRMSG

ERRMSG   MOVEM.L  D0-D3/A0-A1,-(A7)
         MOVE.L   CMDWIN(A6),A0
         MOVEQ    #-1,D3
         MOVE.B   REPORT_P,D1
         QDOS     SD.SETPA
         MOVE.B   REPORT_P,D1
         QDOS     SD.SETST
         MOVE.B   REPORT_I,D1
         QDOS     SD.SETIN
         QDOS     SD.CLEAR
         MOVE.L   20(A7),A1
         MOVE.W   (A1)+,D2
         QDOS     IO.SSTRG
         ST       MSGPRNTD(A6)
         SF       STPRINTD(A6)
         MOVEM.L  (A7)+,D0-D3/A0-A1
         RTS

*DISPLAY STATUS

         XDEF     DISPSTAT

DISPSTAT MOVEM.L  A0-A2,-(A7)
         MOVE.L   CMDWIN(A6),A0
         MOVEQ    #-1,D3
         TAS      STPRINTD(A6)
         BNE.S    DS_PARMS
         MOVE.B   REPORT_P,D1
         QDOS     SD.SETPA
         MOVE.B   REPORT_P,D1
         QDOS     SD.SETST
         MOVE.B   REPORT_I,D1
         QDOS     SD.SETIN
         QDOS     SD.CLEAR
         PRINT    {'L:        C:      N:        Mode: '}
         MOVE.W   #'OI',D1
         TST.B    OVERWMOD(A6)
         BSR.S    DS_MODE
         MOVE.W   #'A ',D1
         TST.B    AUTOINDT(A6)
         BSR.S    DS_MODE
         MOVE.W   #'T ',D1
         TST.B    TABCOMPR(A6)
         BSR.S    DS_MODE
         MOVE.W   #'W ',D1
         TST.B    WORDWRAP(A6)
         BSR.S    DS_MODE
         MOVEQ    #41,D1
         QDOS     SD.TAB
         LEA      FILENAME(A6),A1
         MOVE.W   (A1)+,D2
         MOVE.W   WINWID(A6),D0
         SUBI.W   #41,D0
         CMP.W    D0,D2
         BLE.S    DS_FNAME
         MOVE.W   D0,D2
DS_FNAME QDOS     IO.SSTRG
DS_PARMS MOVEQ    #3,D1
         QDOS     SD.TAB
         MOVE.W   D7,D1
         MOVEQ    #5,D2
         BSR.S    DS_NUM1
         MOVEQ    #13,D1
         QDOS     SD.TAB
         MOVE.W   D6,D1
         MOVEQ    #3,D2
         BSR.S    DS_NUM1
         MOVEQ    #21,D1
         QDOS     SD.TAB
         MOVE.W   MAXLINE(A6),D1
         MOVEQ    #5,D2
         BSR.S    DS_NUM1
         MOVEQ    #40,D1
         QDOS     SD.TAB
         MOVE.W   #'* ',D1
         TST.B    EDIT_TXT(A6)
         BSR.S    DS_MODE
         MOVEM.L  (A7)+,A0-A2
         RTS

DS_MODE  BEQ.S    DS_MODE1
         LSR.W    #8,D1
DS_MODE1 QDOS     IO.SBYTE
         RTS

         XDEF     DS_NUM,DS_NUM1


DS_NUM1  ADDQ.W   #1,D1
DS_NUM   SUBQ.W   #6,A7
         MOVE.L   A7,A1
         BSR.S    ITOD
         MOVE.L   A7,A1
         QDOS     IO.SSTRG
         ADDQ.W   #6,A7
         RTS

* CONVERT UNSIGNED WORD INT TO DECIMAL (R. JUSTIFIED SPACE FILL)
* D1 VALUE, D2 FIELD WIDTH, A1 RESULT POINTER

         XDEF     ITOD

ITOD     MOVEM.L  D1-D2,-(A7)
         CMPI.W   #9,D1
         BHI.S    ITOD_2
ITOD_FL  SUBQ.B   #1,D2
         BLE.S    ITOD_3
         MOVE.B   #' ',(A1)+
         BRA      ITOD_FL
ITOD_2   ANDI.L   #$FFFF,D1
         DIVU     #10,D1
         SUBQ.W   #1,D2
         BSR      ITOD
         SWAP     D1
ITOD_3   ADDI.B   #'0',D1
         MOVE.B   D1,(A1)+
         MOVEM.L  (A7)+,D1-D2
         RTS

* CONVERT DECIMAL NUMBER TO WORD INT
* A1 POINTER TO DEC., D1 RESULT

         XDEF     READNUM

READNUM  MOVEQ    #0,D1
         MOVEQ    #0,D0
RDNUM_LP MOVE.B   (A1),D0
         SUBI.B   #'0',D0
         CMPI.B   #9,D0
         BHI.S    RDNUM_EN
         ADDQ.W   #1,A1
         MULU     #10,D1
         ADD.W    D0,D1
         BRA      RDNUM_LP
RDNUM_EN MOVEQ    #0,D0
         RTS

*FIND LINE D1 AND DISPLAY PAGE

         XDEF     FIND_DSP,FIND_DS1

FIND_DSP MOVEQ    #0,D4
         MOVEQ    #0,D6
FIND_DS1 BSR      ENT_LINE
         MOVEQ    #0,D2
         CMP.W    MAXLINE(A6),D1
         BLS.S    FD_1
         MOVE.W   MAXLINE(A6),D1
         MOVEQ    #-1,D2
FD_1     MOVE.W   D5,D3
         SUB.W    D3,D1
         BGE.S    FD_2
         ADD.W    D1,D3
         MOVEQ    #0,D1
FD_2     MOVE.W   WINLEN(A6),D0
         SUBQ.W   #1,D0
         ADD.W    D1,D0
         SUB.W    MAXLINE(A6),D0
         BLS.S    FD_3
         ADD.W    D0,D3
         SUB.W    D0,D1
         BGE.S    FD_3
         ADD.W    D1,D3
         MOVEQ    #0,D1
FD_3     BSR.S    FINDLINE
         MOVE.L   A1,A4
         MOVE.W   D3,D5
         MOVE.W   D1,D7
         ADD.W    D5,D7
         BSR      DSP_PAGE
         TST.B    D2
         BLT      END_FILE
         RTS

*FIND ADDR OF LINE D1 (IN A1)

         XDEF     FINDLINE

FINDLINE MOVEM.L  D7/A0,-(A7)
         SUB.W    D5,D7
         LEA      (A5,D7.W),A0
         MOVE.L   A4,A1
         SUB.W    D1,D7
         BGT.S    FL_BACK
         BEQ.S    FL_END
         NEG.W    D7
         MOVEQ    #0,D0
         MOVE.W   MAXLINE(A6),D0
         ADDQ.W   #1,D0
         SUB.W    D1,D0
         CMP.W    D7,D0
         BGE.S    FL_UP
         MOVE.W   D0,D7
         ADD.W    D1,D0
         LEA      (A5,D0.L),A0
         MOVE.L   TXTEND(A6),A1
         BRA.S    FL_DOWN
FL_BACK  CMP.W    D7,D1
         BGE.S    FL_DOWN
         MOVE.L   A5,A0
         MOVE.L   TXTBASE(A6),A1
         MOVE.W   D1,D7
         BEQ.S    FL_END
FL_UP    MOVEQ    #0,D0
FL_ULP   MOVE.B   (A0)+,D0
         ADDA.W   D0,A1
         SUBQ.W   #1,D7
         BNE      FL_ULP
         BRA.S    FL_END
FL_DOWN  MOVEQ    #0,D0
FL_DLP   MOVE.B   -(A0),D0
         SUBA.W   D0,A1
         SUBQ.W   #1,D7
         BNE      FL_DLP
FL_END   MOVEM.L  (A7)+,D7/A0
         RTS

         SECTION  MSG
         DC.W     0

         END
