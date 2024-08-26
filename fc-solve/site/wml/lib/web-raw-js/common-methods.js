// NOTE!!! These polyfills / shims are NOT currently used, given
// wide-browser-support:
//
// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/repeat#browser_compatibility
//
// Common methods for various stuff that may not be supported (MSIE 8 and
// below - I'm looking at you.)
// Taken from http://stackoverflow.com/questions/202605/repeat-string-javascript
if (!String.prototype.repeat) {
String.prototype.repeat = function(count) {
    if (count < 1) return '';
    var result = '', pattern = this.valueOf();
    while (count > 0) {
        if (count & 1) result += pattern;
        count >>= 1, pattern += pattern;
    };
    return result;
};
}
