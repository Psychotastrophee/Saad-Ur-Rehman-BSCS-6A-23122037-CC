%{
/* ------------------------------------------------------------
   Lexer for the C language (Flex / win_flex)
   Recognizes: keywords, identifiers, integers, floats, strings,
   character literals, operators, symbols, preprocessor lines.
   Ignores: whitespace and comments (line and block comments).
   Reports: invalid characters, unterminated strings/comments,
   with line numbers.
   ------------------------------------------------------------ */
#include <stdio.h>
#include <stdlib.h>

int line_no = 1;

int c_keyword = 0, c_identifier = 0, c_integer = 0, c_float = 0;
int c_string = 0, c_char = 0, c_operator = 0, c_symbol = 0;
int c_preproc = 0, c_error = 0;
%}

%option noyywrap

DIGIT   [0-9]
LETTER  [a-zA-Z_]

%x COMMENT

%%

 /* ---------- block comments  / * ... * /  ---------- */
"/*"                { BEGIN(COMMENT); }
<COMMENT>"*/"       { BEGIN(INITIAL); }
<COMMENT>\n         { line_no++; }
<COMMENT>.          { /* ignore comment text */ }
<COMMENT><<EOF>>    { printf("ERROR (line %d): unterminated comment\n", line_no);
                      c_error++; return 0; }

 /* ---------- single line comment ---------- */
"//".*              { /* ignore */ }

 /* ---------- preprocessor lines like #include <stdio.h> ---------- */
^[ \t]*"#"[^\n]*    { printf("%-14s %s\n", "PREPROCESSOR", yytext); c_preproc++; }

 /* ---------- keywords (must come BEFORE the identifier rule) ---------- */
"auto"|"break"|"case"|"char"|"const"|"continue"|"default"|"do"|"double"|"else"|"enum"|"extern"|"float"|"for"|"goto"|"if"|"int"|"long"|"register"|"return"|"short"|"signed"|"sizeof"|"static"|"struct"|"switch"|"typedef"|"union"|"unsigned"|"void"|"volatile"|"while" {
                      printf("%-14s %s\n", "KEYWORD", yytext); c_keyword++; }

 /* ---------- identifiers ---------- */
{LETTER}({LETTER}|{DIGIT})*   { printf("%-14s %s\n", "IDENTIFIER", yytext); c_identifier++; }

 /* ---------- numbers ---------- */
{DIGIT}+"."{DIGIT}+  { printf("%-14s %s\n", "FLOAT", yytext); c_float++; }
{DIGIT}+             { printf("%-14s %s\n", "INTEGER", yytext); c_integer++; }

 /* ---------- strings and characters ---------- */
\"([^\"\\\n]|\\.)*\" { printf("%-14s %s\n", "STRING", yytext); c_string++; }
\"([^\"\\\n]|\\.)*   { printf("ERROR (line %d): unterminated string %s\n", line_no, yytext); c_error++; }
'([^'\\\n]|\\.)'     { printf("%-14s %s\n", "CHARACTER", yytext); c_char++; }

 /* ---------- operators (two-character ones first) ---------- */
"=="|"!="|"<="|">="|"&&"|"||"|"++"|"--"|"+="|"-="|"*="|"/="|"%="|"->"|"<<"|">>" {
                      printf("%-14s %s\n", "OPERATOR", yytext); c_operator++; }
[+\-*/%=<>!&|^~]     { printf("%-14s %s\n", "OPERATOR", yytext); c_operator++; }

 /* ---------- symbols ---------- */
[;,(){}\[\]:.?]      { printf("%-14s %s\n", "SYMBOL", yytext); c_symbol++; }

 /* ---------- whitespace ---------- */
\n                   { line_no++; }
[ \t\r]+             { /* ignore */ }

 /* ---------- anything else is an error ---------- */
.                    { printf("ERROR (line %d): invalid character '%s'\n", line_no, yytext); c_error++; }

%%

int main(int argc, char *argv[])
{
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            printf("Cannot open file: %s\n", argv[1]);
            return 1;
        }
    }

    printf("%-14s %s\n", "TOKEN TYPE", "LEXEME");
    printf("-------------------------------\n");

    yylex();

    printf("\n----------- SUMMARY -----------\n");
    printf("Keywords      : %d\n", c_keyword);
    printf("Identifiers   : %d\n", c_identifier);
    printf("Integers      : %d\n", c_integer);
    printf("Floats        : %d\n", c_float);
    printf("Strings       : %d\n", c_string);
    printf("Characters    : %d\n", c_char);
    printf("Operators     : %d\n", c_operator);
    printf("Symbols       : %d\n", c_symbol);
    printf("Preprocessor  : %d\n", c_preproc);
    printf("Errors        : %d\n", c_error);
    printf("Total lines   : %d\n", line_no);

    return 0;
}
