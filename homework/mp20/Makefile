CLANG=clang
LLVM=llc
GCC=gcc
EXEFILES=fib fib-m

all : $(EXEFILES) clean

fib :
	$(CLANG) fib.c -o fib
fib-m.s :
	$(LLVM) fib-m.ll -o fib-m.s
fib-m : fib-m.s
	$(GCC) fib-m.s -o fib-m
.PHONY : clean

clean :
	rm -f fib-m.s
