grammar SandBoxScript;

program				: block* ;

block				: importStmnt
					| assignStmnt
					| expression										
					;

importStmnt			: IMPORT Target=expression																#importStatement
					;

assignStmnt			: NAME								ASSIGN expression									#assignNameStatement
					| memberAccess						ASSIGN expression									#assignMemberStatement
					| memberAccessComp					ASSIGN expression									#assignComputedMemberStatement
					;

expression          : '(' expression ')'																	#parenthesisExp
					| expression DOT NAME																	#memberAccessExp
					| expression '[' expression ']'															#computedMemberAccessExp
                    | Function=expression '(' Arguments=expressionGroup ')'									#functionCallExp
					
					| <assoc=right>		Left=expression Operation=EXPONENT			Right=expression		#binaryOperationExp
                    |					Left=expression Operation=(ASTERISK|SLASH)	Right=expression		#binaryOperationExp
                    |					Left=expression Operation=(PLUS|MINUS)		Right=expression		#binaryOperationExp

					| NAME																					#nameExp
                    | NUMBER																				#numberLiteral
					| string																				#stringLiteral
                    ;

memberAccess		: expression DOT NAME ;
memberAccessComp	: expression '[' expression ']' ;

string				: '"' Content=stringContent '"';
stringContent		: ( ESCAPED_QUOTE | ~('\n'|'\r') )*? ;

expressionGroup		: (expression (',' expression)*)? ;

fragment LETTER			: [a-zA-Z] ;
fragment DIGIT			: [0-9] ;
fragment ESCAPED_QUOTE	: '\\"';
fragment DOT		    : '.' ;
IMPORT					: 'import' ;

STRING :   '"' ( ESCAPED_QUOTE | ~('\n'|'\r') )*? '"';

ASSIGN	            : '=' ;

ASTERISK            : '*' ;
SLASH               : '/' ;
PLUS                : '+' ;
MINUS               : '-' ;
EXPONENT            : '**';

INCREMENT			: '++';
DECREMENT			: '--';

NAME				: LETTER (LETTER | DIGIT)* ;

NUMBER              : DIGIT+ ('.' DIGIT+)? ;

WHITESPACE : [ \n\t\r]+ -> channel(HIDDEN);


