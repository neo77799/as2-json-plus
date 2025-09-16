// 見た目用（任意）
run_test.useHandCursor = true;

// クリックでテスト実行
run_test.onRelease = function() {
    // 連打防止（任意）
    this.enabled = false;
    trace("=== Run TestJSON ===");
    try {
        TestJSON.run();
    } catch (e) {
        trace("ERROR: " + e);
    }
    this.enabled = true;
};