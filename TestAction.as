// �����ڗp�i�C�Ӂj
run_test.useHandCursor = true;

// �N���b�N�Ńe�X�g���s
run_test.onRelease = function() {
    // �A�Ŗh�~�i�C�Ӂj
    this.enabled = false;
    trace("=== Run TestJSON ===");
    try {
        TestJSON.run();
    } catch (e) {
        trace("ERROR: " + e);
    }
    this.enabled = true;
};