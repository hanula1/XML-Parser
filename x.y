%{
#include	<stdio.h>
#include	<string.h>
#include "defs.h"


  int yylex(void);
  void yyerror(const char *txt);

  int level = 0;
  int pos = 0;
  int line = 0;
  const int INDENT_LENGTH = 2;
  const int LINE_WIDTH = 20;

   void indent(int level);
   void check_tag_matching(const char *start_tag, const char *end_tag);
   void print_wrapped_text(const char *text, int level, int *pos, int* line);

%}

%union {
  char s[MAXSTRLEN];
  int i;
  double d;
}


%token <s> PI_TAG_BEG PI_TAG_END STAG_BEG ETAG_BEG TAG_END ETAG_END CHAR S NEWLINE

%type <s> start_tag end_tag word

%%
xml: 
      entry element {printf("\n");}
      ;

entry: 
      instruction
      | entry instruction
      | NEWLINE entry
      | entry NEWLINE
      ;

instruction: 
      PI_TAG_BEG PI_TAG_END { printf("<?%s?>", $1); }
      ;

element: 
      empty_tag 
      | tags_pair
      | element NEWLINE
      | element S
      ;

empty_tag: 
      STAG_BEG ETAG_END { printf("\n"); indent(level); printf("<%s/>", $1); }
      ;

tags_pair: 
      start_tag content end_tag {check_tag_matching($1, $3);}
      ;

start_tag: 
      STAG_BEG TAG_END { printf("\n"); indent(level++); printf("<%s>", $1); line = 0;}
      ;

end_tag: 
      ETAG_BEG TAG_END {pos = 0; printf("\n"); indent(--level); printf("</%s>", $1);} 
      ; 

word: 
      CHAR {print_wrapped_text($1, level, &pos, &line);}
      | word CHAR { print_wrapped_text($2, level, &pos, &line);}
      | word S {print_wrapped_text($2, level, &pos, &line);}
      ;

content: 

    | word 
    | content word 
    | NEWLINE
    | content NEWLINE
    | element
    | content element
    ;


%%

int main( void )
{ 

	printf( "Hanna Banasiak\n" );
	yyparse();

	return( 0 ); // OK
}

void yyerror( const char *txt)
{
	printf("%s\n", txt );
}

void indent(int level) {
   for(int i=0; i<level*INDENT_LENGTH; i++) {
      printf(" ");
   }
}

void check_tag_matching(const char *start_tag, const char *end_tag) {
    if (strcmp(end_tag, start_tag) != 0) {
        printf("Błąd: Niedopasowany znacznik końcowy '%s'. Oczekiwano '%s'\n", end_tag, start_tag ? start_tag : "brak");
    }
   //  else {
   //      printf("Dopasowanie znaczników: <%s> i </%s>\n", end_tag, start_tag);
   //  }
}

void print_wrapped_text(const char *text, int level, int *pos, int* line) {
    int word_len = strlen(text);
    int indent_width = level * INDENT_LENGTH;

   if (*pos + indent_width + word_len > LINE_WIDTH) {
        printf("\n");
        indent(level);
        *pos = 0;
        line++;
    }

    if(*line==0 && *pos==0){
      printf("\n");
      indent(level);
    }

    printf("%s", text);

    *pos += word_len;
}




