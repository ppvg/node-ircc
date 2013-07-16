require! dnode
require! events

module.exports = class PersistentConnectionClient extends events.EventEmitter
  (socket, onConnect) ~>
    if typeof onConnect is \function then @on \connect, onConnect
    remote = null

    d = dnode incoming: (message) ~>
      @emit \message, message
    d.on \remote, (r) ~>
      remote := r
      @emit \connect
    socket.pipe d .pipe socket

    <[connect close send]>.forEach (func) ~>
      @[func] = (...args) ->
        if not remote? then throw new Error 'Not connected'
        else remote[func] ...args
