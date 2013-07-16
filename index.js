module.exports = require('./lib/connection/createPersistentConnection');
module.exports.createPersistentConnection = module.exports;
module.exports.codes = require('./lib/protocol/codes');
module.exports.parser = require('./lib/protocol/parser');
module.exports.serializer = require('./lib/protocol/serializer');
module.exports.ParserStream = require('./lib/protocol/ParserStream');
module.exports.SerializerStream = require('./lib/protocol/SerializerStream');
module.exports.Connection = require('./lib/connection/Connection');
module.exports.PersistentConnectionServer = require('./lib/connection/PersistentConnectionServer');
module.exports.PersistentConnectionClient = require('./lib/connection/PersistentConnectionClient');

