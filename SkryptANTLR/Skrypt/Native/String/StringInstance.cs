﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Skrypt {
    public class StringInstance : BaseInstance {
        public override string Name => "String";
        public override bool CopyOnAssignment => true;

        public string Value { get; set; }

        public StringInstance(Engine engine, string value) : base(engine) {
            Value = value;
        }

        public static BaseValue Length(Engine engine, BaseValue self) {
            return engine.CreateNumber((self as StringInstance).Value.Length);
        }

        public static implicit operator string(StringInstance s) {
            return s.Value;
        }

        public override string ToString() {
            return Value.ToString();
        }
    }
}