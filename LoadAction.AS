// ===============================
// Flash 8 / AS2  JSONツリー表示（全展開）
// 要: JSON.as (class JSON { static function parse(...) {} })
// ステージ: urlInput(TextInput), loadBtn(Button), tree(Tree)
// ===============================

XML.prototype.ignoreWhite = true;

// 初期URL
urlInput.text = "https://gist.githubusercontent.com/neo77799/705e53f48ecf050cbb348e2fa8b38e4b/raw/730f07281e2cdb3cdaadac50605ef03bdd6ce282/sample.json";

// ---- Tree の見た目調整 ----
tree.rowHeight = 20;
tree.horizontalScrollPolicy = "auto";
tree.verticalScrollPolicy = "auto";   // ※ XMLを渡すので labelField は設定しない

// ---- Loadボタン ----
loadBtn.label = "Load";
loadBtn.onRelease = function():Void {
  if (!urlInput.text || urlInput.text.length == 0) return;
  loadJSON(urlInput.text);
};

// ---- JSON を読み込み → パース → ツリーに反映 ----
function loadJSON(url:String):Void {
  showMessage("Loading...");
  var lv:LoadVars = new LoadVars();
  lv.onData = function(raw:String):Void {
    if (raw == undefined) { showMessage("? Load error"); return; }
    try {
      var data:Object = JSON.parse(raw, { mode:"strict" }); // 必要なら lenient に
      var xml:XML = jsonToTreeXML("(root)", data);
      tree.dataProvider = xml;

      // 描画完了を待ってから "確実に" 全展開
      var tid:Number = setInterval(function() {
        clearInterval(tid);
        expandAllNow();
      }, 50);

    } catch (e) {
      showMessage("? Parse error: " + errToString(e));
    }
  };
  // 別ドメインは読み先サーバに crossdomain.xml が必要
  lv.load(url);
}

// ---- メッセージをツリーに表示 ----
function showMessage(msg:String):Void {
  var x:XML = new XML();
  var n:XMLNode = x.createElement("node");
  n.attributes.label = msg;
  x.appendChild(n);
  tree.dataProvider = x;
}

// ---- JSON → Tree 表示用 XML に変換 ----
function jsonToTreeXML(rootLabel:String, value):XML {
  var x:XML = new XML();
  var root:XMLNode = x.createElement("node");
  root.attributes.label = rootLabel;
  x.appendChild(root);
  addValueNode(x, root, null, value);
  return x;
}

// value を node にぶら下げる（再帰）
function addValueNode(x:XML, parent:XMLNode, key:String, val):Void {
  var label:String = (key != null) ? key : "(value)";

  // プリミティブ or null は葉
  if (val == null || (typeof val != "object")) {
    var leaf:XMLNode = x.createElement("node");
    leaf.attributes.label = label + " : " + String(val);
    parent.appendChild(leaf);
    return;
  }

  // コンテナ（配列/オブジェクト）
  var container:XMLNode = x.createElement("node");
  container.attributes.label = label + ((val instanceof Array) ? " [array]" : " [object]");
  parent.appendChild(container);

  if (val instanceof Array) {
    for (var i:Number = 0; i < val.length; i++) {
      addValueNode(x, container, "[" + i + "]", val[i]);
    }
    if (val.length == 0) {
      var emptyA:XMLNode = x.createElement("node");
      emptyA.attributes.label = "(empty)";
      container.appendChild(emptyA);
    }
  } else {
    // AS2 の for..in は関数や未定義も拾うので弾く。見やすさのためキーをソート
    var keys:Array = [];
    for (var kk in val) {
      if (typeof val[kk] != "function" && typeof val[kk] != "undefined") keys.push(kk);
    }
    keys.sort();
    if (keys.length == 0) {
      var emptyO:XMLNode = x.createElement("node");
      emptyO.attributes.label = "(empty)";
      container.appendChild(emptyO);
    } else {
      for (var j:Number = 0; j < keys.length; j++) {
        var k:String = keys[j];
        addValueNode(x, container, k, val[k]);
      }
    }
  }
}

// ---- 全ノード展開（v2 Tree は open 属性を見ないので setIsOpen を再帰適用）----
function expandAllNow():Void {
  var dp:XML = XML(tree.dataProvider);
  if (!dp || !dp.firstChild) return;
  expandNode(dp.firstChild);
}

function expandNode(node:XMLNode):Void {
  // このノードを開く
  tree.setIsOpen(node, true, false);
  // 子があれば再帰
  var child:XMLNode = node.firstChild;
  while (child) {
    expandNode(child);
    child = child.nextSibling;
  }
}

// ---- エラーの見やすい文字列化（JSONError を想定）----
function errToString(e):String {
  if (!e) return "Unknown error";
  if (typeof e == "object") {
    var parts:Array = [];
    if (e.name) parts.push(String(e.name));
    if (e.message) parts.push(String(e.message));
    if (e.line != undefined && e.column != undefined) parts.push("at line " + e.line + ", col " + e.column);
    return parts.join(" | ");
  }
  return String(e);
}
