100 REMark QED configuration program V4.01
110 REMark 20160221: allow for windows larger than 512x256 on QPC2
120 REMark 20180924: Updated for QED v2.0x
125 REMark 20210406: Allow for copying config data from old version
126 REMark 20210406: don't use SCR_XLIM/YLIM as vars (fail on uqlx)
128 REMark 20210406: check first 14 bytes; don't copy them from old to new
129 :
130 v$=VER$:IF v$="HBA" THEN xlim=SCR_XLIM:ylim=SCR_YLIM:ELSE xlim=512:ylim=256
140 WINDOW 480,200,16,16:MODE 4:PAPER 2:INK 7:CSIZE 0,0:CLS
150 CLS:PRINT "*** QED CONFIGURATION ***"\\
160 PRINT "Allows you to change the QED initial settings"\\
170 items=22:items2=11:bytes=97
180 RESTORE :DIM prog(bytes),opname$(items,32),optpos(items),optmin(items),optmax(items)
190 FOR i=0 TO items:READ opname$(i),optpos(i),optmin(i),optmax(i)
195 REPeat get_old
200   INPUT "File name of QED program (e.g. flp1_QED or flp1_QED_OLD): ";oldfile$
210   OPEN_IN#3,oldfile$:FOR i=0 TO bytes:prog(i)=CODE(INKEY$(#3,-1))
220   CLOSE#3
225   RESTORE 26000
226   match=1:FOR i=4 TO 13:READ chk:IF prog(i)<>chk THEN match=0
227   IF match THEN EXIT get_old
228   PRINT "This is not a valid QED program file"
229 END REPeat get_old
230 REMark FOR i=23,25:prog(i)=prog(i)+1
240 FOR i=43 TO 48:IF prog(i)>127 THEN prog(i)=prog(i)-256
250 help$="":FOR i=1 TO prog(51):help$=help$&CHR$(prog(i+51))
260 CLS:PRINT 'Use 씩 keys to select option'
270 PRINT 'Use 섹 keys to change selected option'
280 PRINT 'Press ENTER to end'
290 FOR i=0 TO items-1:AT (i MOD items2)+4,40*(i>=items2):PRINT opname$(i);":";TO 30+40*(i>=items2);optval$(optpos(i))
300 AT 16,0:PRINT opname$(items);": ";TO 30;help$
310 opt=0
320 REPeat sel_loop
330   STRIP 7:INK 0:print_opt:STRIP 2:INK 7
340   key=CODE(INKEY$(-1)):IF key=10 THEN print_opt:EXIT sel_loop
350   SELect ON key
360     =192:change_opt -1
370     =200:change_opt 1
380     =208:print_opt:opt=opt-1:IF opt<0:opt=items
390     =216:print_opt:opt=opt+1:IF opt>items:opt=0
400   END SELect
410 END REPeat sel_loop
420 bordwid=prog(33)
430 winwid=256*prog(14)+prog(15)+4*bordwid:winlen=256*prog(16)+prog(17)+2*bordwid
440 win_x=256*prog(18)+prog(19)-2*bordwid:win_y=256*prog(20)+prog(21)-bordwid
450 IF win_x<0:win_x=0
460 IF win_y<0:win_y=0
470 IF win_x+winwid>xlim:winwid=xlim-win_x
480 IF win_y+winlen>ylim:winlen=ylim-win_y
490 IF prog(42)=0:xinc=6:ELSE xinc=8
500 winwid=winwid-4*bordwid:winwid=winwid-(winwid MOD xinc)
510 winlen=winlen-2*bordwid:winlen=winlen-(winlen MOD 10)
520 INK prog(37):draw_win
530 PRINT "Use 섹 keys to reposition window"
540 PRINT "Use ALT 섹 keys to resize window"
550 PRINT "Press ENTER when finished"
560 REPeat win_loop
570   key=CODE(INKEY$(-1)):IF key=10:EXIT win_loop
580   SELect ON key
590     =192:REMark left
600       IF win_x>1:win_x=win_x-2
610     =193:REMark ALT left
620       IF winwid/xinc>55:winwid=winwid-xinc
630     =200:REMark right
640       IF win_x+winwid+4*bordwid<xlim-1:win_x=win_x+2
650     =201:REMark ALT right
660       IF win_x+winwid+4*bordwid+xinc<=xlim:winwid=winwid+xinc
670     =208:REMark up
680       IF win_y>0:win_y=win_y-1
690     =209:REMark ALT up
700       IF winlen>50:winlen=winlen-10
710     =216:REMark down
720       IF win_y+winlen+2*bordwid<ylim:win_y=win_y+1
730     =217:REMark ALT down
740       IF win_y+winlen+2*bordwid<=ylim-10:winlen=winlen+10
750   END SELect
760   draw_win:AT 1,10:PRINT winwid/xinc;TO 20;winlen/10
770   AT 3,10:PRINT win_x;TO 20;win_y
780 END REPeat win_loop
790 win_x=win_x+2*bordwid:win_y=win_y+bordwid
800 prog(14)=winwid DIV 256:prog(15)=winwid MOD 256:prog(16)=winlen DIV 256:prog(17)=winlen MOD 256
810 prog(18)=win_x DIV 256:prog(19)=win_x MOD 256:prog(20)=win_y DIV 256:prog(21)=win_y MOD 256
820 REMark FOR i=23,25:prog(i)=prog(i)-1
830 PRINT#0;"Save new settings? (Y/N) ";
840 REPeat getreply:reply$=INKEY$(-1):IF reply$ INSTR "YN":EXIT getreply
850 PRINT#0;reply$
860 IF reply$=="Y" THEN
865   PRINT#0;"Enter name of new QED program to save settings to or just ENTER to save to ";oldfile$;": ";
867   INPUT#0;newfile$:IF newfile$="" THEN newfile$=oldfile$
870   OPEN#3,newfile$
875   FOR i=0 TO 13:a$=INKEY$(#3,-1)
880   FOR i=14 TO bytes:PRINT#3;CHR$(prog(i));
890   CLOSE#3
900 END IF
910 PRINT#0;"Finished"
920 STOP
10000 DEFine PROCedure print_opt
10010   IF opt=22:AT 16,30:PRINT help$;:ELSE AT (opt MOD items2)+4,30+40*(opt>=items2):PRINT optval$(optpos(opt));
10020 END DEFine print_opt
10030 DEFine PROCedure change_opt(n)
10040   IF opt=22
10050     AT 16,30:PRINT FILL$(" ",LEN(help$));
10060     AT 16,30:INPUT help$
10070     prog(51)=LEN(help$)
10080     FOR i=1 TO LEN(help$):prog(i+51)=CODE(help$(i))
10090   ELSE
10100     AT (opt MOD items2)+4,30+40*(opt>=items2):PRINT "   ";
10110     newval=prog(optpos(opt))+n
10120     IF newval<optmin(opt):newval=optmin(opt)
10130     IF newval>optmax(opt):newval=optmax(opt)
10140     prog(optpos(opt))=newval
10150   END IF
10160 END DEFine change_opt
10170 DEFine PROCedure draw_win
10180   PAPER 0:BORDER 0,0:CLS
10190   WINDOW winwid+4*bordwid,winlen+2*bordwid,win_x,win_y
10200   PAPER prog(36):BORDER bordwid,prog(32):CLS
10210 END DEFine draw_win
10220 DEFine FuNction optval$(pos)
10230   SELect ON pos
10240     =23,25:RETurn prog(pos)+1
10250     =43 TO 48:IF prog(pos) THEN RETurn "ON":ELSE RETurn "OFF"
10260     =REMAINDER :RETurn prog(pos)
10270   END SELect
10280 END DEFine optval$
25000 DATA 'Left margin',23,0,254
25010 DATA 'Right margin',25,0,254
25020 DATA 'Tab distance',27,1,255
25030 DATA 'Initial workspace size (K)',29,1,255
25035 DATA 'Workspace overhead (K)',31,1,255
25040 DATA 'Border colour',32,0,255
25050 DATA 'Border width',33,0,16
25060 DATA 'Paper colour initial window',34,0,255
25070 DATA 'Ink colour initial window',35,0,7
25080 DATA 'Paper colour text window',36,0,255
25090 DATA 'Ink colour text window',37,0,7
25100 DATA 'Paper colour error report',38,0,255
25110 DATA 'Ink colour error report',39,0,7
25120 DATA 'Paper colour command line',40,0,255
25130 DATA 'Ink colour command line',41,0,7
25140 DATA 'Horizontal CSIZE',42,0,3
25141 DATA 'Default overwrite mode',43,-1,0
25142 DATA 'Default word wrap mode',44,-1,0
25143 DATA 'Default auto-indent mode',45,-1,0
25144 DATA 'Default TAB expansion mode',46,-1,0
25145 DATA 'Default TAB compression mode',47,-1,0
25146 DATA 'Swap SHIFT 씩 / ALT 씩',48,-1,0
25150 DATA 'HELP file name',50,0,0
26000 DATA 0,0,74,251,0,3,81,69,68,0
