﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SandBoxScript {
    public class GetPropertyInstance : BaseInstance {
        public override string Name => "GetProperty";
        public IGetProperty Property;

        public GetPropertyInstance(Engine engine, GetPropertyDelegate property) : base(engine) {
            Property = new GetPropertyFunction(property);
        }
    }
}