###
#!/usr/bin/env node
###
sisig = require './sisig'
___ = require('parkplace').scope sisig
_ = require 'lodash'
chalk = require 'chalk'
hasAnsi = require 'has-ansi'
stripAnsi = require 'strip-ansi'
Deferred = require('promised-io/promise').Deferred

currentFile = __filename.split('/')
parentDirectory = currentFile.slice(0, -2).join '/'

sisig.databaseLocation = parentDirectory + '/db/cachefile.json'

argv = require('minimist')(process.argv.splice 2)

if argv.tomorrow?
    argv.when = 'tomorrow'

if argv.today?
    argv.when = 'today'

options = {
    colors: if argv.colors? then argv.colors else false
    shutup: if (argv.q? or argv.quiet? or argv.shutup?) then true else false
    terse: if argv.terse? then argv.terse else false
    json: if argv.json? then argv.json else false
    force: if (argv.force? or argv.f?) then true else false
    when: if argv.when? then argv.when else 'all'
}
if options.json
    options.terse = true
    options.colors = false
if options.terse
    options.shutup = true

___.readable 'print', (data)->
    afterFirst = false
    if options.json
        return data
    return _(data).map((info)->
        start = "Senor Sisig will be available"
        if afterFirst
            start = _([0..start.length-1]).map(()-> return ' ').value().join('')
        else
            afterFirst = true
        {date, title, location} = info
        if options.colors
            date = chalk.inverse date
            title = chalk.red title
            location = chalk.yellow location
        if info.open
            activeTime = "#{info.time.start} to #{info.time.end}"
            if options.colors
                activeTime = chalk.green activeTime
            if options.terse
                return "#{date} | #{title} | #{location} | #{activeTime}"
            else
                return "#{start} on #{date} at '#{title}' near #{location} from #{activeTime}."
        else
            closed = 'closed'
            if options.colors
                if options.terse
                    closed = closed.toUpperCase()
                closed = chalk.red closed
            if options.terse
                return "#{date} | #{closed}"
            else
                return "Senor Sisig will be #{closed} on #{date}."
        ).value().join '\n'

ready = ()->
    console.log sisig.print sisig.filterByDate options.when
    if sisig.cachefile.staleData or !sisig.cachefile.hasFile or options.force
        good = ()->
            process.exit()
        bad = (e)->
            console.log "Error writing cachefile.", e
            process.exit()
        sisig.writeCache().then good, bad
    setTimeout ()->
        process.exit()
    , 10000


fail = ()->
    console.log "Fail is the best!", arguments

if options.force
    sisig.loadFromWeb().then ready, fail
else
    sisig.load().then ready, fail