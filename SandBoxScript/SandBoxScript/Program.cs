﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Antlr4.Runtime;
using Antlr4;
using SandBoxScript.ANTLR;

namespace SandBoxScript {
    class Program {
        static void Main(string[] args) {
            string input = "a(1,)";

            var inputStream = new AntlrInputStream(input);
            var sandBoxScriptLexer = new SandBoxScriptLexer(inputStream);
            var commonTokenStream = new CommonTokenStream(sandBoxScriptLexer);
            var sandBoxScriptParser = new SandBoxScriptParser(commonTokenStream);

            var expressionContext = sandBoxScriptParser.expression();
            var visitor = new SandBoxScriptVisitor();

            Console.WriteLine(visitor.Visit(expressionContext));

            Console.ReadKey();
        }
    }
}
