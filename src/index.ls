module.exports = require('./connection/createPersistentConnection');
ircc = module.exports.createPersistentConnection = module.exports
ircc.codes = require \./protocol/codes
ircc.parser = require \./protocol/parser
ircc.serializer = require \./protocol/serializer
ircc.ParserStream = require \./protocol/ParserStream
ircc.SerializerStream = require \./protocol/SerializerStream
ircc.Connection = require \./connection/Connection
ircc.PersistentConnectionServer = require \./connection/PersistentConnectionServer
ircc.PersistentConnectionClient = require \./connection/PersistentConnectionClient