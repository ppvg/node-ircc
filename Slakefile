{spawn} = require \child_process
require! [\fs \path \gaze \q]

/* Tasks */

task \build 'Compile src/*.ls to lib/*.js' ->
  clean!.then build .catch (e) -> console.log e.message

task \test 'Run the tests' ->
  buildAndTest!.catch (e) -> process.exit 1

task \watch 'Build and test when files are changed' ->
  clearTerminal!.then buildAndTest
  watch \src/*, -> clearTerminal!.then buildAndTest
  watch \test/*, -> clearTerminal!.then test

task \coverage 'Code coverage report and badge using jscoverage' ->
  process.env.\IRCC_COV = 1
  clean!
    .then build
    .then jscoverage
    .then coverageReport
    .then coverageBadge
    .finally -> rm \lib-cov

/* Actions */

clean = -> rm \lib

build = -> livescript \lib, \src

test = -> mocha [\--reporter, \spec, \-G], \inherit

buildAndTest = -> clean! .then build .then test .catch (e) -> console.error e.message

jscoverage = ->
  build!.then ->
    jscov = spawn \jscoverage, ['--no-highlight', 'lib', 'lib-cov'], {stdio: 'inherit'}
    deferred = q.defer!
    jscov.on \exit, (code, signal) ->
      if signal? or code isnt 0 then deferred.reject!
      else deferred.resolve!
    deferred.promise

coverageReport = ->
  mochaCov \html
    .then -> console.log "Code coverage report written to 'coverage.html'"
    .catch (e) -> console.error 'Unable to generate code coverage report:', e

coverageBadge = ->
  mochaCov \json
    .then createBadge
    .then -> console.log "Code coverage badge written to 'coverage.png'"
    .catch (e) -> console.error 'Unable to generate code coverage badge:', e

/* Helpers */

watch = (glob, callback) ->
  new gaze.Gaze [glob] .on \all, callback

livescript = (libPath, srcPath) ->
  srcFiles = [path.join srcPath, file for file in dir srcPath when /\.ls$/.test file]
  stderrOutput = ''
  lsc = spawn \lsc, [\-bco libPath] ++ srcFiles
  lsc.stderr.on \data, -> stderrOutput += it.toString!
  deferred = q.defer!
  lsc.on \exit, (error) ->
    if stderrOutput.length > 0 then deferred.reject new Error stderrOutput
    else deferred.resolve!
  deferred.promise

mocha = (args, io=\ignore) ->
  args ++= [\-c \--compilers \ls:LiveScript \-r \test/common]
  mocha = spawn \mocha, args, { stdio: io }
  deferred = q.defer!
  mocha.on \exit, (code, signal) ->
    if signal? or code isnt 0 then deferred.reject!
    else deferred.resolve!
  deferred.promise

mochaCov = (type) ->
  file = fs.openSync "coverage.#{type}", \w
  mocha [\--reporter "#{type}-cov"], [\ignore, file, \ignore]

createBadge = ->
  badge = require \coverage-badge
  json = JSON.parse fs.readFileSync \coverage.json
  file = fs.createWriteStream \coverage.png
  badge json.coverage .pipe file

getDirs = (folder) ->
  (fs.readdirSync folder).filter (file) ->
    isDirectory (path.join folder, file)

isDirectory = -> (fs.lstatSync it).isDirectory!

clearTerminal = -> q (process.stdout.write '\u001B[2J\u001B[0;0f')

rm = (path) ->
  deferred = q.defer!
  (spawn \rm [\-r path]).on \exit, deferred~resolve
  deferred.promise
