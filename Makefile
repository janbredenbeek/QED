#
# Makefile for QED
#
SRC = QED_ASM QED2_ASM QEDCMD_ASM QED_IN
SRCD = win3_QEDv2_
DESTD = dos1_QED_v2_
RELEASE = 203

OBJS = QED_REL QED2_REL QEDCMD_REL

QED: $(OBJS)
     $PQLINK -WITH $CQED -PROG $CQED

$(OBJS): QED_IN $PQDOS_IN_MAC

.SUFFIXES: _ASM _REL

_ASM_REL:
      $PQMAC $C$* -ERRORS

# CP command seems to chop off the first letter of the filename when the
# destination is a directory. So until this gets fixed we have to specify
# all files explicitly :-(

ckin:
        $PCP -v $(DESTD)QED_ASM $(SRCD)QED_ASM
        $PCP -v $(DESTD)QED2_ASM $(SRCD)QED2_ASM
        $PCP -v $(DESTD)QEDCMD_ASM $(SRCD)QEDCMD_ASM
        $PCP -v $(DESTD)QED_IN $(SRCD)QED_IN
        $PCP -v $(DESTD)QED_HELP $(SRCD)QED_HELP
        $PCP -v $(DESTD)CHANGES_TXT $(SRCD)CHANGES_TXT

ckout:
        $PCP -v $(SRCD)QED_ASM $(DESTD)QED_ASM
        $PCP -v $(SRCD)QED2_ASM $(DESTD)QED2_ASM
        $PCP -v $(SRCD)QEDCMD_ASM $(DESTD)QEDCMD_ASM
        $PCP -v $(SRCD)QED_IN $(DESTD)QED_IN
        $PCP -v $(SRCD)CHANGES_TXT $(DESTD)CHANGES_TXT
        $Pzip $(DESTD)QED_zip QED CHANGES_TXT

zip:
        $Pzip $(DESTD)QED$(RELEASE)_zip QED QED_HELP QED_DOC QEDCONFIG_BAS CHANGES_TXT

