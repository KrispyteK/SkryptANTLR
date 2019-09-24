﻿using System;
using Antlr4.Runtime;
using Antlr4.Runtime.Misc;
using Skrypt.ANTLR;

namespace Skrypt {
    public partial class SkryptVisitor : SkryptBaseVisitor<BaseObject> {
        public override BaseObject VisitMemberDefinitionStatement(SkryptParser.MemberDefinitionStatementContext context) {
            var value = Visit(context.expression());

            if (value is IValue noref) value = noref.Copy();

            context.name().variable.Value = value;

            return DefaultResult;
        }
    }
}
