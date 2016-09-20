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

unsigned int comment = 0;       //The number of comments
unsigned int string_buf_valid;  //The remaining size of string buff
bool string_error;              //if string_error is true, there exists an error
int string_write(char *, unsigned int);  //write the string buffer, the result is a string token
bool null_error;             //string contains null character

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

%x COMMENT
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

 /*record the curr_lineno*/
<INITIAL,COMMENT>{line_feed} {
   curr_lineno++;
}

 /*comments begin*/
<INITIAL>"(*" {
   comment++;
   BEGIN(COMMENT);
}

 /*EOF in comments*/
<COMMENT><<EOF>> {                       
  yylval.error_msg = "EOF in comment";
  BEGIN(INITIAL);
  return (ERROR);
}

<COMMENT>[*]/[^)]     {}         //only '*', no ')' followed
<COMMENT>[(]/[^*]     {}         //only '(', no '*' followed
<COMMENT>[^\n*(]      {}         //other characters in comments

 /* mutipul comments */
<COMMENT>"(*" {
  comment++;
}

 /* "*)" is the end of a comment  */
<COMMENT>"*)" {
  comment--;
  if (comment == 0) 
    BEGIN(INITIAL);
}
 /* unmatched comment terminator  */
<INITIAL>"*)" {
  yylval.error_msg = "Unmatched *)";
  return (ERROR);
}

  /*comments in type of "--"*/
<INITIAL>("--")[^\n]*  {}    

 /* encounter a quarter, represents the begin of a string constant */
<INITIAL>[\"] {
  BEGIN(STRING);
  string_buf_ptr = string_buf;  //initial the string_buf_ptr
  string_buf_valid = MAX_STR_CONST;  //initial the string_buf_valid
  string_error = false;   //there is no string error
  null_error = false;
}

 /* EOF in string constant  */
<STRING><<EOF>> {
  yylval.error_msg = "EOF in string constant";
  BEGIN(INITIAL);
  return (ERROR);
}

 /* Write the string buf, until it is full */
<STRING>[^\n\0\\\"]* {
  string_write(yytext, strlen(yytext)) ; 
}

 /* String contains null character */
<STRING>[\0] {
  yylval.error_msg = "String contains null character";
  null_error = true;
  string_error = true;
}

 /* illegal line feed */
<STRING>{line_feed} {
  BEGIN(INITIAL);
  curr_lineno++;
  yylval.error_msg = "Unterminated string constant";
  return (ERROR);
}

<STRING>[\\](.|{line_feed}) {
  
  char ch;
  /*  legal line feed in string constant */
  if(yytext[1]=='\n')
      curr_lineno++;
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
    case '\0':
      yylval.error_msg = "String contains null character";
      null_error = true;
      string_error = true;
      break;
    default:
      string_write(&yytext[1], 1);
  }
}
 /* handle the only '\' in the string */
<STRING>[\\]            {}

<STRING>[\"] {
  BEGIN(INITIAL);
  if (!string_error) {
    yylval.symbol = stringtable.add_string(string_buf, string_buf_ptr-string_buf);
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
<INITIAL>{objectid}   {yylval.symbol = idtable.add_string(yytext);return (OBJECTID);}
<INITIAL>{int_const}  {yylval.symbol = inttable.add_string(yytext);return (INT_CONST);}

<INITIAL>.            {yylval.error_msg = yytext ; return (ERROR);}

%%

int string_write(char *str, unsigned int len) {
  if (len < string_buf_valid) {
    strncpy(string_buf_ptr, str, len);
    string_buf_ptr += len;
    string_buf_valid -= len;
    return 0;
  } else {
    if(!null_error){
      string_error = true;
      yylval.error_msg = "String constant too long";
      }
    return -1;
  }
}


