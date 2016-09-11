SUPPORTDIR= ../cool-support
LIB= 
FLEXSRC= cool.flex
FLEXGEN= cool-lex.cc
YSRC= cool.y
BISONCGEN= cool-parse.cc
BISONHGEN= cool-parse.h
COMMON_CSRC= stringtab.cc handle_flags.cc utilities.cc
FLEX_CSRC= lextest.cc   
BISON_CSRC= parser-phase.cc dumptype.cc tree.cc cool-tree.cc tokens-lex.cc 
FLEX_CFILES= ${FLEX_CSRC} ${FLEXGEN} ${COMMON_CSRC} 
BISON_CFILES= $(BISON_CSRC) ${BISONCGEN} ${COMMON_CSRC}
FLEX_OBJS= ${FLEX_CFILES:.cc=.o} 
BISON_OBJS= ${BISON_CFILES:.cc=.o} 
CFLAGS= -g -Wall -Wno-unused -Wno-deprecated -DDEBUG ${CPPINCLUDE}
FLEXFLAGS= -d 
BFLAGS= -d -v -y -b cool --debug -p cool_yy
CPPINCLUDE= -I. -I${SUPPORTDIR}/include 
FLEX= flex 
CC= g++
BISON= bison

all: lexer parser
lexer: ${FLEX_OBJS}
	${CC} ${CFLAGS} ${FLEX_OBJS} ${LIB} -o lexer

parser: ${BISON_OBJS}
	${CC} ${CFLAGS} ${BISON_OBJS} ${LIB} -o parser

.cc.o:
	${CC} ${CFLAGS} -c $<

${FLEXGEN:.cc.o}: ${FLEXGEN}
	${CC} ${CFLAGS} -c $<

${FLEXGEN}: ${FLEXSRC} 
	${FLEX} ${FLEXFLAGS} -o${FLEXGEN} ${FLEXSRC}

${BISONCGEN} ${BISONHGEN}: ${YSRC}
	${BISON} ${BFLAGS} ${YSRC}
	mv -f ${YSRC:.y=.tab.c} ${BISONCGEN}

${FLEX_CSRC} ${BISON_CSRC} ${COMMON_CSRC}:
	-ln -s ${SUPPORTDIR}/src/$@ $@

clean :
	-rm -f core ${FLEX_OBJS} ${BISON_OBJS} ${BISONCGEN} ${BISONHGEN} ${YSRC:.y=.tab.h} ${FLEXGEN} \
        lexer parser *~ *.output

realclean: clean
	-rm -f ${FLEX_CSRC} ${BISON_CSRC} ${COMMON_CSRC}
