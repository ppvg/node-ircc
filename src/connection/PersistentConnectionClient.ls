require! dnode
require! events

module.exports = class PersistentConnectionClient extends events.EventEmitter
  (socket) ~>
    remote = null

    callbacks =
      message: (message) ~>
        @emit \message, message
      connect: ~>
        @emit \connect
      init: ~>
        @emit \init

    (d = dnode callbacks).on \remote, (r) ~>
      remote := r

    socket.pipe d .pipe socket

    <[connect close send]>.forEach (func) ~>
      @[func] = (...args) ->
        if not remote? then throw new Error 'Not connected'
        else remote[func] ...args
