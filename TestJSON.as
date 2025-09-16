// TestJSON.as (ActionScript 2)
// 実行: フレーム1などで  _root.onLoad = function(){ TestJSON.run(); };

class TestJSON {

    static var passed = 0;
    static var failed = 0;
    static var total  = 0;

    static function run() {
        trace("\n=== JSON.as Test Suite (minimal) ===");
        passed = 0; failed = 0; total = 0;

        // ---------------------------
        // 1) strict: exponent number
        // ---------------------------
        doTest("strict: exponent number", function() {
            var o = JSON.parse("{\"x\":1e-3,\"y\":1E+2}");
            return (o.x == 0.001) && (o.y == 100);
        });

        // ----------------------------------
        // 2) strict: Unicode surrogate pairs
        // ----------------------------------
        doTest("strict: Unicode surrogate pairs", function() {
            var o = JSON.parse("{\"face\":\"\\uD83D\\uDE00\"}");
            return (typeof o.face == "string") && (o.face.length == 2);
        });

        // --------------------------------------
        // 3) strict: trailing comma should fail
        // --------------------------------------
        doTestExpectError("strict: trailing comma should fail", function() {
            // ここはエラーが出てほしい
            JSON.parse("{\"a\":1,}", {mode:"strict"});
        }, "Trailing");

        // -----------------------------
        // 4) lenient: trailing comma OK
        // -----------------------------
        doTest("lenient: trailing comma OK", function() {
            var o1 = JSON.parse("{\"a\":1,}", {mode:"lenient", allowTrailingComma:true});
            // 簡易比較
            return (o1.a == 1) && (countKeys(o1) == 1);
        });

        // ----------------------------
        // 5) lenient: single quotes OK
        // ----------------------------
        doTest("lenient: single quotes OK", function() {
            var o2 = JSON.parse("{'a':'b','n':'\\u0041'}", {mode:"lenient", allowSingleQuotes:true});
            return (o2.a == "b") && (o2.n == "A");
        });

        // ---------------------------------
        // 6) lenient: unquoted keys OK
        // ---------------------------------
        doTest("lenient: unquoted keys OK", function() {
            var o3 = JSON.parse("{ a:1, b:2 }", {mode:"lenient", allowUnquotedKeys:true});
            return (o3.a == 1) && (o3.b == 2) && (countKeys(o3) == 2);
        });

        // ----------------------------
        // 7) lenient: comments OK
        // ----------------------------
        doTest("lenient: comments OK", function() {
            var txt = "/* head */ { // line\n  a:1, // after\n  b:2 /* mid */ ,\n} // tail";
            var o4 = JSON.parse(txt, {mode:"lenient", allowComments:true, allowTrailingComma:true, allowUnquotedKeys:true});
            return (o4.a == 1) && (o4.b == 2) && (countKeys(o4) == 2);
        });

        // -------------------------------------
        // 8) strict: error shows line/column
        // -------------------------------------
        doTestExpectError("strict: error shows line/column", function() {
            JSON.parse("{\n  \"a\": 1,\n  \"b\":\n}", {mode:"strict"});
        }, "line"); // メッセージ内に "line" を含むことを期待

        // --------------------------------------------------
        // 9) preserveBigIntAsString: big integer kept string
        // --------------------------------------------------
        doTest("preserveBigIntAsString: big integer kept as string", function() {
            var o5 = JSON.parse("{\"big\":123456789012345678901}", {mode:"strict", preserveBigIntAsString:true});
            return (typeof o5.big == "string");
        });

        // ----------------------------------
        // 10) stringify: space/indent
        // ----------------------------------
        doTest("stringify: space/indent", function() {
            var s1 = JSON.stringify({a:1, b:[2,3]}, null, 2);
            return (s1.indexOf("\n") >= 0) && (s1.indexOf("  \"a\": 1") >= 0);
        });

        // ----------------------------------------------
        // 11) stringify: replacer(array) filters keys
        // ----------------------------------------------
        doTest("stringify: replacer(array) filters keys", function() {
            var s2 = JSON.stringify({a:1, b:2, c:3}, ["a","c"], 0);
            return (s2.indexOf("\"a\"") >= 0) && (s2.indexOf("\"c\"") >= 0) && (s2.indexOf("\"b\"") < 0);
        });

        // -----------------------------------------------------
        // 12) stringify: replacer(function) transforms values
        // -----------------------------------------------------
        doTest("stringify: replacer(function) transforms values", function() {
            var s3 = JSON.stringify({a:1, b:2}, function(k, v) {
                if (k == "b") return v*10;
                return v;
            }, 0);
            var o6 = JSON.parse(s3);
            return (o6.b == 20);
        });

        // ----------------------------------------------
        // 13) array: trailing comma (lenient)
        // ----------------------------------------------
        doTest("array: trailing comma (lenient)", function() {
            var a1 = JSON.parse("[1,2,3,]", {mode:"lenient", allowTrailingComma:true});
            return (a1 instanceof Array) && (a1.length == 3) && (a1[0] == 1) && (a1[2] == 3);
        });

        // -----------------------------------------
        // 14) strict: leading zero should fail
        // -----------------------------------------
        doTestExpectError("strict: leading zero should fail", function() {
            JSON.parse("{\"n\":01}", {mode:"strict"});
        }, "Leading zero");

        // ---------------------------------------
        // 15) strict: bad exponent should fail
        // ---------------------------------------
        doTestExpectError("strict: bad exponent should fail", function() {
            JSON.parse("{\"n\":1e}", {mode:"strict"});
        }, "exponent");

        // ---- summary ----
        trace("\n--- Summary ---");
        trace("Passed: " + passed + " / " + total + "  Failed: " + failed);
        if (failed == 0) trace("ALL GREEN!");
    }

    // ====== 最小ヘルパ（無名関数はここだけで使用） ======
    static function doTest(name, fn) {
        total++;
        try {
            var ok = fn();
            if (ok) {
                passed++;
                trace("[OK] " + name);
            } else {
                failed++;
                trace("[NG] " + name + " -> assertion failed");
            }
        } catch(e) {
            failed++;
            trace("[NG] " + name + " -> " + errToString(e));
        }
    }

    static function doTestExpectError(name, fn, mustContain) {
        total++;
        var got = false;
        try {
            fn(); // ここでエラーが出てほしい
        } catch(e) {
            var s = errToString(e);
            if (s.indexOf(mustContain) >= 0) {
                got = true;
            } else {
                trace("[NG] " + name + " -> wrong error: " + s);
            }
        }
        if (got) {
            passed++;
            trace("[OK] " + name);
        } else if (!got) {
            failed++;
            // 例外が出なかった or メッセージが違った
            trace("[NG] " + name + " -> no error or message mismatch");
        }
    }

    // ====== 補助関数 ======
    static function countKeys(o) {
        var n = 0;
        var k;
        for (k in o) n++;
        return n;
    }

    static function errToString(e) {
        if (!e) return "Unknown error";
        if (typeof e == "object") {
            var parts = [];
            if (e.name) parts.push(String(e.name));
            if (e.message) parts.push(String(e.message));
            if (e.line != undefined && e.column != undefined) parts.push("at line " + e.line + ", col " + e.column);
            if (e.snippet) parts.push("snippet: " + e.snippet);
            return parts.join(" | ");
        }
        return String(e);
    }
}
