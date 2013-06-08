{spawn} = require \child_process
require! [\gaze \fs]

/* Tasks */

task \build 'Compile all LiveScript from src/ to JavaScript in lib/' ->
  invoke \clean
  lsc [\-bco \lib] ++ ["src/#file" for file in dir \src when /\.ls$/.test file]

task \test 'Run the tests' ->
  invoke \build
  mocha [\--reporter, \spec, \test/**/*.ls]

task \justtest 'Run the tests without running "build"' ->
  invoke \build
  mocha [\--reporter, \spec, \test/**/*.ls]

task 'watch' 'Watch, compile and test files.' ->
  run = (task) -> (->
      clearTerminal!
      invoke task)
  gaze [\src/*], ->  @on \all, run \test
  gaze [\test/*], -> @on \all, run \justtest
  (run 'test')!

task \clean 'Remove all compiled files' ->
  proc = spawn \rm [\-r \./lib]

/* Helper functions */

lsc = (args) ->
  proc = spawn \livescript args
  proc.stderr.on \data say
  proc.on \exit, (err) -> process.exit err if err
  proc.on \close, (code) -> process.exit if not code?

mocha = (args) ->
  path = \node_modules/mocha/bin/mocha
  defaults =
    \-c \--compilers \ls:LiveScript
    \-r \test/common
  args = defaults.concat args
  spawn path, args, { stdio: \inherit }

clearTerminal = -> process.stdout.write '\u001B[2J\u001B[0;0f'
