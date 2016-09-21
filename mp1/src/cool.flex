/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
  if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
    YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

unsigned int comment = 0;       //记录注释的个数
unsigned int string_buf_valid;  //记录字符串缓冲数组剩余的空间，用来判断字符串常量是否过长
bool string_error;              //若string_error为ture，表明存在字符串错误
int string_write(char *, unsigned int);  //填充字符串缓冲数组string_buf
bool null_error;             //若null_error为true，则表明字符串常量里出现null无效字符

%}

%option noyywrap

/*
 * Define names for regular expressions here.
 */

letter      [A-Za-z]
up_letter   [A-Z]
low_letter  [a-z]
digit       [0-9]
line_feed   [\n]
underscore  "_"
typeid      {up_letter}({letter}|{digit}|{underscore})* 
objectid    {low_letter}({letter}|{digit}|{underscore})*
delim       [ \f\r\t\v]
ws          {delim}+
int_const   {digit}+
le          "<="
assign      "<-"
darrow      "=>"
class       [Cc][Ll][Aa][Ss][Ss]
else        [Ee][Ll][Ss][Ee]
false       "f"[Aa][Ll][Ss][Ee]
fi          [Ff][Ii]
if          [Ii][Ff]
in          [Ii][Nn]
inherits    [Ii][Nn][Hh][Ee][Rr][Ii][Tt][Ss]
isvoid      [Ii][Ss][Vv][Oo][Ii][Dd]
let         [Ll][Ee][Tt]
loop        [Ll][Oo][Oo][Pp]
pool        [Pp][Oo][Oo][Ll]
then        [Tt][Hh][Ee][Nn]
while       [Ww][Hh][Ii][Ll][Ee]
case        [Cc][Aa][Ss][Ee]
esac        [Ee][Ss][Aa][Cc]
new         [Nn][Ee][Ww]
of          [Oo][Ff]
not         [Nn][Oo][Tt]
true        "t"[Rr][Uu][Ee]

  /* 注释状态 */
%x COMMENT     
  /*字符串状态*/
%x STRING      

%%

 /*
  * Define regular expressions for the tokens of COOL here. Make sure, you
  * handle correctly special cases, like:
  *   - Nested comments
  *   - String constants: They use C like systax and can contain escape
  *     sequences. Escape sequence \c is accepted for all characters c. Except
  *     for \n \t \b \f, the result is c.
  *   - Keywords: They are case-insensitive except for the values true and
  *     false, which must begin with a lower-case letter.
  *   - Multiple-character operators (like <-): The scanner should produce a
  *     single token for every such operator.
  *   - Line counting: You should keep the global variable curr_lineno updated
  *     with the correct line number
  */

 /*遇到换行符则记录行号*/
<INITIAL,COMMENT>{line_feed} {
   curr_lineno++;
}

 /*"(*"表明注释状态开始*/
<INITIAL>"(*" {
   comment++;  //注释个数加1
   BEGIN(COMMENT); //开始注释状态
}

 /*注释中遇到EOF*/
<COMMENT><<EOF>> {                       
  yylval.error_msg = "EOF in comment";
  BEGIN(INITIAL);   //回到起始状态
  return (ERROR);   //返回错误信息，不为此注释生成token
}

<COMMENT>[*]/[^)]     {}         //注释中没有连续的*)符，表明注释未结束
<COMMENT>[(]/[^*]     {}         //注释中没有连续的(*符，表明新注释未开始
<COMMENT>[^\n*(]      {}         //注释中遇到其他字符

 /* 注释中遇到新注释，即遇到(* */
<COMMENT>"(*" {
  comment++;   //注释个数加1
}

 /* 一个注释结束，即遇到*)  */
<COMMENT>"*)" {
  comment--;     //注释个数减1
  if (comment == 0)   //若comment为0，表明注释状态已结束
    BEGIN(INITIAL);   
}
 /* 在起始状态遇到*)，即在注释之外遇到*),返回错误信息 */
<INITIAL>"*)" {
  yylval.error_msg = "Unmatched *)";
  return (ERROR);
}

  /*以"--"为格式的注释*/
<INITIAL>("--")[^\n]*  {}    

 /* 遇到“，表明字符串常量开始*/
<INITIAL>[\"] {
  BEGIN(STRING);
  string_buf_ptr = string_buf;  //初始化string_buf_ptr的指针,指向string_buf的第一个字符
  string_buf_valid = MAX_STR_CONST;  //string_buf剩余空间为最大
  string_error = false;   //无字符串错误
  null_error = false;     //无空字符错误
}

 /* 若字符串中有EOF，直接返回错误信息 */
<STRING><<EOF>> {
  yylval.error_msg = "EOF in string constant";
  BEGIN(INITIAL);
  return (ERROR);
}

 /* 遇到正常字符，写入string_buf，直到字符串结束再返回*/
<STRING>[^\n\0\\\"]* {
  string_write(yytext, strlen(yytext)) ; 
}

 /* 遇到空字符，生成错误信息，直到字符串结束再返回 */
<STRING>[\0] {
  yylval.error_msg = "String contains null character";
  null_error = true;
  string_error = true;
}

 /* 非法换行，生成错误信息并返回，从下一行恢复词法分析*/
<STRING>{line_feed} {
  BEGIN(INITIAL);
  curr_lineno++;
  yylval.error_msg = "Unterminated string constant";
  return (ERROR);
}

 /* 处理转义符\的情况 */
<STRING>[\\](.|{line_feed}) {
  
  char ch;
  /*  合法换行  */
  if(yytext[1]=='\n')
      curr_lineno++;
  /* 处理特殊的字符 */
  switch (yytext[1]) {
    case 'n':
      ch = '\n';
      string_write(&ch,1);
      break;
    case 'b':
      ch = '\b';
      string_write(&ch,1);
      break;
    case 't':
      ch = '\t';
      string_write(&ch,1);
      break;
    case 'f':
      ch = '\f';
      string_write(&ch,1);
      break;
    case '\0':              //遇到\0,生成错误信息，直到字符串结束再返回
      yylval.error_msg = "String contains null character";
      null_error = true;
      string_error = true;
      break;
    default:                //遇到正常字符则\无效
      string_write(&yytext[1], 1);
  }
}
 /* 处理以\结尾的情况 */
<STRING>[\\]            {}

 /* 在字符串状态下，遇到”，进入初始状态，若没有错误信息，则返回string token，否则返回错误信息 */
<STRING>[\"] {
  BEGIN(INITIAL);
  if (!string_error) {
    yylval.symbol = stringtable.add_string(string_buf, string_buf_ptr-string_buf);  //填好stringtable
    return (STR_CONST);
  }
  else{
    return (ERROR);
}
}

{ws}                  {}

<INITIAL>"+"          {return ('+');}
<INITIAL>"-"          {return ('-');}
<INITIAL>"*"          {return ('*');}
<INITIAL>"/"          {return ('/');}
<INITIAL>"="          {return ('=');}
<INITIAL>"<"          {return ('<');}
<INITIAL>"."          {return ('.');}
<INITIAL>"~"          {return ('~');}
<INITIAL>","          {return (',');}
<INITIAL>";"          {return (';');}
<INITIAL>":"          {return (':');}
<INITIAL>"("          {return ('(');}
<INITIAL>")"          {return (')');}
<INITIAL>"@"          {return ('@');}
<INITIAL>"{"          {return ('{');}
<INITIAL>"}"          {return ('}');}

<INITIAL>{class}      {return (CLASS);}
<INITIAL>{else}       {return (ELSE);}
<INITIAL>{if}         {return (IF);}
<INITIAL>{fi}         {return (FI);}
<INITIAL>{in}         {return (IN);}
<INITIAL>{inherits}   {return (INHERITS);}
<INITIAL>{isvoid}     {return (ISVOID);}
<INITIAL>{let}        {return (LET);}
<INITIAL>{loop}       {return (LOOP);}
<INITIAL>{pool}       {return (POOL);}
<INITIAL>{then}       {return (THEN);}
<INITIAL>{case}       {return (CASE);}
<INITIAL>{esac}       {return (ESAC);}
<INITIAL>{new}        {return (NEW);}
<INITIAL>{not}        {return (NOT);}
<INITIAL>{of}         {return (OF);}
<INITIAL>{while}      {return (WHILE);}
<INITIAL>{assign}     {return (ASSIGN);}
<INITIAL>{darrow}     {return (DARROW);}
<INITIAL>{le}         {return (LE);}
<INITIAL>{true}       {yylval.boolean = true; return (BOOL_CONST);}
<INITIAL>{false}      {yylval.boolean = false; return (BOOL_CONST);}

<INITIAL>{typeid}     {yylval.symbol = idtable.add_string(yytext);return (TYPEID);}
<INITIAL>{objectid}   {yylval.symbol = idtable.add_string(yytext);return (OBJECTID);}  //填好idtable
<INITIAL>{int_const}  {yylval.symbol = inttable.add_string(yytext);return (INT_CONST);} //填好inttable

<INITIAL>.            {yylval.error_msg = yytext ; return (ERROR);}  //遇到无效字符，返回错误信息

%%

 /* 填充字符串缓冲数组，形成一个string token */
int string_write(char *str, unsigned int len) {
  if (len < string_buf_valid) {
    strncpy(string_buf_ptr, str, len);
    string_buf_ptr += len;
    string_buf_valid -= len;
    return 0;
  } else {  //若剩余空间不够，则生成错误信息
    if(!null_error){    //若已经有了null错误信息，不再生成字符串过长的错误信息
      string_error = true;
      yylval.error_msg = "String constant too long";
      }
    return -1;
  }
}


