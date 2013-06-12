{spawn} = require \child_process
require! [\gaze \fs]

/* Tasks */

task \build 'Compile all LiveScript from src/ to JavaScript in lib/' ->
  clean ->
    build!

task \test 'Run the tests' ->
  build ->
    runMocha [\--reporter, \spec, \test/**/*.ls]

task \justtest 'Run the tests without running "build"' ->
  runMocha [\--reporter, \spec, \test/**/*.ls]

task \watch 'Watch, compile and test files.' ->
  run = (task) -> (->
      clearTerminal!
      invoke task)
  gaze [\src/*], ->  @on \all, run \test
  gaze [\test/*], -> @on \all, run \justtest
  (run 'test')!

task \coverage 'Generate code coverage report using jscoverage (saved as coverage.html)' ->
  build ->
    jscov = spawn \jscoverage ['--no-highlight', 'lib', 'lib-cov'] {stdio: 'inherit'}
    jscov.on \exit (code, signal) ->
      if code is 0 and not signal?
        file = fs.createWriteStream \coverage.html
        process.env.\AETHER_COV = 1
        mocha = runMocha [\--reporter \html-cov], false
        mocha.stdout.pipe file
        mocha.on \exit, -> spawn \rm [\-r, \lib-cov]

# task \clean 'Remove all compiled files' ->
#   clean!

/* Helper functions */


clean = (cb) ->
  proc = spawn \rm [\-r \./lib]
  if cb then proc.on \exit cb

build = (cb) ->
  livescript [\-bco \lib] ++ ["src/#file" for file in dir \src when /\.ls$/.test file], cb

livescript = (args, cb) ->
  proc = spawn \livescript args
  proc.stderr.on \data say
  proc.on \exit, (err) -> process.exit err if err
  proc.on \close, (code) -> process.exit if not code?
  if cb then proc.on \exit cb

runMocha = (args, inheritStdio=true) ->
  path = \node_modules/mocha/bin/mocha
  defaults =
    \-c \--compilers \ls:LiveScript
    \-r \test/common
  args = defaults.concat args
  if inheritStdio then
    spawn path, args, { stdio: \inherit }
  else
    spawn path, args

clearTerminal = -> process.stdout.write '\u001B[2J\u001B[0;0f'
