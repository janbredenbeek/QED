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
* Commands
*

         INCLUDE  WIN1_MACRO_LIB
         INCLUDE  WIN1_QDOS_IN_MAC
         INCLUDE  WIN2_QEDv2_QED_IN

         XREF     CMDLN_P,CMDLN_I,MAIN_ERR,READNUM,SPLIT_LN
         XREF     LEFT,ALEFT,SLEFT,CALEFT,RIGHT,ARIGHT,SRIGHT,CRIGHT,SCRIGHT
         XREF     JOIN_LN,DOWN,UP,UNDO,CH_MODE,MK_LNTBL,INSRT_LN,DEL_LNTB
         XREF     ENT_LINE,GETSCRLN,MOV_TXT,STRIPSPC,COPYLINE,DSP_PAGE
         XREF     OPEN_DEF,ERRMSG,FIND_DSP,FIND_DS1,FINDLINE,EL_ERR
         XREF     DS_NUM,DS_NUM1,ADDCHR,DEL_D1,CH_AINDT,CH_WRDWR
         XREF     CH_TABEX,CH_TABCP,OPENFILE,FORK,ED_LOAD,SAV_ENV

         SECTION  CODE

* Prepare command window: set colours, display prompt '>' and count length         
* Entry: A1 ptr to command line (either in CMDBUF or temp buffer)
* Exit: D1 total length of command line (excl EOL)
*       D2 = D1 but never greater than window width - 1
*       A1 preserved
         
CMD_COLR MOVE.L   A1,-(A7)
         MOVE.L   CMDWIN(A6),A0
         MOVE.B   CMDLN_P,D1
         MOVEQ    #-1,D3
         QDOS     SD.SETPA
         MOVE.B   CMDLN_P,D1
         QDOS     SD.SETST
         MOVE.B   CMDLN_I,D1
         QDOS     SD.SETIN
         QDOS     SD.CLEAR
         MOVEQ    #'>',D1
         QDOS     IO.SBYTE
         MOVE.L   (A7)+,A1
         MOVEQ    #0,D1
CMDLENLP CMPI.B   #LF,(A1,D1.W)
         BEQ.S    CMDCOL_E
         ADDQ.W   #1,D1
         BRA      CMDLENLP
CMDCOL_E MOVE.W   D1,D2             D1 = total length of cmd line (excl EOL)
         CMP.W    WINWID(A6),D2
         IF HS THEN
            MOVE.W   WINWID(A6),D2
            SUBQ.W   #1,D2          D2 = length as it fits into the window
         ENDIF
         RTS         
         
         XDEF     ENT_CMD,ED_COMLN

* Enter new command line
* A feature frequently asked for: Allow command lines programmed under ALTKEYs
* to be stuffed into the command buffer.
* This didn't work because we have to read it from the text window and not the
* command window!

ENT_CMD  MOVEQ    #0,D2
         MOVEQ    #0,D3             don't wait if there's nothing to get
         SUBA.W   #CMDLEN,A7        make room for temp buffer
ED_GETLN QDOS     IO.FBYTE          get any characters, one by one
         TST.L    D0
         BNE.S    ED_EOL            until there's nothing left
         CMPI.B   #LF,D1
         BEQ.S    ED_EOL
         CMPI.W   #CMDLEN-1,D2      watch out for buffer overflows...
         BGE      ED_GETLN          and ignore any excess chars
         MOVE.B   D1,(A7,D2.W)
         ADDQ.W   #1,D2
         BRA      ED_GETLN          loop until EOL
ED_EOL   MOVE.B   #LF,(A7,D2.W)     ensure proper termination
         QDOS     SD.CURS           disable cursor on text window
         BRA.S    ED_CMCOL          go editing the cmd line
         
* Edit existing command line         
         
ED_COMLN SUBA.W   #CMDLEN,A7        make room for temp buffer
         MOVE.L   A7,A1
         LEA      CMDBUF(A6),A0
ED_COMLL MOVE.B   (A0)+,(A1)        copy cmd line into temp buffer
         CMPI.B   #LF,(A1)+
         BNE      ED_COMLL
ED_CMCOL MOVE.L   A7,A1             point A1 at temp buffer
         BSR      CMD_COLR          set colours of cmd window and display prompt
         TST.W    D2                D2 = length of any existing cmd line
         IF NE THEN
            MOVE.W   D1,-(A7)       save true length of cmd line
            QDOS     IO.SSTRG       write out cmd line (D2 = len in window)
            MOVE.W   D2,D1
            ADDQ.W   #1,D2          
            CMP.W    WINWID(A6),D2
            IF HS THEN
               SUBQ.W   #1,D1
            ENDIF
            SWAP     D1             this will be 'current position' for IO.EDLIN
            MOVE.W   (A7)+,D1       restore lenth of cmd line in buffer
         ENDIF
         MOVE.W   #CMDLEN,D2        buffer size
         LEA      (A7,D1.W),A1      ptr to end of cmd line
         QDOS     IO.EDLIN          now let user enter command line
         TST.L    D0
         BNE.S    CMD_ABRT          error? just abort (user pressed ESC?)
         CMPI.B   #LF,-(A1)         properly terminated with ENTER?
         BEQ.S    CMD_CPLN          yes, copy line to cmdbuf
CMD_ABRT ADDA.W   #CMDLEN,A7        command entry aborted; clean up buffer
         SF       MSGPRNTD(A6)
         SF       STPRINTD(A6)
         RTS

* Repeat existing command (F2)         
         
         XDEF     REP_CMD

REP_CMD  LEA      CMDBUF(A6),A1     use existing command
         BSR      CMD_COLR          display prompt
DSPCMDLN QDOS     IO.SSTRG          ... and cmd line
         BRA.S    EXEC_CMD

* Command line entered or edited properly, now copy it to cmdbuf         
         
CMD_CPLN MOVE.L   A7,A1
         LEA      CMDBUF(A6),A2
CMD_CPCH MOVE.B   (A1)+,(A2)+
         SUBQ.W   #1,D1
         BGT      CMD_CPCH
         ADDA.W   #CMDLEN,A7        cleanup temp buffer
         
* The command interpreter enters here. 
* The command should be in CMDBUF(A6), properly terminated by EOL
         
EXEC_CMD SF       MSGPRNTD(A6)
         SF       STPRINTD(A6)
         CLR.L    -(A7)             put end-marker on the stack
         LEA      CMDBUF(A6),A2
CMD_GTCT BSR      SKIPSPC           loop for each command
         CMPI.B   #LF,(A2)
         BEQ      CMD_END
         MOVEQ    #1,D1             assume count of 1
         CMPI.B   #'0',(A2)
         BLO.S    CMD_BRAC
         CMPI.B   #'9',(A2)
         BHI.S    CMD_BRAC
         BSR      GETNUM            get count
CMD_NXTB BSR      SKIPSPC
CMD_BRAC MOVE.W   D1,-(A7)          put repeat count on stack
         CMPI.B   #'(',(A2)         compound command?
         BNE.S    CMD_FRST
         ADDQ.W   #1,A2
         MOVE.L   A2,-(A7)          put current position on stack
         BRA      CMD_GTCT          ... and loop back
CMD_FRST MOVE.B   (A2)+,D1
         BSR      UP_ALPHA          get first letter
         BNE      CMD_ERR
         LSL.W    #8,D1
         MOVE.B   (A2),D1
         BSR      UP_ALPHA          get second letter (if any)
         BNE.S    CMD_1LET
         ADDQ.W   #1,A2
         CMPI.W   #'RP',D1          
         BNE.S    CMD_LOOK
         ADDQ.W   #2,A7             RP means repeat forever; drop count
         MOVEQ    #0,D1             and loop with count of 0
         BRA      CMD_NXTB
CMD_1LET MOVE.B   #' ',D1           1-letter command; use space as second char
CMD_LOOK BSR      SKIPSPC
         LEA      CMDTBL-2,A1
CMD_LOOP ADDQ.W   #2,A1             now lookup command in table
         MOVE.W   (A1)+,D0
         BEQ.S    CMD_UNKN
         CMP.W    D1,D0
         BNE      CMD_LOOP
         ADDA.W   (A1),A1           found command; calculate address
         MOVEM.L  A1-A2,-(A7)       save regs
         
* The following loop executes a single command N times (N=0 means forever)         
         
CMD_CALL MOVE.L   TXTWIN(A6),A0
         MOVE.W   D4,D1
         MOVE.W   D5,D2
         MOVEQ    #-1,D3
         QDOS     SD.POS            set cursor position
         MOVEM.L  (A7),A1-A2        retrieve regs
         JSR      (A1)              execute command routine
         BSR      TST_ESC           check for ESC pressed
         TST.W    8(A7)             test repeat count
         BEQ      CMD_CALL          if zero, loop forever
         SUBQ.W   #1,8(A7)          else, subtract 1
         BNE      CMD_CALL          and loop until exhausted
         ADDA.W   #10,A7            cleanup stack
         
* End of single command; check syntax         
         
CMD_NEXT BSR.S    SKIPSPC
         MOVE.B   (A2)+,D1
         CMPI.B   #LF,D1
         BEQ.S    CMD_END           EOL
         CMPI.B   #';',D1
         BEQ      CMD_GTCT          semicolon means there are more commands
         CMPI.B   #')',D1           end of compound command?
         BNE.S    CMD_ERR           anything else means syntax error
         TST.L    (A7)              any commands left?
         BEQ.S    CMD_BMIS          if not, mismatched brackets
         TST.W    4(A7)             repeat count
         BEQ.S    REP_BRAC
         SUBQ.W   #1,4(A7)
         BNE.S    REP_BRAC
         ADDQ.W   #6,A7
         BRA      CMD_NEXT
REP_BRAC MOVE.L   (A7),A2           go back to first command in compound
         BRA      CMD_GTCT
CMD_END  TST.L    (A7)+             EOL; check if no pending commands left
         BNE.S    CMD_BMIS
         RTS
CMD_ERR  LEA      SYNTXMSG,A1
         BRA.S    CMD_MSG
CMD_UNKN LEA      UNKNMSG,A1
         BRA.S    CMD_MSG
CMD_BMIS LEA      BMISMSG,A1
         BRA.S    CMD_MSG
         
* ESC pressed; clear text window buffer         
         
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

* Some support routines         
         
         XDEF     SKIPSPC

SKIPSPC  CMPI.B   #LF,(A2)
         BEQ.S    SKPSP_EN
         CMPI.B   #' ',(A2)
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
         CMPI.B   #' ',D2
         BLS.S    USE_SP
         CMPI.B   #'0',D2
         BLO.S    GS_FIRST
         CMPI.B   #'9',D2
         BLS.S    USE_SP
         CMPI.B   #'A',D2
         BLO.S    GS_FIRST
         CMPI.B   #'Z',D2
         BLS.S    USE_SP
         CMPI.B   #'a',D2
         BLO.S    GS_FIRST
         CMPI.B   #'z',D2
         BLS.S    USE_SP
GS_FIRST ADDQ.L   #1,A2
         MOVEQ    #$20,D1
         OR.B     D2,D1
         CMPI.B   #'{',D1
         BNE.S    GS_FRST2
         ADDQ.B   #2,D2
         BRA.S    GS_FRST2
USE_SP   MOVEQ    #0,D2
GS_FRST2 MOVE.L   A2,A1
         MOVEQ    #0,D0
GS_LOOP  MOVE.B   (A2),D1
         CMPI.B   #LF,D1
         BEQ.S    GS_ENDS
         TST.B    D2
         BNE.S    GS_DELIM
         CMPI.B   #' ',D1
         BLS.S    GS_ENDS
         CMPI.B   #')',D1
         BEQ.S    GS_ENDS
         CMPI.B   #';',D1
         BEQ.S    GS_ENDS
GS_DELIM ADDQ.L   #1,A2
         CMP.B    D2,D1
         BNE      GS_LOOP
         MOVEQ    #-1,D0
GS_ENDS  MOVE.L   A2,D1
         SUB.L    A1,D1
         ADD.W    D0,D1
         MOVEQ    #0,D0
         RTS
NO_ARG   MOVEQ    #-1,D0
         RTS
* BAD_DLIM ERRMSG   {'Bad string delimiter'}
*          BRA      MAIN_ERR

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
         DC.W     'QF'
         DC.W     CMD_QF-*
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
         DC.W     'SC'
         DC.W     CMD_SC-*
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
         DC.W     'TA'
         DC.W     CH_AINDT-*
         DC.W     'TC'
         DC.W     CH_TABCP-*
         DC.W     'TE'
         DC.W     CH_TABEX-*
         DC.W     'TI'
         DC.W     CH_MODE-*
         DC.W     'TW'
         DC.W     CH_WRDWR-*
         DC.W     'TY'
         DC.W     INS_STR-*
         DC.W     'U '
         DC.W     UNDO-*
         DC.W     'WB'
         DC.W     CMD_WB-*
         DC.W     'X '
         DC.W     CMD_X-*
         DC.W     'XF'
         DC.W     CMD_XF-*
         DC.W     0

CMD_RT   LEA      RTLIN1(A6),A1
         MOVE.W   (A1),D1
         MOVE.L   2(A1),(A1)+
         CLR.W    (A1)
         BRA      FIND_DSP

STORE_LN MOVE.L   RTLIN1(A6),RTLIN2(A6)
         MOVE.W   D7,RTLIN1(A6)
         RTS

         XDEF     CMD_NWLN,CMD_T,CMD_B

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

CMD_SL   MOVE.W   #LEFTMAR,D2
         BRA.S    CMD_GTNM
CMD_SR   MOVE.W   #RIGHTMAR,D2
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

ASK_QUIT ERRMSG   {'Lose changes in '}
         MOVE.L   CMDWIN(A6),A0
         LEA      FILENAME(A6),A1
         MOVE.W   (A1)+,D2
         MOVEQ    #-1,D3
         QDOS     IO.SSTRG
         LOAD$    {' (Y/N) ? '},A1
         MOVE.W   (A1)+,D2
         QDOS     IO.SSTRG
         SF       MSGPRNTD(A6)
         QDOS     SD.CURE
         QDOS     IO.FBYTE
         MOVEQ    #$DF,D2
         AND.B    D1,D2
         QDOS     SD.CURS
         CMPI.B   #'Y',D2
         RTS

CMD_Q    MOVE.B   #1,-(A7)
         BRA.S    Q_TSTFIL
CMD_QF   CLR.B    -(A7)
Q_TSTFIL MOVE.L   A5,D0
         IF NE THEN
            BSR      ENT_LINE
         ENDIF
         TST.B    EDIT_TXT(A6)
         BEQ.S    Q_KILL
         TST.B    (A7)
         IF MI THEN
            BSR      DSP_PAGE
         ENDIF
         BSR.S    ASK_QUIT
         BNE.S    Q_ABORT
Q_KILL   TST.L    NEXTFILE(A6)
         BEQ.S    KILL_QED
         BSR      UNFORK
         TAS      (A7)
         BNE      Q_TSTFIL
         BSR      DSP_PAGE
Q_ABORT  BRA      MAIN_ERR

CMD_X    MOVE.B   #1,-(A7)
         BRA.S    X_ENTER
CMD_XF   CLR.B    -(A7)
X_ENTER  MOVE.L   A5,D0
         IF NE THEN
            BSR      ENT_LINE
         ENDIF
         TST.B    EDIT_TXT(A6)
         BEQ.S    X_NEXT
         TST.B    (A7)
         IF MI THEN
            BSR      DSP_PAGE
         ENDIF
         BSR.S    SA_CURR
         BNE      MAIN_ERR
X_NEXT   TST.L    NEXTFILE(A6)
         BEQ.S    KILL_QED
         BSR      UNFORK
         TAS      (A7)
         BNE      X_ENTER
         BSR      DSP_PAGE
         BRA      MAIN_ERR
KILL_QED MOVE.L   GUARDWIN(A6),A0
         MOVEQ    #-1,D3
         MOVEQ    #0,D1
         MOVEQ    #0,D2
         QDOS     SD.BORDR
         QDOS     SD.CLEAR
         MOVEQ    #-1,D1
         MOVEQ    #0,D3
         QDOS     MT.FRJOB

CMD_SA   MOVE.L   A5,D0
         IF NE THEN
            BSR      ENT_LINE
         ENDIF
         BSR      GETSTR
         BNE.S    SA_CURR
         BSR      COPY_STK
         BRA.S    SA_SAVE
SA_CURR  CLR.W    -(A7)
         LEA      FILENAME(A6),A0
SA_SAVE  MOVE.L   TXTBASE(A6),A1
         MOVE.L   TXTEND(A6),D1
         SUB.L    A1,D1
         ST       D0
         BSR      SA_BLOCK
         ADDA.W   (A7)+,A7
         SF       EDIT_TXT(A6)
         RTS

CMD_SC   BSR      GETSTR
         BNE.S    SC_CURR
         BSR.S    COPY_STK
         BRA.S    SC_SAVE
SC_CURR  CLR.W    -(A7)
         LEA      FILENAME(A6),A0
SC_SAVE  BSR      ENT_LINE
         ST       D0
         BSR      SA_OPEN
         MOVE.L   A5,-(A7)
         MOVEQ    #0,D0
         MOVEQ    #0,D2
         MOVEQ    #-1,D3
         MOVE.L   TXTBASE(A6),A1
SC_LOOP  CMPA.L   TXTEND(A6),A1
         BHS.S    SC_CLOSE
         MOVE.B   (A5)+,D2
         PEA      (A1,D2.W)
         CMPI.B   #LF,-1(A1,D2.W)
         IF EQ THEN
            SUBQ.B   #1,D2
         ENDIF
         QDOS     IO.SSTRG
         MOVE.L   (A7)+,A1
         TST.L    D0
         BNE.S    SC_CLOSE
         CMPI.B   #LF,-1(A1)
         BNE      SC_LOOP
         MOVE.L   A1,-(A7)
         MOVE.W   #$0D0A,-(A7)
         MOVE.L   A7,A1
         MOVEQ    #2,D2
         QDOS     IO.SSTRG
         ADDQ.L   #2,A7
         MOVE.L   (A7)+,A1
         TST.L    D0
         BEQ      SC_LOOP
SC_CLOSE MOVE.L   (A7)+,A5
         MOVE.L   D0,-(A7)
         QDOS     IO.CLOSE
         MOVE.L   (A7)+,D0
         ADDA.W   (A7)+,A7
         BNE      FL_ERROR
         RTS

COPY_STK MOVE.L   (A7)+,A0
         MOVEQ    #50,D0
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
         BSR      GETBLOCK
         SF       D0
         BSR      SA_BLOCK
         ADDA.W   (A7)+,A7
         RTS

* Open output file
* Entry: D0.B =0 for ask permission, !0 for auto-rename (.._OLD)
*        A0.L filename (NOTE: Must be room for at least 44 chars!)
* Exit : A0.L channel ID  (if error, routine never returns).

SA_OPEN  MOVEM.L  D0/A0-A2,-(A7)
         MOVEQ    #IO.EXCL,D3
         BSR      OPEN_DEF
         CMPI.L   #ERR.NF,D0
         BEQ      SAO_OVER
         TST.L    D0
         BNE      FL_ERROR
         TST.B    3(A7)
         BNE.S    SAO_REN
SAO_ASK  MOVE.L   A0,-(A7)
         MOVE.L   4(A7),A1
         BSR      ERRMSG
         MOVE.L   CMDWIN(A6),A0
         MOVEQ    #-1,D3
         LOAD$    {' exists; ',$5B,'O]verwrite, ',$5B,'A]ppend or ',$5B,'ESC]ape? '},A1
         MOVE.W   (A1)+,D2
         QDOS     IO.SSTRG
         QDOS     SD.CURE
         QDOS     IO.FBYTE
         ANDI.W   #$FF,D1
         LEA      UCASETBL,A1
         MOVE.B   (A1,D1.W),D2
         QDOS     SD.CURS
         SF       MSGPRNTD(A6)
         MOVE.L   (A7)+,A0
         CMPI.B   #'O',D2
         BEQ.S    SAO_OVR1
         CMPI.B   #'A',D2
         BNE.S    SAO_ESC
         CLR.L    -(A7)
         MOVE.L   A7,A1
         MOVEQ    #4,D2
         QDOS     FS.HEADR
         MOVE.L   (A7)+,D1
         TST.L    D0
         BNE.S    SAO_ERR
         QDOS     FS.POSAB
         BRA.S    SAO_MSG
SAO_ESC  CMPI.B   #ESC,D2
         BNE      SAO_ASK
         MOVEQ    #ERR.EX,D0
SAO_ERR  MOVE.L   D0,-(A7)
         QDOS     IO.CLOSE
         MOVE.L   (A7)+,D0
         BRA.S    FL_ERROR
SAO_REN  MOVE.L   4(A7),A1
         MOVE.W   (A1),D0
         CMPI.W   #40,D0
         BGT.S    SAO_OVR1
         ADDQ.W   #4,(A1)
         LEA      2(A1,D0.W),A2
         MOVE.B   #'_',(A2)+
         MOVE.B   #'O',(A2)+
         MOVE.B   #'L',(A2)+
         MOVE.B   #'D',(A2)+
         MOVE.L   A0,-(A7)
         MOVE.L   A1,A0
         MOVEQ    #-1,D1
         QDOS     IO.DELET
         MOVE.L   (A7)+,A0
         MOVE.L   4(A7),A1
         MOVEQ    #-1,D3
         QDOS     FS.RENAM
         MOVE.L   4(A7),A1
         SUBQ.W   #4,(A1)
SAO_OVR1 QDOS     IO.CLOSE
SAO_OVER MOVE.L   4(A7),A0
         MOVEQ    #IO.OVER,D3
         BSR      OPENFILE
         BNE.S    FL_ERROR
SAO_MSG  ERRMSG   {'Writing '}
         MOVE.L   4(A7),A1
         MOVE.L   A0,4(A7)
         MOVE.L   CMDWIN(A6),A0
         MOVEQ    #-1,D3
         MOVE.W   (A1)+,D2
         QDOS     IO.SSTRG
         SF       MSGPRNTD(A6)
         MOVEM.L  (A7)+,D0/A0-A2
         RTS

FL_ERROR ERRMSG   {'FILE ERROR: '}
         MOVE.L   CMDWIN(A6),A0
         MOVE.W   UT_ERR,A2
         JSR      (A2)
         BRA      MAIN_ERR

* SAVE D1 BYTES AT (A1) TO FILE (A0)
* Entry: D0.B same as in SA_OPEN

SA_BLOCK MOVEM.L  D1/A0-A1,-(A7)
         BSR      SA_OPEN
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
         QDOS     FS.FLUSH
SA_CLOSE MOVE.L   D0,-(A7)
         QDOS     IO.CLOSE
         MOVEM.L  (A7)+,D0-D1/A0-A1
         TST.L    D0
         BNE.S    FL_ERROR
         RTS

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
NO_ROOM  ERRMSG   {'No room for file'}
ERR2     BRA      MAIN_ERR

CMD_IF   BSR      GETSTR
         BNE      EXPT_STR
         BSR      ENT_LINE
         BSR      COPY_STK
         MOVEQ    #IO.SHARE,D3
         BSR      OPEN_DEF
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
         BLT      MAIN_ERR
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
         BNE      MAIN_ERR
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
         BNE.S    DB_DEL
         MOVE.W   BLKEND(A6),D0
         CMP.W    MAXLINE(A6),D0
         BLT.S    DB_DEL
         MOVE.L   TXTBASE(A6),A4
         MOVE.B   #LF,(A4)+
         MOVE.L   A4,TXTMAX(A6)
         CLR.W    MAXLINE(A6)
         MOVE.B   #1,(A5)
         BRA.S    DB_DISP
DB_DEL   MOVE.L   A1,A4
         NEG.L    D1
         BSR      MOV_TXT
         MOVE.W   BLKEND(A6),D1
         SUB.W    D2,D1
         ADDQ.W   #1,D1
         BSR      DEL_LNTB
DB_DISP  MOVE.W   D2,D1
         BRA      FIND_DSP

CMD_R    BSR      GETSTR
         MOVEM.L  D1/A1,-(A7)
         BSR      FORK
         BNE      NO_ROOM
         MOVE.L   TXTWIN(A6),A0
         MOVEQ    #-1,D3
         QDOS     SD.CLEAR
         MOVEM.L  (A7)+,D1/A1
         LEA      CMDBUF(A6),A0
         BRA.S    R_COPY_E
R_COPY_L MOVE.B   (A1)+,(A0)+
R_COPY_E DBF      D1,R_COPY_L
         MOVE.B   #LF,(A0)+
         BSR      ED_LOAD
         BEQ.S    R_END
         BSR.S    UNFORK
R_END    BSR      DSP_PAGE
         BRA      MAIN_ERR

* Unlink file environment

         XDEF     UNFORK

UNFORK   MOVEM.L  D3/A0-A3,-(A7)
         MOVE.L   ENVSAV(A6),A0
         LEA      NEXTFILE(A6),A1
UF_LOOP  MOVE.L   (A1),A1
         CMPA.L   (A1),A0
         BNE      UF_LOOP
         MOVE.L   NEXTFILE(A6),(A1)
         CLR.L    ENVSAV(A6)
         QDOS     MT.RECHP
         TST.L    TXTBASE(A6)
         IF NE THEN
            MOVE.L   TXTBASE(A6),A0
            QDOS     MT.RECHP
         ENDIF
         MOVE.L   A5,D0
         IF NE THEN
            MOVE.L   A5,A0
            QDOS     MT.RECHP
         ENDIF
         BSR.S    NEXT_ENV
         MOVE.L   ENVSAV(A6),A1
         CMPA.L   NEXTFILE(A6),A1
         BNE.S    UF_END
         CLR.L    NEXTFILE(A6)
UF_END   MOVEM.L  (A7)+,D3/A0-A3
         RTS

         XDEF     NEXT_ENV

NEXT_ENV MOVEM.L  A0-A1,-(A7)
         TST.L    NEXTFILE(A6)
         BEQ.S    NE_END
         TST.L    ENVSAV(A6)
         IF NE THEN
            BSR      SAV_ENV
         ENDIF
         LEA      NEXTFILE(A6),A1
         MOVE.L   (A1),A0
         MOVE.L   A0,ENVSAV(A6)
         MOVE.L   #ENV_END-NEXTFILE,D0
NE_LOOP  MOVE.L   (A0)+,(A1)+
         SUBQ.L   #4,D0
         BGT      NE_LOOP
         MOVEM.L  (A0),D4-D7/A4-A5
NE_END   MOVEM.L  (A7)+,A0-A1
         RTS

DS_ONOFF LEA      ON$,A1
         BNE.S    DSO_2
         LEA      OFF$,A1
DSO_2    JMP      (A2)

ON$      STRING$  'ON'
OFF$     STRING$  'OFF'

CMD_SH   QDOS     SD.CLEAR
         MOVE.L   A2,-(A7)
         PRINT    {'   Editing file: '}
         LEA      FILENAME(A6),A1
         JSR      (A2)
         PRINT    {LF,'  "Find" string: "'}
         LEA      FINDSTR(A6),A1
         JSR      (A2)
         PRINT    {'"',LF,'  Tab expansion: '}
         TST.B    TABEXPND(A6)
         BSR      DS_ONOFF
         PRINT    {LF,'Tab compression: '}
         TST.B    TABCOMPR(A6)
         BSR      DS_ONOFF
         PRINT    {LF,'   Tab distance: '}
         MOVE.W   TABINC(A6),D1
         MOVEQ    #5,D2
         BSR      DS_NUM
         PRINT    {LF,'    Left margin: '}
         MOVE.W   LEFTMAR(A6),D1
         MOVEQ    #5,D2
         BSR      DS_NUM1
         PRINT    {LF,'   Right margin: '}
         MOVE.W   RIGHTMAR(A6),D1
         MOVEQ    #5,D2
         BSR      DS_NUM1
         PRINT    {LF,'    Block start: '}
         MOVE.W   BLKSTART(A6),D1
         BSR      PRBLOKN
         PRINT    {LF,'      Block end: '}
         MOVE.W   BLKEND(A6),D1
         BSR      PRBLOKN
         PRINT    {LF,'    Buffer size: '}
         MOVE.L   TXTMAX(A6),D1
         SUB.L    TXTBASE(A6),D1
         LSL.L    #6,D1
         SWAP     D1
         MOVEQ    #5,D2
         BSR      DS_NUM
         PRINT    {'K',LF,'   Buffer usage: '}
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

         XDEF     RET_KEY

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

         XDEF     CUP,CDOWN

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

         XDEF     UCASETBL

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

         END
