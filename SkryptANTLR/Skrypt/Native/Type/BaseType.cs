﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Skrypt {
    public abstract class BaseType : BaseValue {
        public BaseType(Engine engine) : base(engine) {
            var template = engine.templateMaker.CreateTemplate(this.GetType());

            GetProperties(template.Members);

            engine.SetGlobal(template.Name, this);

            Name = template.Name;
        }

        public Template Template;
        public List<BaseTrait> Traits = new List<BaseTrait>();
        public abstract BaseInstance Construct(Arguments arguments);

        public override string ToString() {
            var str = $"{Name}";
            str += "\nTraits: ";

            if (Traits.Any()) {
                foreach (var t in Traits) {
                    str += $"{t.Name} ";
                }
            } else {
                str += "none";
            }

            foreach (var kv in Members) {
                str += $"\n{kv.Key}:\t{kv.Value.Value}";
            }

            return str;
        }
    }
}