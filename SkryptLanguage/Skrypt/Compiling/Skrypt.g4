grammar Skrypt;

program				: block EOF ;

block				: (
					importStmnt
					| importAllFromStmnt
					| importFromStmnt
					| importFromModuleStmnt
					| moduleStmnt
					| structStmnt
					| traitStmnt
					| traitImplStmnt
					| tryStmnt
					| ifStmnt
					| forStmnt
					| whileStmnt																								
					| fnStmnt 
					| returnStmnt
					| breakStmnt
					| continueStmnt
					| assignStmnt
					| expression
					)*
					;

stmntBlock			: '{' Block=block '}'
					| ifStmnt
					| returnStmnt
					| continueStmnt
					| breakStmnt
					| assignStmnt
					| expression
					;

importStmnt	: IMPORT name (DOT NAME)*?	{
	var nameCtx = ($ctx as ImportStatementContext).name();
	var scope = GetDefinitionBlock($ctx);

	if (nameCtx.variable == null) {
		CompileErrorHandler.TolerateError(
            nameCtx.NAME().Symbol,
            "Undefined variable: " + nameCtx.GetText()
        );
	} else {
		var root = nameCtx.variable.Value;
		var target = root;
		var members = ($ctx as ImportStatementContext).NAME();

		foreach (var m in members) {
			try {
				target = target.GetProperty(m.GetText()).value;
			} catch (System.Exception e) {
				CompileErrorHandler.TolerateError(
					nameCtx.NAME().Symbol,
					e.Message
				);
			}
		}

		foreach (var m in target.Members) {
			var v = m.Value;

			scope.LexicalEnvironment.AddVariable(new Skrypt.Variable(m.Key,v.value, scope.LexicalEnvironment));
		}
	}
}																																
#importStatement;

importAllFromStmnt	: IMPORT ASTERISK FROM string {
	var Ctx = ($ctx as ImportAllFromStatementContext);
	var scope = GetDefinitionBlock($ctx);

	var relativePath = Ctx.@string().value;
	var input = Engine.FileHandler.Read(relativePath);

	Engine.DoRelativeFile(relativePath, true, scope.LexicalEnvironment);
}		
#importAllFromStatement;

importFromStmnt	: IMPORT NAME (',' NAME)* FROM string {
	var Ctx = ($ctx as ImportFromStatementContext);
	var scope = GetDefinitionBlock($ctx);

	var relativePath = Ctx.@string().value;
	var input = Engine.FileHandler.Read(relativePath);

	Engine.DoRelativeFile(relativePath, true);

	foreach (var n in Ctx.NAME()) {
		var name = n.GetText();

		scope.LexicalEnvironment.AddVariable(new Skrypt.Variable(name, Engine.GetValue(name), scope.LexicalEnvironment));
	}
}
#importFromStatement;

importFromModuleStmnt : IMPORT NAME (',' NAME)* FROM Module=name {
	var Ctx = ($ctx as ImportFromModuleStatementContext);
	var scope = GetDefinitionBlock($ctx);

	var module = Ctx.Module.variable.Value;

	if (module == null)
		CompileErrorHandler.TolerateError(
			Ctx.Module.Start,
			"Module can't be null."
		);

	foreach (var n in Ctx.NAME()) {
		try {
			var name = n.GetText();	
			var value = module.GetProperty(name).value;

			scope.LexicalEnvironment.AddVariable(new Skrypt.Variable(name, value, scope.LexicalEnvironment));
		} catch (NonExistingMemberException e) {
			CompileErrorHandler.TolerateError(
				n.Symbol,
				e.Message
			);
		}
	}
}								
#importFromModuleStatement;

moduleStmnt	: MODULE name {
	var Ctx = ($ctx as ModuleStatementContext);

	var nameCtx = Ctx.name();
	
	var key = $"{this.Engine.FileHandler.File}@{nameCtx.GetText()}";
	var isParsed = this.Engine.InitializeOnParse.ContainsKey(key);
	Variable variable = null;
	SkryptModule module = null;

	if (!isParsed) {
		var isInValidContext = ContextIsIn($ctx, new [] {typeof(ModuleStatementContext), typeof(ProgramContext)});

		if (!isInValidContext)
			CompileErrorHandler.TolerateError(
				$ctx.Start,
				"Module has to be in global scope or module block."
			);

		var block = GetDefinitionBlock($ctx.Parent);

		if (nameCtx.variable != null && nameCtx.variable.IsConstant)
			CompileErrorHandler.TolerateError(
				nameCtx.Start,
				"Constant cannot be redefined."
			);

		module = new ScriptModule(nameCtx.GetText(), this.Engine);

		this.Engine.FastAdd(module);

		variable = new Skrypt.Variable(nameCtx.GetText(), module, block.LexicalEnvironment);

		block.LexicalEnvironment.AddVariable(variable);
	}

	} '{' moduleProperty* '}' {

	if (!isParsed) {
		foreach (var c in Ctx.moduleProperty()) {
			this.Engine.Visitor.Visit(c);

			CreateProperty(variable.Value, Ctx, c, false);
		}

		this.Engine.InitializeOnParse[key] = module;
	}
}		
#moduleStatement;

structStmnt	: STRUCT name {
	var isInValidContext = ContextIsIn($ctx, new [] {typeof(ModuleStatementContext), typeof(ProgramContext), typeof(StructStatementContext)});

	if (!isInValidContext)
		CompileErrorHandler.TolerateError(
			$ctx.Start,
			"Struct has to be in global scope, module block or struct block."
		);

	var Ctx = ($ctx as StructStatementContext);
	var nameCtx = Ctx.name();
	var block = GetDefinitionBlock($ctx.Parent);
	var typeName = nameCtx.GetText();

	if (nameCtx.variable != null && nameCtx.variable.IsConstant)
		CompileErrorHandler.TolerateError(
			nameCtx.Start,
			"Constant cannot be redefined."
		);

	var type = new Skrypt.Variable(typeName, new ScriptType(typeName, this.Engine), block.LexicalEnvironment);
	var template = new Template {Name = typeName};

	block.LexicalEnvironment.AddVariable(type);

	}  '{' structProperty* '}' {

	foreach (var c in Ctx.structProperty()) {
		var isPrivate = c.PRIVATE() != null;	
		var isStatic = c.STATIC() != null;

		this.Engine.Visitor.Visit(c.Property);

		if (isStatic) {
			CreateProperty(type.Value, Ctx, c.Property, isPrivate);
		} else {
			var nameToken = GetPropertyNameToken(c.Property);

			var value = Ctx.LexicalEnvironment.GetVariable(nameToken.Text).Value;

			if (value == null) {
				CompileErrorHandler.TolerateError(
					c.Property.Start,
					"Field can't be set to an undefined value."
				);
			}

			if (nameToken.Text == "init" && value is FunctionInstance function) {
				(type.Value as ScriptType).Constructor = function.Function as ScriptFunction;
				continue;
			}

			template.Members[nameToken.Text] = new Member(value, isPrivate, Ctx);
		}
	}

	var finalType = (type.Value as ScriptType);

	finalType.Template = template;
	finalType.File = Engine.FileHandler.File;
}	
#structStatement;

traitStmnt : TRAIT name {
	var isInValidContext = ContextIsIn($ctx, new [] {typeof(ModuleStatementContext), typeof(ProgramContext)});

	if (!isInValidContext) {
		CompileErrorHandler.TolerateError(
			$ctx.Start,
			"Trait has to be in global scope or module block."
		);
	}

	var Ctx = ($ctx as TraitStatementContext);
	var nameCtx = Ctx.name();
	var block = GetDefinitionBlock($ctx.Parent);
	var traitName = nameCtx.GetText();

	if (nameCtx.variable != null && nameCtx.variable.IsConstant)
		CompileErrorHandler.TolerateError(
			nameCtx.Start,
			"Constant cannot be redefined."
		);

	var trait = new ScriptTrait(traitName, this.Engine);
	var traitVariable = new Skrypt.Variable(traitName, trait, block.LexicalEnvironment);

	block.LexicalEnvironment.AddVariable(traitVariable);

	} propertiesBlock {

	foreach (var child in Ctx.propertiesBlock().property()) {
		this.Engine.Visitor.Visit(child);

		var nameToken = GetPropertyNameToken(child);
		var value = Ctx.LexicalEnvironment.GetVariable(nameToken.Text).Value;

		if (value == null) {
			CompileErrorHandler.TolerateError(
				nameToken,
				"Field can't be set to an undefined value."
			);
		}

		trait.TraitMembers[nameToken.Text] = new Member(value, false, Ctx);
	}
}				
#traitStatement;

traitImplStmnt : IMPL name FOR name propertiesBlock? {
	var isInValidContext = ContextIsIn($ctx, new [] {typeof(ProgramContext)});

	if (!isInValidContext)
		CompileErrorHandler.TolerateError(
			$ctx.Start,
			"Implementation has to be in global scope."
		);

	var Ctx = ($ctx as TraitImplStatementContext);
	var traitNameCtx = Ctx.name(0);
	var typeNameCtx = Ctx.name(1);

	var trait = traitNameCtx.variable.Value as SkryptTrait;
	var type = typeNameCtx.variable.Value as SkryptType;

	if (!typeof(SkryptTrait).IsAssignableFrom(traitNameCtx.variable.Value.GetType())) {
		CompileErrorHandler.TolerateError(
			traitNameCtx.NAME().Symbol,
			"Trait expected."
		);
	}

	if (!typeof(SkryptType).IsAssignableFrom(typeNameCtx.variable.Value.GetType())) {
		CompileErrorHandler.TolerateError(
			traitNameCtx.NAME().Symbol,
			"Type expected."
		);
	}

	type.Traits.Add(trait);

	foreach (var kv in trait.TraitMembers) {
		var newMember = new Member(kv.Value.value, kv.Value.isPrivate, kv.Value.definitionBlock);

		type.Template.Members[kv.Key] = newMember;
	}

	var modifiesProperties = Ctx.propertiesBlock() != null;

	if (modifiesProperties) {
		foreach (var child in Ctx.propertiesBlock().property()) {
			this.Engine.Visitor.Visit(child);

			var nameToken = GetPropertyNameToken(child);	
			var value = Ctx.LexicalEnvironment.GetVariable(nameToken.Text).Value;

			if (!trait.TraitMembers.ContainsKey(nameToken.Text)) {
				CompileErrorHandler.TolerateError(
					nameToken,
					$"Trait does not contain property {nameToken.Text}."
				);
				continue;
			}

			if (value == null) {
				CompileErrorHandler.TolerateError(
					nameToken,
					"Field can't be set to an undefined value."
				);
			}

			type.Template.Members[nameToken.Text].value = value;
		}
	}
}				
#traitImplStatement;

propertiesBlock		: '{' property+ '}' ;
traitProperty		: property ;
structProperty		: (PRIVATE | PUBLIC) STATIC? Property=property ;
moduleProperty		: moduleStmnt | structStmnt | memberDefStmnt | fnStmnt;
property			: memberDefStmnt | fnStmnt ;

fnStmnt	: CONST? FN name '(' parameterGroup ')' {
	var fnCtx = ($ctx as FunctionStatementContext);
	var nameCtx = fnCtx.name();
	var isConstant = fnCtx.CONST() != null;

	if (nameCtx.variable != null && nameCtx.variable.IsConstant)
		CompileErrorHandler.TolerateError(
			nameCtx.Start,
			"Constant cannot be redefined."
		);

	var scope = GetDefinitionBlock($ctx.Parent);
	var newVar = new Skrypt.Variable(nameCtx.GetText(), scope.LexicalEnvironment);

	scope.LexicalEnvironment.AddVariable(newVar);
	nameCtx.variable = newVar;		

	fnCtx.LexicalEnvironment.AddVariable(new Skrypt.Variable("self", scope.LexicalEnvironment){IsConstant = true});

	var parameters = fnCtx.parameterGroup().parameter();
	var processedParameters = new Skrypt.Parameter[parameters.Length];

	for (var i = 0; i < parameters.Length; i++) {
		var p = parameters[i];
		var name = p.NAME().GetText();

		processedParameters[i] = new Skrypt.Parameter(name, p.expression()); 

		var parameterVar = new Skrypt.Variable(name, null, scope.LexicalEnvironment);

		fnCtx.LexicalEnvironment.AddVariable(parameterVar);
	}
} stmntBlock {
	var function = new Skrypt.ScriptFunction(fnCtx) { 
		Parameters = processedParameters,
		File = Engine.FileHandler.File
	}; 

	var functionVar = new Skrypt.FunctionInstance(this.Engine, function); 

	newVar.Value = functionVar;
}				
#functionStatement;											

returnStmnt	: RETURN expression? {
	$ctx.Statement = GetFirstFunctionStatement($ctx);

	if ($ctx.Statement == null) {
		CompileErrorHandler.TolerateError(
			(_localctx as ReturnStatementContext).RETURN().Symbol,
			"Return statement must be inside a function."
		);
	}
}					
#returnStatement;

parameterGroup : (parameter (',' parameter)*)? ;								

parameter : NAME ('=' expression)?;
		
tryStmnt : TRY stmntBlock catchStmt 																					
#tryStatement;

catchStmt : CATCH '('name')' {
	var catchCtx = ($ctx as CatchStatementContext);
	var nameCtx = catchCtx.name();
	var newVar = new Skrypt.Variable(nameCtx.GetText(), catchCtx.LexicalEnvironment);

	catchCtx.LexicalEnvironment.AddVariable(newVar);

	nameCtx.variable = newVar;	
} stmntBlock 		
#catchStatement;

forStmnt : FOR '(' Instantiator=assignStmnt ',' Condition=expression ',' Modifier=expression ')' stmntBlock			
#forStatement;

whileStmnt: WHILE '(' Condition=expression ')' stmntBlock															
#whileStatement;

continueStmnt : CONTINUE {
	$ctx.Statement = GetFirstLoopStatement($ctx);

	if ($ctx.Statement == null) {
		CompileErrorHandler.TolerateError(
			(_localctx as ContinueStatementContext).CONTINUE().Symbol,
			"Continue statement must be inside a loop."
		);
	}
}				
#continueStatement;

breakStmnt : BREAK {
	$ctx.Statement = GetFirstLoopStatement($ctx);

	if ($ctx.Statement == null) {
		CompileErrorHandler.TolerateError(
			(_localctx as BreakStatementContext).BREAK().Symbol,
			"Break statement must be inside a loop."
		);
	}
}					
#breakStatement;

ifStmnt	: if (elseif)* else?	
#ifStatement;

if : IF '(' Condition=expression ')' stmntBlock;

elseif : ELSE IF '(' Condition=expression ')' stmntBlock;

else : ELSE stmntBlock;

memberDefStmnt : CONST? name ASSIGN expression {
	var memberDefCtx = ($ctx as MemberDefinitionStatementContext);
	var nameCtx = memberDefCtx.name();
	var block = GetDefinitionBlock($ctx);

	var isConstant = memberDefCtx.CONST() != null;

	if (nameCtx.variable != null)
		CompileErrorHandler.TolerateError(
			nameCtx.Start,
			 $"Member {nameCtx} is already defined."
		);

	if (nameCtx.variable == null) {
		var newVar = new Skrypt.Variable(nameCtx.GetText(), block.LexicalEnvironment) {
			IsConstant = isConstant
		};

		block.LexicalEnvironment.AddVariable(newVar);
		nameCtx.variable = newVar;
	} 	
} 
#memberDefinitionStatement;

assign : Operator=(PLUS|MINUS|ASTERISK|REMAINDER|BITAND|BITNOT|BITOR|BITXOR)? ASSIGN  
#assignOperator;

assignStmnt	: CONST? name assign expression {
	var assignNameCtx = ($ctx as AssignNameStatementContext);
	var nameCtx = assignNameCtx.name();
	var block = GetDefinitionBlock(nameCtx.GetText(), $ctx);
	var isConstant = assignNameCtx.CONST() != null;
	var hasOperator = (assignNameCtx.assign() as SkryptParser.AssignOperatorContext).Operator != null;

	if (hasOperator) {
		if (nameCtx.variable == null)
			CompileErrorHandler.TolerateError(
				nameCtx.Start,
				"Undefined variable: " + nameCtx.GetText()
			);
		if (isConstant)
			CompileErrorHandler.TolerateError(
				assignNameCtx.Start,
				"Const keyword cannot be used for operator assignment."
			);
	}

	if (nameCtx.variable != null && nameCtx.variable.IsConstant) 
			CompileErrorHandler.TolerateError(
				nameCtx.Start,
				"Constant cannot be redefined."
			);

	if (nameCtx.variable == null) {
		var newVar = new Skrypt.Variable(nameCtx.GetText(),block.LexicalEnvironment) {
			IsConstant = isConstant
		};

		block.LexicalEnvironment.AddVariable(newVar);
		nameCtx.variable = newVar;
	} 	

	var isInFunction = block.Context.Parent is StmntBlockContext SmntBlock && SmntBlock.Parent is FunctionStatementContext;
}																																
#assignNameStatement
| memberAccess		assign expression	#assignMemberStatement
| memberAccessComp	assign expression	#assignComputedMemberStatement;

expression          : '(' expression ')'																						#parenthesisExp
					| fnLiteral																									#functionLiteral		
					| expression DOT NAME	 																					#memberAccessExp
					| expression '[' expression ']'																				#computedMemberAccessExp
                    | Function=expression '(' Arguments=expressionGroup ')'	{
var functionCtx = ($ctx as FunctionCallExpContext);

functionCtx.CallFile = Engine.FileHandler.File;		
}																																#functionCallExp
					
					| Target=expression Operation=(INCREMENT|DECREMENT) 														#postfixOperationExp		
					| Operation=(MINUS|NOT|BITNOT|INCREMENT|DECREMENT|TYPEOF) Target=expression									#prefixOperationExp
			


					| <assoc=right>		Left=expression Operation=EXPONENT			Right=expression							#binaryOperationExp
                    |					Left=expression Operation=(ASTERISK|SLASH|REMAINDER)	Right=expression				#binaryOperationExp
                    |					Left=expression Operation=(PLUS|MINUS)		Right=expression							#binaryOperationExp

                    |					Left=expression Operation=(BITSHIFTL|BITSHIFTR|BITSHIFTUR)	Right=expression			#binaryOperationExp

                    |					Left=expression Operation=(LESS|LESSEQ|GREATER|GREATEREQ)	Right=expression			#binaryOperationExp
                    |					Left=expression Operation=(EQUAL|NOTEQUAL|IS)				Right=expression			#binaryOperationExp
                    |					Left=expression Operation=BITAND		Right=expression								#binaryOperationExp
                    |					Left=expression Operation=BITXOR		Right=expression								#binaryOperationExp
                    |					Left=expression Operation=BITOR		Right=expression									#binaryOperationExp

					|					Left=expression Operation=AND	Right=expression										#binaryOperationExp
                    |					Left=expression Operation=OR	Right=expression										#binaryOperationExp

					| <assoc=right> expression TERNARYTRUE expression TERNARYFALSE expression									#conditionalExp

                    | number																									#numberLiteral
					| string																									#stringLiteral
					| boolean																									#booleanLiteral
					| null																										#nullLiteral
					/*| vector2																									#vector2Literal
					| vector3																									#vector3Literal
					| vector4																									#vector4Literal*/
					| array																										#arrayLiteral
					| name {
	var nameCtx = ($ctx as NameExpContext).name();

	if (nameCtx.variable == null) {
		CompileErrorHandler.TolerateError(
			nameCtx.NAME().Symbol,
			"Undefined variable: " + nameCtx.GetText()
		);
	}																								
}																																#nameExp
                    ;

name returns [Skrypt.Variable variable] : NAME 	{
	var scope = GetDefinitionBlock($NAME.text, $ctx);

	$variable = GetReference($NAME.text, scope);
} ;

memberAccess		: expression DOT NAME ;
memberAccessComp	: expression '[' expression ']' ;

string returns [string value] : STRING { 
	if ($STRING.text.Length > 2) {
		var content = $STRING.text.Substring(1, $STRING.text.Length - 2);

		$value = System.Text.RegularExpressions.Regex.Unescape(content);
	} else {
		$value = "";
	}
} ;

number returns [double value] : NUMBER { 
	$value = double.Parse($NUMBER.text); 
} ;

boolean returns [bool value] : BOOLEAN { 
	$value = $BOOLEAN.text == "true" ? true : false; 
} ;

null returns [object value] : NULL { 
	$value = null; 
} ;

fnLiteral			:  ('(' parameterGroup ')' | parameter) '=>' {
	var fnCtx = ($ctx as FnLiteralContext);
	var scope = GetDefinitionBlock($ctx.Parent);

	fnCtx.LexicalEnvironment.AddVariable(new Skrypt.Variable("self", scope.LexicalEnvironment){IsConstant = true});

	var parameters = fnCtx.parameterGroup() == null ? new ParameterContext[] {fnCtx.parameter()} : fnCtx.parameterGroup().parameter();
	var processedParameters = new Skrypt.Parameter[parameters.Length];

	for (var i = 0; i < parameters.Length; i++) {
		var p = parameters[i];
		var name = p.NAME().GetText();

		processedParameters[i] = new Skrypt.Parameter(name, p.expression()); 

		var parameterVar = new Skrypt.Variable(name, scope.LexicalEnvironment);

		fnCtx.LexicalEnvironment.AddVariable(parameterVar);
	}

} stmntBlock {
	var function = new Skrypt.ScriptFunction(fnCtx) { 
		Parameters = processedParameters
	}; 

	$ctx.value = new Skrypt.FunctionInstance(this.Engine, function);	
}																																				
					;					


/*
vector2				:	'<' X=expression ',' Y=expression '>' ;
vector3				:	'<' X=expression ',' Y=expression ',' Z=expression '>' ;
vector4				:	'<' X=expression ',' Y=expression ',' Z=expression ',' W=expression'>' ;
*/

array				: '[' expressionGroup ']' ; 

expressionGroup		: (expression (',' expression)*)? ;

fragment LETTER			: [a-zA-Z] ;
fragment DIGIT			: [0-9] ;
fragment ESCAPED_QUOTE	: '\\"';
fragment TRUE			: 'true';
fragment FALSE			: 'false';

DOT						: '.' ;

IMPORT					: 'import' ;
FROM					: 'from' ;
MODULE					: 'module' ;
STRUCT					: 'struct' ;
TRAIT					: 'trait' ;
IMPL					: 'impl' ;
IF						: 'if' ;
ELSE					: 'else' ;
FN						: 'fn' ;
WHILE					: 'while' ;
FOR						: 'for' ;
RETURN					: 'return' ;
BREAK					: 'break' ;
CONTINUE				: 'continue' ;
STATIC					: 'static' ;
PRIVATE					: 'private' ;
PUBLIC					: 'public' ;
CONST					: 'const' ;
TYPEOF					: 'typeof' ;
TRY						: 'try' ;
CATCH					: 'catch' ;

KEYWORD					: (IMPORT | MODULE | IF | ELSE | FN | WHILE | FOR | RETURN | BREAK | CONTINUE | STATIC | PRIVATE | CONST | TYPEOF | TRY | CATCH) ;

LESS					: '<'	;
LESSEQ					: '<='	;
GREATER					: '>'	;
GREATEREQ				: '>='	;
EQUAL					: '=='	;
NOTEQUAL				: '!='	;
IS						: 'is' ;

AND						: '&&' ;
OR						: '||' ;

ASTERISK				: '*'	;
SLASH					: '/'	;
PLUS					: '+'	;
MINUS					: '-'	;
REMAINDER				: '%'	;
EXPONENT				: '**'	;

BITAND					: '&' ;
BITOR					: '^' ;
BITXOR					: '|' ; 
BITSHIFTL				: '<<' ; 
BITSHIFTR				: '>>' ; 
BITSHIFTUR				: '>>>' ; 

INCREMENT				: '++'	;
DECREMENT				: '--'	;
NOT						: '!' ;
BITNOT					: '~' ;

TERNARYTRUE				: '?' ;
TERNARYFALSE			: ':' ;

ASSIGN					: '='	;

NULL					: 'null' ;

BOOLEAN					: TRUE | FALSE ;

NAME					: ('_' | LETTER) ('_' | LETTER | DIGIT)*;

NUMBER					: DIGIT+ ('.' DIGIT+)?;

STRING					: '"' ~('"')* ('"' | {
	CompileErrorHandler.TolerateError(
		CharIndex,
		_tokenStartLine,
		_tokenStartCharPositionInLine,
        "Unterminated string."
    );
}) ;

WHITESPACE				: [ \n\t\r]+ -> channel(HIDDEN);

COMMENT					: '/*' .*? '*/' -> skip ;

LINE_COMMENT			: '//' ~[\r\n]* -> skip ;

// handle characters which failed to match any other token
ErrorCharacter : . ;