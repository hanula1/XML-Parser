%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "defs.h"
#include "x.tab.h"

int linia = 0;

int process_token(const char *text, const char *TokenType,
		  const char *TokenVal, const int TokenID); 
char *strnncpy(char *dst, const char *src, const int n);

%}

%option yylineno
%x ST_COMMENT ST_PI ST_TAG

/* identyfikator */

id [a-zA-Z:_][a-zA-Z:_0-9-]*

%%

 /* Komentarze (na warunkach poczatkowych) */
<INITIAL>"<!--" {
  BEGIN(ST_COMMENT); 
  linia = yylineno; 
};
<INITIAL>"-->"  { printf("Koniec komentarza bez początku w linii %d\n", yylineno);}
<ST_COMMENT>"-->" {BEGIN(INITIAL);};
<ST_COMMENT>.|\n ;

 /* Instrukcje przetwarzania (na warunkach poczatkowych) */
<INITIAL>"<?"{id} {
  BEGIN(ST_PI); 
  linia = yylineno; 
  return process_token(yytext, "PI_TAG_BEG", yytext+2, PI_TAG_BEG);
};
<INITIAL>"?>" {printf("Koniec instrukcji przetwarzania bez początku w linii %d\n", yylineno);}
<ST_PI>"?>" {
  BEGIN(INITIAL);
  return process_token(yytext, "PI_TAG_END", "", PI_TAG_END);
  };
<ST_PI>.|\n ; 

 /* Znacznik (na warunkach poczatkowych) */
<INITIAL>"<"{id} {
  BEGIN(ST_TAG); 
  linia = yylineno; 
  return process_token(yytext, "STAG_BEG", yytext+1, STAG_BEG);};
<INITIAL>">" {printf("Koniec znacznika bez początku w linii %d\n", yylineno);}
<ST_TAG>">" {
  BEGIN(INITIAL);
  return process_token(yytext, "TAG_END", "", TAG_END);
  };

 /* Znacznik zamykający(na warunkach poczatkowych) */
<INITIAL>"</"{id} {
  BEGIN(ST_TAG); 
  linia = yylineno; 
    return process_token(yytext, "ETAG_BEG", yytext+2, ETAG_BEG);};

<INITIAL>"/>" {printf("Koniec znacznika zamykającego bez początku w linii %d\n", yylineno);}
<ST_TAG>"/>" {
  BEGIN(INITIAL);
  return process_token(yytext, "ETAG_END", "", ETAG_END);
  };

<ST_TAG>.|\n ; 

 /* Napisy */
"&lt"   return process_token(yytext, "CHAR", "<", CHAR);
"&gt"   return process_token(yytext, "CHAR", ">", CHAR);
"&amp"  return process_token(yytext, "CHAR", "&", CHAR);
"&apos" return process_token(yytext, "CHAR", "\'", CHAR);
"&quote" return process_token(yytext, "CHAR", "\"", CHAR);

 /* Białe znaki */
^[ \t]+ ;
"\n" return process_token(yytext, "NEWLINE", "\n", NEWLINE);
 [ \t] return process_token(yytext, "S", yytext, S);

 /* Inne symbole */
. return process_token(yytext, "CHAR", yytext, CHAR);
%%

int yywrap() {
  if(YY_START == ST_COMMENT)
  	printf("Brak zamknięcia komentarza w linii %d\n", linia);
  if(YY_START == ST_PI)
  	printf("Brak zamknięcia przetwarzania instrukcji w linii %d\n", linia);
  if(YY_START == ST_TAG)
  	printf("Brak zamknięcia znacznika w linii %d\n", linia);
  return 1; 
}

/* Nazwa:	strnncpy
 * Cel:		Kopiuje zadaną liczbę znaków napisu umieszczając na końcu
 *		znak o kodzie 0.
 * Parametry:	dst		- (o) napis, do którego ma nastąpić kopiowanie;
 *		src		- (i) napis, który ma być kopiowany;
 *		n		- (i) maksymalna liczba znaków do kopiowania.
 * Zwraca:	dst.
 * Uwagi:	strncpy nie umieszcza znaku o kodzie 0 za kopiowanym napisem.
 *		Napis docelowy musi mieć miejsce na dodatkowy n+1 znak.
 */
char *
strnncpy(char *dst, const char *src, const int n)
{
  if (n > 0) {
    strncpy(dst, src, n);
  }
  dst[n] = '\0';
  return dst;
}/*strnncpy*/

/* Nazwa:       process_token
 * Cel:         Wypisanie informacji o wykrytym elemencie i przekazanie
 *              tej informacji wyżej z ewentualną wartością elementu, jeśli
 *              takowa występuje.
 * Parametry:   text            - (i) tekst, do którego nastąpiło dopasowanie;
 *              TokenType       - (i) napis będący tekstową reprezentacją
 *                                      nazwy typu elementu;
 *              TokenVal        - (i) wartość elementu, o ile występuje;
 *              TokenID         - (i) identyfikator typu elementu zadeklarowany
 *                                      za pomocą dyrektywy %token
 *                                      w pliku modula.y lub kod pojedynczego
 *					znaku (w pliku analizatora składniowego
 *					występuje ujęty w apostrofy).
 * Zwraca:      Identyfikator typu elementu (TokenID).
 * Uwagi:       Informacja o wykrytym elemencie zwracana jest
 *              w trzech kolumnach. W pierwszej wypisywany jest tekst,
 *              do którego nastąpiło dopasowanie, w drugiej - typ elementu,
 *              w trzeciej - wartość elementu (o ile występuje).
 */
int process_token(const char *text, const char *TokenType,
		  const char *TokenVal, const int TokenID)
{
  int l;
  /* if (TokenID == NEWLINE)
    printf("%-20.20s%-15s %s\n", "\\n", TokenType, TokenVal);
  else
    printf("%-20.20s%-15s %s\n", text, TokenType, TokenVal); */
  if(TokenID==PI_TAG_BEG ||TokenID==STAG_BEG ||TokenID==ETAG_BEG || 
    TokenID==CHAR|| TokenID==NEWLINE || TokenID==S) {
    l = strlen(text);
    strnncpy(yylval.s, TokenVal, l - 1 <= MAXSTRLEN? l : MAXSTRLEN);
  }
  return(TokenID);
}

