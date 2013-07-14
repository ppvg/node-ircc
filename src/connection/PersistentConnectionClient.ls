require! dnode
require! events

module.exports = class PersistentConnectionClient extends events.EventEmitter
  (socket, onRemote) ~>
    @_d = dnode incoming: (message) ~>
      @emit \message, message
    @_d.on \remote, (remote) ~>
      if typeof onRemote is \function then onRemote remote
      @emit \remote, remote
    socket.pipe(@_d).pipe(socket)