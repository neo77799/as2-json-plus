// JSON.as (ActionScript 2) ? Strict + Lenient モード対応
// 2005年版実装を拡張：指数表記、Unicodeサロゲート、行列エラー、コメント/末尾カンマ/単一引用/未引用キー(オプション)。
// stringify: replacer/space、U+2028/U+2029 エスケープ、DoS対策(maxDepth/maxLength)、大整数保護(preserveBigIntAsString)

class JSON {

    static var DEFAULTS:Object = {allowComments: false,
            allowTrailingComma: false,
            allowSingleQuotes: false,
            allowUnquotedKeys: false,
            preserveBigIntAsString: false,
            maxDepth: 512,
            maxLength: 10 * 1024 * 1024,
            mode: "strict"};

    // ========= Public API =========
    static function parse(text:String, options:Object):Object {
        if (options == null)
            options = {};
        for (var k:String in DEFAULTS)
            if (options[k] === undefined)
                options[k] = DEFAULTS[k];
        if (options.mode == "strict") {
            options.allowComments = false;
            options.allowTrailingComma = false;
            options.allowSingleQuotes = false;
            options.allowUnquotedKeys = false;
        }
        var p:Object = _makeParser(text, options);
        return p.parse();
    }

    // replacer: 関数 or 配列, space: 数値(0..10) or 文字列(<=10)
    static function stringify(value, replacer, space):String {
        var s:Object = _makeStringify(replacer, space);
        return s.run(value);
    }

    // ========= 内部: Parser =========
    static function _makeParser(text:String, opt:Object):Object {
        var t:String = text;
        var i:Number = 0;
        var ch:String = " ";
        var line:Number = 1;
        var col:Number = 0;
        var len:Number = (t == null ? 0 : t.length);

        if (len > opt.maxLength)
            error("Input too large");
        if (len >= 1 && t.charCodeAt(0) == 0xFEFF) {
            i = 1;
        }

        function next():String {
            if (i >= len) {
                ch = "";
                return ch;
            }
            ch = t.charAt(i++);
            if (ch == "\n") {
                line++;
                col = 0;
            } else {
                col++;
            }
            return ch;
        }
        function peek():String {
            return (i < len) ? t.charAt(i) : "";
        }
        function error(msg:String):Void {
            var start:Number = Math.max(0, i - 20);
            var end:Number = Math.min(len, i + 20);
            var snippet:String = t.substring(start, end);
            throw{name: "JSONError", message: msg, line: line, column: col, at: i - 1, snippet: snippet, text: t};
        }
        function skipWhite():Void {
            for (; ; ) {
                if (!ch)
                    break;
                if (ch <= " " || ch == "\u00A0") {
                    next();
                    continue;
                }
                if (opt.allowComments && ch == "/") {
                    var p:String = peek();
                    if (p == "/") {
                        while (next() && ch != "\n" && ch != "\r") {
                        }
                        continue;
                    } else if (p == "*") {
                        next();
                        next();
                        for (; ; ) {
                            if (!ch)
                                error("Unterminated comment");
                            if (ch == "*" && peek() == "/") {
                                next();
                                next();
                                break;
                            }
                            next();
                        }
                        continue;
                    }
                }
                break;
            }
        }
        function fromCodePoint(cp:Number):String {
            if (cp <= 0xFFFF)
                return String.fromCharCode(cp);
            cp -= 0x10000;
            var hi:Number = 0xD800 + (cp >> 10);
            var lo:Number = 0xDC00 + (cp & 0x3FF);
            return String.fromCharCode(hi) + String.fromCharCode(lo);
        }
        function hex4():Number {
            var u:Number = 0;
            for (var k:Number = 0; k < 4; k++) {
                var c:String = next();
                var d:Number = parseInt(c, 16);
                if (!isFinite(d))
                    error("Invalid hex digit in \\u escape");
                u = u * 16 + d;
            }
            return u;
        }
        function parseString(quote:String):String {
            var s:String = "";
            if (ch != quote)
                error("Bad string start");
            while (next()) {
                if (ch == quote) {
                    next();
                    return s;
                }
                if (ch == "\\") {
                    var esc:String = next();
                    switch (esc) {
                        case '"':
                            s += '"';
                            break;
                        case "'":
                            s += "'";
                            break;
                        case "\\":
                            s += "\\";
                            break;
                        case "b":
                            s += "\b";
                            break;
                        case "f":
                            s += "\f";
                            break;
                        case "n":
                            s += "\n";
                            break;
                        case "r":
                            s += "\r";
                            break;
                        case "t":
                            s += "\t";
                            break;
                        case "u":
                            var u:Number = hex4();
                            if (u >= 0xD800 && u <= 0xDBFF) {
                                if (peek() == "\\" && (i + 1 < len) && t.charAt(i + 1) == "u") {
                                    next();
                                    next();
                                    var u2:Number = hex4();
                                    if (u2 >= 0xDC00 && u2 <= 0xDFFF) {
                                        var cp:Number = 0x10000 + ((u - 0xD800) * 0x400) + (u2 - 0xDC00);
                                        s += fromCodePoint(cp);
                                    } else
                                        error("Invalid low surrogate");
                                } else
                                    error("Missing low surrogate");
                            } else {
                                s += String.fromCharCode(u);
                            }
                            break;
                        default:
                            s += esc; // 非標準だが後方互換
                    }
                } else {
                    s += ch;
                }
            }
            error("Unterminated string");
            return null;
        }
        function parseUnquotedKey():String {
            var key:String = "";
            var c:String = ch;
            var isStart:Boolean = ((c >= "A" && c <= "Z") || (c >= "a" && c <= "z") || c == "_" || c == "$");
            if (!isStart)
                error("Bad unquoted key start");
            key += c;
            while (next()) {
                c = ch;
                var ok:Boolean = ((c >= "A" && c <= "Z") || (c >= "a" && c <= "z") || (c >= "0" && c <= "9") || c == "_" || c == "$");
                if (!ok)
                    break;
                key += c;
            }
            return key;
        }
        function parseNumber() {
            var s:String = "";
            if (ch == "-") {
                s += "-";
                next();
            }
            if (ch == "0") {
                s += "0";
                next();
                if (ch >= "0" && ch <= "9")
                    error("Leading zero not allowed");
            } else if (ch >= "1" && ch <= "9") {
                while (ch >= "0" && ch <= "9") {
                    s += ch;
                    next();
                }
            } else
                error("Bad number");
            if (ch == ".") {
                s += ".";
                next();
                if (!(ch >= "0" && ch <= "9"))
                    error("Digits required after decimal point");
                while (ch >= "0" && ch <= "9") {
                    s += ch;
                    next();
                }
            }
            if (ch == "e" || ch == "E") {
                s += ch;
                next();
                if (ch == "+" || ch == "-") {
                    s += ch;
                    next();
                }
                if (!(ch >= "0" && ch <= "9"))
                    error("Digits required in exponent");
                while (ch >= "0" && ch <= "9") {
                    s += ch;
                    next();
                }
            }
            if (opt.preserveBigIntAsString) {
                if (s.indexOf(".") < 0 && s.indexOf("e") < 0 && s.indexOf("E") < 0) {
                    var absStr:String = (s.charAt(0) == "-") ? s.substr(1) : s;
                    if (absStr.length > 15)
                        return s;
                }
            }
            var n:Number = Number(s);
            if (!isFinite(n))
                error("Bad number");
            return n;
        }
        function parseWord() {
            if (ch == "t") {
                if (next() == "r" && next() == "u" && next() == "e") {
                    next();
                    return true;
                }
            }
            if (ch == "f") {
                if (next() == "a" && next() == "l" && next() == "s" && next() == "e") {
                    next();
                    return false;
                }
            }
            if (ch == "n") {
                if (next() == "u" && next() == "l" && next() == "l") {
                    next();
                    return null;
                }
            }
            error("Syntax error");
            return null;
        }
        function parseArray(depth:Number):Array {
            if (depth > opt.maxDepth)
                error("Max depth exceeded");
            var a:Array = [];
            if (ch != "[")
                error("Bad array start");
            next();
            skipWhite();
            if (ch == "]") {
                next();
                return a;
            }
            while (ch) {
                var v = parseValue(depth + 1);
                a.push(v);
                skipWhite();
                if (ch == "]") {
                    next();
                    return a;
                }
                if (ch != ",")
                    error("Bad array separator");
                next();
                skipWhite();
                if (ch == "]") {
                    if (opt.allowTrailingComma) {
                        next();
                        return a;
                    } else
                        error("Trailing comma not allowed");
                }
            }
            error("Bad array");
            return null;
        }
        function parseObject(depth:Number):Object {
            if (depth > opt.maxDepth)
                error("Max depth exceeded");
            var o:Object = {};
            if (ch != "{")
                error("Bad object start");
            next();
            skipWhite();
            if (ch == "}") {
                next();
                return o;
            }
            while (ch) {
                var key:String;
                if (ch == '"' || (ch == "'" && opt.allowSingleQuotes))
                    key = parseString(ch);
                else if (opt.allowUnquotedKeys)
                    key = parseUnquotedKey();
                else
                    error("Object keys must be strings");
                skipWhite();
                if (ch != ":")
                    error("Missing ':' after key");
                next();
                var v = parseValue(depth + 1);
                o[key] = v;
                skipWhite();
                if (ch == "}") {
                    next();
                    return o;
                }
                if (ch != ",")
                    error("Bad object separator");
                next();
                skipWhite();
                if (ch == "}") {
                    if (opt.allowTrailingComma) {
                        next();
                        return o;
                    } else
                        error("Trailing comma not allowed");
                }
            }
            error("Bad object");
            return null;
        }
        function parseValue(depth:Number) {
            skipWhite();
            switch (ch) {
                case "{":
                    return parseObject(depth);
                case "[":
                    return parseArray(depth);
                case '"':
                    return parseString('"');
                case "'":
                    if (opt.allowSingleQuotes)
                        return parseString("'");
                    error("Unexpected single quote in strict mode");
                case "-":
                case "0":
                case "1":
                case "2":
                case "3":
                case "4":
                case "5":
                case "6":
                case "7":
                case "8":
                case "9":
                    return parseNumber();
                default:
                    return parseWord();
            }
        }
        next();
        return {parse: function():Object {
            var v = parseValue(0);
            skipWhite();
            if (ch)
                error("Trailing characters after a complete JSON value");
            return v;
        }};
    }

    // ========= 内部: Stringify =========
    static function _makeStringify(replacer, space):Object {
        var rep = replacer;
        var indent:String = null;
        var gap:String = "";

        // インデント決定（まず数値化）
        var n:Number = Number(space);
        if (!isNaN(n)) {
            if (n < 0)
                n = 0;
            if (n > 10)
                n = 10;
            indent = "";
            for (var i:Number = 0; i < n; i++)
                indent += " ";
        } else if (typeof space == "string") {
            indent = String(space).substr(0, 10);
        }

        // Array 判定（AS2互換）
        function isArray(x):Boolean {
            return (x instanceof Array) || (x && typeof x.length == "number" && (typeof x.join == "function" || typeof x.push == "function"));
        }

        // replacer 種別を先に決めておく
        var repIsArray:Boolean = isArray(rep);
        var repIsFunc:Boolean = false;
        if (!repIsArray && rep) {
            var t:String = typeof rep;
            repIsFunc = (t == "function");
            if (!repIsFunc && rep.constructor) {
                var cstr:String = String(rep.constructor);
                if (cstr.indexOf("Function") >= 0)
                    repIsFunc = true;
            }
            if (!repIsFunc) {
                var rstr:String = String(rep);
                if (rstr.indexOf("function") == 0)
                    repIsFunc = true;
            }
        }

        function quote(s:String):String {
            var out:String = '"';
            var l:Number = s.length;
            for (var i2:Number = 0; i2 < l; i2++) {
                var c:String = s.charAt(i2);
                if (c == '"' || c == '\\')
                    out += '\\' + c;
                else if (c < ' ') {
                    switch (c) {
                        case '\b':
                            out += '\\b';
                            break;
                        case '\f':
                            out += '\\f';
                            break;
                        case '\n':
                            out += '\\n';
                            break;
                        case '\r':
                            out += '\\r';
                            break;
                        case '\t':
                            out += '\\t';
                            break;
                        default:
                            var code:Number = s.charCodeAt(i2);
                            var h:String = code.toString(16);
                            while (h.length < 4)
                                h = "0" + h;
                            out += '\\u' + h;
                    }
                } else if (c == "\u2028" || c == "\u2029") {
                    var cc:Number = s.charCodeAt(i2);
                    var hh:String = cc.toString(16);
                    while (hh.length < 4)
                        hh = "0" + hh;
                    out += '\\u' + hh;
                } else
                    out += c;
            }
            return out + '"';
        }

        function str(key, holder) {
            var value = holder[key];

            if (value && typeof value == "object" && typeof value.toJSON == "function") {
                value = value.toJSON(key);
            }

            if (repIsFunc) {
                // call/apply は使わない
                value = rep(key, value);
            }

            switch (typeof value) {
                case "string":
                    return quote(value);
                case "number":
                    return isFinite(value) ? String(value) : "null";
                case "boolean":
                    return String(value);
                case "object":
                    if (!value)
                        return "null";

                    var stepback:String = gap;
                    if (indent)
                        gap += indent;

                    var partial:Array = [];
                    var v, k;

                    // 配列
                    if (isArray(value)) {
                        for (var i3:Number = 0; i3 < value.length; i3++) {
                            v = str(String(i3), value) || "null";
                            partial.push(v);
                        }
                        var res:String;
                        if (!indent)
                            res = "[" + partial.join(",") + "]";
                        else {
                            if (partial.length == 0)
                                res = "[]";
                            else
                                res = "[\n" + gap + partial.join(",\n" + gap) + "\n" + stepback + "]";
                        }
                        gap = stepback;
                        return res;
                    }

                    // オブジェクト
                    if (repIsArray) {
                        for (var j:Number = 0; j < rep.length; j++) {
                            k = rep[j];
                            if (typeof k != "string")
                                continue;
                            v = str(k, value);
                            if (v)
                                partial.push(quote(k) + (indent ? ": " : ":") + v);
                        }
                    } else {
                        for (k in value) {
                            if (typeof value[k] == "undefined" || typeof value[k] == "function")
                                continue;
                            v = str(k, value);
                            if (v)
                                partial.push(quote(k) + (indent ? ": " : ":") + v);
                        }
                    }

                    var out:String;
                    if (!indent)
                        out = "{" + partial.join(",") + "}";
                    else {
                        if (partial.length == 0)
                            out = "{}";
                        else
                            out = "{\n" + gap + partial.join(",\n" + gap) + "\n" + stepback + "}";
                    }
                    gap = stepback;
                    return out;

                default:
                    return "null";
            }
        }

        return {run: function(value) {
            var holder:Object = {};
            // 空文字キーは避ける
            holder.__root__ = value;
            return str("__root__", holder);
        }};

    }
}
