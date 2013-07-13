global.path = require('path');
global.chai = require('chai');
global.sinon = require('sinon');
global.chai.use(require('sinon-chai'));
global.expect = chai.expect;
chai.should()
global.mockery = require('mockery');
global.libPath = process.env.IRCC_COV
  ? path.join('..', 'lib-cov')
  : path.join('..', 'lib');
