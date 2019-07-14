﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Skrypt {
    class StringType : BaseType {
        public StringType(Engine engine) : base(engine) {
            Template = engine.TemplateMaker.CreateTemplate(typeof(StringInstance));
        }

        public BaseInstance Construct(string val) {
            var obj = new StringInstance(Engine, val);

            obj.GetProperties(Template);
            obj.TypeObject = this;

            return obj;
        }

        public override BaseInstance Construct(Arguments arguments) {
            return Construct(arguments[0].ToString());
        }


        public static BaseObject FromByteArray(Engine engine, BaseObject self, Arguments arguments) {
            var array = arguments.GetAs<ArrayInstance>(0);
            var rawString = "";

            for (var i = 0; i < array.SequenceValues.Count; i++) {
                var rawValue = array.SequenceValues[i];

                if (rawValue is NumberInstance num) {
                    rawString += (char)num.Value;
                } else {
                    throw new FatalErrorException("Number expected.");
                }
            }

            return engine.CreateString(rawString);
        }
    }
}