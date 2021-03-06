﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Skrypt {
    public class BooleanInstance : SkryptInstance, IValue {
        public override string Name => "Boolean";

        public bool Value { get; set; }

        public BooleanInstance(SkryptEngine engine, bool value) : base(engine) {
            Value = value;
        }

        public static implicit operator bool(BooleanInstance d) {
            return d.Value;
        }

        public override bool IsTrue() {
            return Value;
        }

        public override string ToString() {
            return Value.ToString();
        }

        public SkryptObject Copy() {
            return Engine.CreateBoolean(Value);
        }

        SkryptObject IValue.Copy() {
            return Engine.CreateBoolean(Value);
        }

        bool IValue.Equals(IValue other) {
            return this.Value.Equals(((BooleanInstance)other).Value);
        }
    }
}