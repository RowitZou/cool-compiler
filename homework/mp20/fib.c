#include <stdio.h>
#include <stdlib.h>

int fib(int n)
{
    return n == 0 ? 0 :
	   n == 1 ? 1 :
	   fib(n-2) + fib(n-1);
}

int main(int argc, char *argv[])
{
    printf("%d\n", fib(atoi(argv[1])));
    return 0;
}
