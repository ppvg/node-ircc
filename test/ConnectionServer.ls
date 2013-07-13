should = it

var ConnectionServer
pathToModule = path.join libPath, \ConnectionServer

before ->
  mockery.enable!
  mockery.registerAllowable pathToModule, true
  mockery.registerMock \./Connection, {}
  mockery.registerMock \./createUnixServer, {}
  ConnectionServer := require pathToModule

after ->
  mockery.deregisterAll!
  mockery.disable!

describe 'ConnectionServer', ->
  void
