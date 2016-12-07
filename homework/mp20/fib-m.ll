@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00"

define i32 @fib(i32 %n) {
entry:
  %n.addr = alloca i32
  store i32 %n, i32* %n.addr
  %0 = load i32, i32* %n.addr
  %cmp = icmp eq i32 %0, 0
  br i1 %cmp, label %if_true, label %if_false

if_true:
  br label %if_end

if_false:
  %cmp1 = icmp eq i32 %0, 1
  br i1 %cmp1, label %if_true2, label %if_false2

if_true2:
  br label %if_end

if_false2:
  %sub = sub i32 %0, 2
  %call = call i32 @fib(i32 %sub)
  %sub1 = sub i32 %0, 1
  %call1 = call i32 @fib(i32 %sub1)
  %add = add i32 %call, %call1
  br label %if_end2

if_end:
  %temp = phi i32 [ 0, %if_true ], [ 1, %if_true2 ]
  br label %if_end2

if_end2:
  %result = phi i32 [ %add, %if_false2 ], [ %temp, %if_end ]
  ret i32 %result
}

define i32 @main(i32 %argc, i8** %argv) {
entry:
  %argc.addr = alloca i32
  %argv.addr = alloca i8**
  store i32 %argc, i32* %argc.addr
  store i8** %argv, i8*** %argv.addr
  %0 = load i8**, i8*** %argv.addr
  %arrayidx = getelementptr inbounds i8*, i8** %0, i32 1
  %1 = load i8*, i8** %arrayidx
  %call = call i32 @atoi(i8* %1)
  %call1 = call i32 @fib(i32 %call)
  %call2 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %call1)
  ret i32 0
}

declare i32 @printf(i8*, ...)

declare i32 @atoi(i8*)

