100 REMark QED configuration program V4.00
105 REMark 20160221: allow for windows larger than 512x256 on QPC2
107 REMark 20180117: Updated for QED v2.00b2
110 WINDOW 448,200,32,16:MODE 4:PAPER 2:INK 7:CSIZE 1,0:CLS
120 CLS:PRINT "*** QED CONFIGURATION ***"\\
130 PRINT "Allows you to change the QED initial settings"\\
140 RESTORE :DIM prog(87),opname$(15,27),optpos(15),optmin(15),optmax(15)
150 FOR i=0 TO 15:READ opname$(i),optpos(i),optmin(i),optmax(i)
160 INPUT "Name of medium containing QED (e.g. flp1_): ";dev$
170 OPEN_IN#3,dev$&"QED":FOR i=0 TO 87:prog(i)=CODE(INKEY$(#3,-1))
180 CLOSE#3
190 FOR i=23,25:prog(i)=prog(i)+1
200 help$="":FOR i=1 TO prog(43):help$=help$&CHR$(prog(i+43))
210 CLS:PRINT 'Use 씩 keys to select option'
220 PRINT 'Use 섹 keys to change selected option'
230 PRINT 'Press ENTER to end'
240 AT 4,0:FOR i=0 TO 14:PRINT opname$(i);":";TO 29;prog(optpos(i))
250 PRINT opname$(15);": ";TO 29;help$
260 opt=0
270 REPeat sel_loop
280   STRIP 7:INK 0:print_opt:STRIP 2:INK 7
290   key=CODE(INKEY$(-1)):IF key=10 THEN print_opt:EXIT sel_loop
300   SELect ON key
310     =192:change_opt -1
320     =200:change_opt 1
330     =208:print_opt:opt=opt-1:IF opt<0:opt=15
340     =216:print_opt:opt=opt+1:IF opt>15:opt=0
350   END SELect
360 END REPeat sel_loop
370 bordwid=prog(31)
380 winwid=256*prog(14)+prog(15)+4*bordwid:winlen=256*prog(16)+prog(17)+2*bordwid
390 win_x=256*prog(18)+prog(19)-2*bordwid:win_y=256*prog(20)+prog(21)-bordwid
400 IF win_x<0:win_x=0
410 IF win_y<0:win_y=0
420 IF win_x+winwid>SCR_XLIM:winwid=SCR_XLIM-win_x
430 IF win_y+winlen>SCR_YLIM:winlen=SCR_YLIM-win_y
440 IF prog(40)=0:xinc=6:ELSE xinc=8
450 winwid=winwid-4*bordwid:winwid=winwid-(winwid MOD xinc)
460 winlen=winlen-2*bordwid:winlen=winlen-(winlen MOD 10)
470 INK prog(35):draw_win
480 PRINT "Use 섹 keys to reposition window"
490 PRINT "Use ALT 섹 keys to resize window"
500 PRINT "Press ENTER when finished"
510 REPeat win_loop
520   key=CODE(INKEY$(-1)):IF key=10:EXIT win_loop
530   SELect ON key
540     =192:REMark left
550       IF win_x>1:win_x=win_x-2
560     =193:REMark ALT left
570       IF winwid/xinc>55:winwid=winwid-xinc
580     =200:REMark right
590       IF win_x+winwid+4*bordwid<SCR_XLIM-1:win_x=win_x+2
600     =201:REMark ALT right
610       IF win_x+winwid+4*bordwid+xinc<=SCR_XLIM:winwid=winwid+xinc
620     =208:REMark up
630       IF win_y>0:win_y=win_y-1
640     =209:REMark ALT up
650       IF winlen>50:winlen=winlen-10
660     =216:REMark down
670       IF win_y+winlen+2*bordwid<SCR_YLIM:win_y=win_y+1
680     =217:REMark ALT down
690       IF win_y+winlen+2*bordwid<=SCR_YLIM-10:winlen=winlen+10
700   END SELect
710   draw_win:AT 1,10:PRINT winwid/xinc;TO 20;winlen/10
720   AT 3,10:PRINT win_x;TO 20;win_y
730 END REPeat win_loop
740 win_x=win_x+2*bordwid:win_y=win_y+bordwid
750 prog(14)=winwid DIV 256:prog(15)=winwid MOD 256:prog(16)=winlen DIV 256:prog(17)=winlen MOD 256
760 prog(18)=win_x DIV 256:prog(19)=win_x MOD 256:prog(20)=win_y DIV 256:prog(21)=win_y MOD 256
770 FOR i=23,25:prog(i)=prog(i)-1
780 PRINT#0;"Save new settings? (Y/N) ";
790 REPeat getreply:reply$=INKEY$(-1):IF reply$ INSTR "YN":EXIT getreply
800 PRINT#0;reply$
810 IF reply$=="Y" THEN
820   OPEN#3,dev$&"QED"
830   FOR i=0 TO 87:PRINT#3;CHR$(prog(i));
840   CLOSE#3
850 END IF
860 PRINT#0;"Finished"
870 STOP
10000 DEFine PROCedure print_opt
10010   IF opt=15:AT 19,29:PRINT help$;:ELSE AT opt+4,29:PRINT prog(optpos(opt));
10020 END DEFine print_opt
10030 DEFine PROCedure change_opt(n)
10040   IF opt=15
10050     AT 19,29:PRINT FILL$(" ",LEN(help$));
10060     AT 19,29:INPUT help$
10070     prog(43)=LEN(help$)
10080     FOR i=1 TO LEN(help$):prog(i+43)=CODE(help$(i))
10090   ELSE
10100     AT opt+4,29:PRINT "   ";
10110     newval=prog(optpos(opt))+n
10120     IF newval<optmin(opt):newval=optmin(opt)
10130     IF newval>optmax(opt):newval=optmax(opt)
10140     prog(optpos(opt))=newval
10150   END IF
10160 END DEFine change_opt
10170 DEFine PROCedure draw_win
10180   PAPER 0:BORDER 0,0:CLS
10190   WINDOW winwid+4*bordwid,winlen+2*bordwid,win_x,win_y
10200   PAPER prog(34):BORDER bordwid,prog(30):CLS
10210 END DEFine draw_win
25000 DATA 'Left margin',23,1,255
25010 DATA 'Right margin',25,1,255
25020 DATA 'Tab distance',27,1,255
25030 DATA 'Initial workspace size (K)',29,1,255
25040 DATA 'Border colour',30,0,255
25050 DATA 'Border width',31,0,16
25060 DATA 'Paper colour initial window',32,0,255
25070 DATA 'Ink colour initial window',33,0,7
25080 DATA 'Paper colour text window',34,0,255
25090 DATA 'Ink colour text window',35,0,7
25100 DATA 'Paper colour error report',36,0,255
25110 DATA 'Ink colour error report',37,0,7
25120 DATA 'Paper colour command line',38,0,255
25130 DATA 'Ink colour command line',39,0,7
25140 DATA 'Horizontal CSIZE',40,0,3
25150 DATA 'HELP file name',42,0,0
