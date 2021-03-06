﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Skrypt {
    public class SkryptTrait : SkryptObject {
        public SkryptTrait(SkryptEngine engine) : base(engine) {
            var template = engine.TemplateMaker.CreateTemplate(this.GetType());

            Name = template.Name;

            TraitMembers = template.Members;
        }

        public Dictionary<string, Member> TraitMembers = new Dictionary<string, Member>();
    }
}
