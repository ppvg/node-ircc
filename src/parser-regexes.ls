/* Scroll down for example matches */

module.exports =
  split:
    //^ (?:                   #     (non-capturing group to trim whitespace)
          :([^\x20]+)\x20+    # <-- the prefix (\x20 is ' ')
        )?                    #     (optional)
        (?:                   #     (non-capturing group to trim whitespace)
          ( [a-zA-Z]+         # <-- the command; either in letters...
          | [0-9]{3} )\x20*   # <-- ... or 3 digits. (mandatory)
        )
        (.*)                  # <-- the parameters and trailing text, if any
        (?:\r\n)? $           #     (strip off any \r\n of the end
    //
  prefix:                           # (NOTE: just "irc.example.com" will *not* match)
    //^ ( [a-zA-Z\[\]\\`_^{|}]      # <-- nickname (optional), as in RFC 2812
          [a-zA-Z\[\]\\`_^{|}0-9-]* # <-- 1 letter or special, then any number
        )?                          #     of letter, num, special or - (dash)
        (?:
          ! ([^@]+)  # <-- !user (optional, '!' is not captured)
        )?
        (?:
          @ (.+)     # <-- @host (idem)
        )?
    $//

  parameters:
    //  (.*?)        # <-- the actual parameters (non-greedy, to...
        (?:\x20*)    #  <- ...trim spaces)
        (?:
          : (.*)     # <-- trailing text (optional, ':' is not captured)
        )?
    $//

/*
":nick!user@server COMMAND param param".match module.exports.split

  [ ':nick!user@server COMMAND param param',
    'nick!user@server',
    'COMMAND',
    'param param',
    index: 0,
    input: ':nick!user@server COMMAND param param' ]

":nick!user@server".match module.exports.prefix

   [ 'nick!user@server',
    'nick',
    'user',
    'server',
    index: 0,
    input: 'nick!user@server' ]

NOTE: just "irc.example.com" on its own will *not* match.
*/
