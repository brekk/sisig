###
#!/usr/bin/env node
###
Crawler = require 'crawler'
url = require 'url'
_ = require 'lodash'
cheerio = require 'cheerio'
chalk = require 'chalk'
prettyHTML = require('js-beautify').html
fs = require 'fs'

currentFile = __filename.split('/')
parentDirectory = currentFile.slice(0, -2).join '/'

argv = require('minimist')(process.argv.splice 2)

hasData = false
cache = {
    "last-called": Date.now()
}
cachefile = parentDirectory + '/db/cache.json'
try
    cache = require cachefile
    if cache?
        hasData = true
    console.log "cachefile found"
catch e
    console.log "no cachefile found."

options = {
    colors: if argv.colors? then argv.colors else false
    shutup: if (argv.q? or argv.quiet? or argv.shutup?) then true else false
    terse: if argv.terse? then argv.terse else false
    json: if argv.json? then argv.json else false
    force: if (argv.force? or argv.f?) then true else false
}
if options.json
    options.terse = true
    options.colors = false
if options.terse
    options.shutup = true

index = 0
highlight = (str)->
    if index is 0
        pre = ''
        main = str.slice 0, 1
        post = str.slice 1
    else
        pre = str.slice 0, index
        main = str.slice index, index + 1
        post = str.slice index + 1
    if options.colors
        main = chalk.red main
    if index + 1 < str.length
        index += 1
    else
        index = 0
    return pre + main + post

announcement = null
unless options.shutup
    announcement = setInterval ()->
        process.stdout.clearLine()
        process.stdout.cursorTo(0)
        process.stdout.write highlight "Loading the burrito data... "
    , 100

forceZeroes = (n)->
    if _.isNumber(n) and n < 10
        return '0' + n
    return '' + n

timeOutKill = ()->
    fail = "Unable to ascertain where the burritos at."
    if options.colors
        fail = chalk.red fail
    console.log fail
    process.exit()

readyNow = ()->
    lookBack = 72e5
    writeWhenDone = true
    twoHoursAgo = Date.now() - lookBack
    if cache['last-called'] <= twoHoursAgo
        writeWhenDone = false
    return writeWhenDone

crawlback = _.once (e, res, $)->
    console.log "CRAWLBACK"
    if e?
        console.log "Error during crawling", e
        if e.stack?
            console.log e.stack
        return
    setTimeout timeOutKill, 10000
    if announcement?
        clearInterval announcement
        process.stdout.clearLine()
        process.stdout.cursorTo(0)
        process.stdout.write "  \n"
    unless options.terse
        console.log ""
    writeWhenDone = readyNow()
    if writeWhenDone
        cache.raw = prettyHTML res.body
    scrapeAndRead = (cb)->
        sections = $('#find-us').find 'section'
        d = new Date()
        date = d.getFullYear() + '-' + forceZeroes (d.getMonth() + 1) + '-' + forceZeroes d.getDate()
        rows = $("section[data-wcal-date=#{date}]").find('.map-row')
        first = false
        output = []
        rows.each ()->
            active = $ @
            title = active.find('h5').eq(0).text()
            location = active.find('.map-trigger').text().split('. ,').join(',')
            activeTime = active.find('.time').text().trim()
            activeTime = _(activeTime.split('\n')).map((word)->
                return word.trim()
            ).value().join(' ')
            time = activeTime.split ' to '
            data = {
                title: title
                location: location
                time: {
                    start: time[0]
                    end: time[1]
                }
            }
            if options.colors
                title = chalk.red title
                location = chalk.yellow location
                activeTime = chalk.green activeTime
            unless options.terse
                start = "Senor Sisig will be available at"
                if first
                    start = "                                "
                console.log "#{start} \"#{title}\" near #{location} from #{activeTime}."
            else
                unless options.json
                    console.log "#{title} | #{location} | #{activeTime}"
            output.push data
            first = true
            return
        if options.json
            process.stdout.write JSON.stringify output
        if writeWhenDone
            cache.data = output
        if cb? and _.isFunction cb
            cb()
        return
    scrapeAndRead ()->
        if writeWhenDone
            console.log "writing"
            cache['last-called'] = Date.now()
            output = JSON.stringify cache, null, 4
            fs.writeFile cachefile, output, 'utf8', (err)->
                unless err
                    unless options.terse
                        console.log "Done!"
                    process.exit()
                    return
                console.log "Error during attempted file writing.", e
                process.exit()
                return
        else
            console.log "no writing"
            process.exit()
    return
console.log "READY NOW?", readyNow()
if hasData and readyNow()
    raw = cache.raw
    $ = cheerio.load raw, {
        normalizeWhitespace: false
        decodeEntities: true
    }
    console.log "we won't do it live"
    crawlback null, raw, $
else
    # console.log "this would normally rescrape"
    c = new Crawler
        maxConnections: 1
        jQuery: {
            name: 'cheerio'
            options: {
                normalizeWhitespace: false
            }
        }
        callback: crawlback

    c.queue 'http://senorsisig.com'