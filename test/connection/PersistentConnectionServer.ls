should = it

var ConnectionServer
pathToModule = path.join libPath, \connection, \PersistentConnectionServer

before ->
  mockery.enable!
  mockery.registerAllowable pathToModule, true
  mockery.registerMock \./Connection, {}
  mockery.registerMock \./createUnixServer, {}
  ConnectionServer := require pathToModule

after ->
  mockery.deregisterAll!
  mockery.disable!

describe 'PersistentConnectionServer', ->
  void
