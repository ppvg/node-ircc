global.path = require('path');
global.chai = require('chai');
global.sinon = require('sinon');
global.chai.use(require('sinon-chai'));
global.expect = chai.expect;
chai.should()
global.mockery = require('mockery');
global.libPath = process.env.IRCC_COV
  ? path.join(__dirname, '..', 'lib-cov')
  : path.join(__dirname, '..', 'lib');
global.modulePath = function() {
  var args = Array.prototype.slice.call(arguments, 0);
  args.unshift(global.libPath);
  return path.join.apply(path, args);
};
global.catchCallback = function(obj, func, type) {
  var callback;
  obj[func] = function(t, cb) {
    if (t === type)
      return callback = cb;
  };
  return function() {
    if (typeof callback === 'function')
      callback.apply(this, arguments);
  };
};