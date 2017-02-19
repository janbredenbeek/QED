* QED TEXT EDITOR by Jan Bredenbeek
* Start: 27 June 1988
* Release 1.00: August 1988
* Release 1.01: September 1988 (stable)
* Licenced under GPL v3 Licence (2017)
* See https://github.com/janbredenbeek/QED for latest version from the author
* This should be assembled and linked using the GST Macro Assembler and Linker
* (see http://www.dilwyn.me.uk/asm/index.html)
*
* Support routines
*

         INCLUDE  FLP1_MACRO_LIB
         INCLUDE  FLP1_QDOS_IN_MAC
         INCLUDE  FLP2_QED_DEF

         XREF     MAIN_ERR,REPORT_P,REPORT_I,END_FILE

         SECTION  CODE

*CONSTRUCT LINE LENGTH TABLE

         XDEF     MK_LNTBL

MK_LNTBL MOVEM.L  D1/D3/A1-A2,-(A7)
         MOVEM.L  TXTBASE(A6),A1-A2
         MOVEQ    #-1,D1
         MOVEQ    #LF,D3
MKL_LP   CMPA.L   A2,A1
         BHS.S    MKL_EN1
         CMP.B    (A1)+,D3
         BNE      MKL_LP
         ADDQ.W   #1,D1
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
         BSR.S    ALLOC_LN
         BEQ.S    MKL_END
MKL_TRNC ERRMSG   {'Lines truncated'}
MKL_END  MOVEM.L  (A7)+,D1/D3/A1-A2
         RTS

* INSERT D1 ENTRIES IN LINE TABLE

         XDEF     INSRT_LN

INSRT_LN MOVEM.L  A1-A2,-(A7)
         MOVEQ    #-1,D0
         MOVE.L   D0,BLKSTART(A6)
         MOVE.W   MAXLINE(A6),D0
         ADD.W    D1,D0
         BVS.S    ALN_ERR
         CMP.W    LNTBLSIZ(A6),D0
         BLO.S    ILN_MOVE
         MOVEM.L  D0-D3/A0/A3,-(A7)
         MOVE.L   A5,A0
         QDOS     MT.RECHP
         MOVE.L   (A7),D1
         ADDI.W   #256,D1
         BSR.S    ALLOC_LN
         MOVEM.L  (A7)+,D0-D3/A0/A3
ILN_MOVE MOVE.W   D0,MAXLINE(A6)
         SUB.W    D1,D0
         ADDQ.W   #1,D0
         LEA      (A5,D0.W),A1
         LEA      (A1,D1.W),A2
         SUB.W    D7,D0
         BRA.S    ILN_MVE
ILN_MVL  MOVE.B   -(A1),-(A2)
ILN_MVE  DBF      D0,ILN_MVL
         MOVEM.L  (A7)+,A1-A2
         RTS
ALN_ERR  ERRMSG   {'No room for line table'}
         SF       EDIT_LN(A6)
         SUBA.L   A5,A5
         BRA      MAIN_ERR

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
ALN_LP   CMPA.L   A2,A1
         BHS.S    ALN_END
         CMP.B    (A1)+,D3
         BNE      ALN_LP
         MOVE.L   A1,D1
         SUB.L    A0,D1
         MOVE.B   D1,(A5,D2.W)
         ADDQ.W   #1,D2
         SUB.L    D4,D1
         BLE      ALN_NEWL
         MOVE.B   D4,-1(A5,D2.W)
         LEA      -1(A0,D4.W),A1
         NEG.L    D1
         BSR      MOV_TXT
         MOVE.L   TXTEND(A6),A2
         MOVEQ    #1,D0
         ADDQ.W   #1,A1
         BRA      ALN_NEWL
ALN_END  MOVE.L   A0,TXTEND(A6)
         MOVEM.L  (A7)+,D2-D4/A0-A3
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

*ENTER EDITED LINE INTO TEXT FILE

         XDEF     ENT_LINE,ENT_LIN1

ENT_LIN1 SF       D0
         BRA.S    EL_TEST
ENT_LINE ST       D0
EL_TEST  CMPA.W   #0,A5
         BEQ.S    NO_LNTBL
         TST.B    EDIT_LN(A6)
         BEQ.S    EL_RTS
         SF       EDIT_LN(A6)
         MOVEM.L  D1-D2/A1/A3,-(A7)
         MOVEQ    #0,D1
         MOVE.W   LINELEN(A6),D1
         TST.B    D0
         IF NE THEN
            BSR      STRIPSPC
         ENDIF
         MOVE.W   D1,D2
         ADDQ.W   #1,D1
         MOVEQ    #0,D0
         MOVE.B   (A5,D7.W),D0
         SUB.L    D0,D1
         BSR.S    GETSCRLN
         BSR.S    MOV_TXT
         BNE.S    EL_ERR
         ADD.B    D1,(A5,D7.W)
         BRA.S    EL_COPYE
EL_COPYL MOVE.B   (A3)+,(A1)+
EL_COPYE DBF      D2,EL_COPYL
         MOVE.B   #LF,(A1)
         MOVEM.L  (A7)+,D1-D2/A1/A3
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
STRIPSP1 MOVEQ    #' ',D0
         TST.W    D1
         BEQ.S    SS_END
SS_LOOP  CMP.B    -1(A3,D1.W),D0
         BNE.S    SS_END
         SUBQ.W   #1,D1
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
         MOVEM.L  D1/A1/A3,-(A7)
         BSR      GETSCRLN
         MOVE.L   A1,A3
         MOVEQ    #0,D1
         MOVE.B   (A5,D7.W),D1
         SUBQ.B   #1,D1
         BSR      STRIPSP1
         LEA      LINEBUF(A6),A3
         MOVE.W   D1,LINELEN(A6)
         BRA.S    CL_COPYE
CL_COPYL MOVE.B   (A1)+,(A3)+
CL_COPYE DBF      D1,CL_COPYL
         MOVEM.L  (A7)+,D1/A1/A3
CL_END   RTS

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
DSPP_LP  CMP.W    18(A7),D7
         BNE.S    DSPP_LIN
         TST.B    EDIT_LN(A6)
         BEQ.S    DSPP_LIN
         BSR.S    DSP_BUF
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

DSP_BUF  MOVEM.L  D1-D2/A1,-(A7)    DISPLAY LINE IN EDIT BUFFER
         LEA      LINEBUF(A6),A1
         MOVE.W   LINELEN(A6),D2
         BRA.S    DSPLIN_0
DSP_LINE MOVEM.L  D1-D2/A1,-(A7)    DISPLAY LINE AT (A1)
         MOVEQ    #0,D2
         MOVE.B   (A5,D7.W),D2
         SUBQ.B   #1,D2
DSPLIN_0 MOVEM.L  D2/A1,-(A7)
         MOVE.W   D4,D1
         MOVE.W   D5,D2
         QDOS     SD.POS
         MOVEM.L  (A7)+,D2/A1
         SUB.W    D6,D2
         BLE.S    DSPL_END
         MOVE.W   WINWID(A6),D1
         SUB.W    D4,D1
         CMP.W    D1,D2
         BLE.S    DSPLIN_1
         MOVE.W   D1,D2
DSPLIN_1 ADDA.W   D6,A1
         QDOS     IO.SSTRG
DSPL_END MOVEM.L  (A7)+,D1-D2/A1
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
         BEQ      OF_END            Exit with error code if no TK2
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
OF_DELET MOVEQ    #-1,D1
         MOVE.L   12(A7),A0
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
         IF EQ THEN
            MOVE.B   REPORT_P,D1
            QDOS     SD.SETPA
            MOVE.B   REPORT_P,D1
            QDOS     SD.SETST
            MOVE.B   REPORT_I,D1
            QDOS     SD.SETIN
            QDOS     SD.CLEAR
            PRINT    {'Line        Col      Line count:        Mode: '}
            TST.B    OVERWMOD(A6)
            IF EQ THEN
               PRINT    {'INSERT'}
            ELSE
               PRINT    {'OVERWRITE'}
            ENDIF
         ENDIF
         MOVEQ    #5,D1
         QDOS     SD.TAB
         MOVE.W   D7,D1
         MOVEQ    #5,D2
         BSR.S    DS_NUM1
         MOVEQ    #16,D1
         QDOS     SD.TAB
         MOVE.W   D6,D1
         MOVEQ    #3,D2
         BSR.S    DS_NUM1
         MOVEQ    #33,D1
         QDOS     SD.TAB
         MOVE.W   MAXLINE(A6),D1
         MOVEQ    #5,D2
         BSR.S    DS_NUM1
         MOVEM.L  (A7)+,A0-A2
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
 
