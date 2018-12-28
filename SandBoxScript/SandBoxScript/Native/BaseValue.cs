﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SandBoxScript {
    public class BaseValue {
        public virtual string Name { get; set; }

        public Engine Engine { get; set; }
        public Dictionary<string, Member> Members = new Dictionary<string, Member>();

        public BaseValue(Engine engine) {
            Engine = engine;
        }

        public void GetProperties (Dictionary<string, Member> properties) {
            Members = Members.Concat(properties).ToDictionary(d => d.Key, d => d.Value);
        }

        public void GetProperties(Template template) {
            Members = Members.Concat(template.Members).ToDictionary(d => d.Key, d => d.Value);
            Name = template.Name;
        }

        public T AsType<T>() where T : BaseValue {
            return (T)this;
        }

        public override string ToString() {
            var str = $"{Name}\n";

            foreach (var kv in Members) {
                str += $"{kv.Key}: {kv.Value}\n";
            }

            return str;
        }
    }
}