if (process.env.SKIP_EMCC != '1') {
    QUnit.config.autostart = false;
    // QUnit.config.notrycatch = 1;
    const test_code = require('tests/fcs-core');
    const test_code2 = require('tests/fcs-purejs-rand');
    test_code.test_js_fc_solve_class(QUnit, function() {
        test_code2.test_js_fc_solve_class(QUnit, function() {
            return;
        });
    });
} else {
    QUnit.module("SKIP_EMCC");
    QUnit.test("dummy", (a) => {
        a.expect(1);

        a.ok(true, 'skipped');
    });
    QUnit.skip("SKIP_EMCC was set so skip emcc tests", (a) => {
        a.expect(1);

        a.ok(true, 'skipped');
    });
}
