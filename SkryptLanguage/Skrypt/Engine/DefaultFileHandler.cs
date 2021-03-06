﻿using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Skrypt {
    public class DefaultFileHandler : IFileHandler {
        public SkryptEngine Engine { get; set; }
        public string File { get; set; }
        public string Folder { get; set; }
        public string BaseFolder { get; set; }

        public DefaultFileHandler (SkryptEngine e) {
            Engine = e;
        }

        public string Read(string path) {
            var str = string.Empty;

            var fullPath = Path.Combine(BaseFolder, path);

            using (var sr = new StreamReader(fullPath)) {
                str = sr.ReadToEnd();
            }

            return str;
        }

        public void Write(string destination, string content) {
            var fullPath = Path.Combine(BaseFolder, destination);

            var directory = Path.GetDirectoryName(fullPath);

            if (!Directory.Exists(directory)) {
                Directory.CreateDirectory(directory);
            }

            using (var sr = new StreamWriter(fullPath)) {
                foreach (var c in content) { 
                    sr.Write(c);
                }
            }
        }

        public async void ReadAsync(string path, FunctionInstance callback) {
            char[] result;
            var builder = new StringBuilder();
            var fullPath = Path.Combine(BaseFolder, path);

            using (var sr = new StreamReader(fullPath)) {
                result = new char[sr.BaseStream.Length];

                await sr.ReadAsync(result, 0, (int)sr.BaseStream.Length);
            }

            foreach (var c in result) {
                if (char.IsLetterOrDigit(c) || char.IsWhiteSpace(c)) {
                    builder.Append(c);
                }
            }

            callback.Run(Engine.CreateString(builder.ToString()));
        }

        public async void WriteAsync(string destination, string content, FunctionInstance callback) {
            var fullPath = Path.Combine(BaseFolder, destination);

            var directory = Path.GetDirectoryName(fullPath);

            if (!Directory.Exists(directory)) {
                Directory.CreateDirectory(directory);
            }

            using (var sw = new StreamWriter(fullPath)) {
                foreach (var c in content) {
                    await sw.WriteAsync(c);
                }
            }

            callback.Run();
        }
    }
}
