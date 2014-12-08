###
#!/usr/bin/env node
###

Crawler = require 'crawler'
url = require 'url'
_ = require 'lodash'

chalk = require 'chalk'

argv = require('minimist') process.argv.splice 2

options = {
    colors: if argv.colors? then argv.colors else false
    shutup: if (argv.q? or argv.quiet? or argv.shutup?) then true else false
    terse: if argv.terse? then argv.terse else false
    json: if argv.json? then argv.json else false
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

c = new Crawler
    maxConnections: 1
    jQuery: {
        name: 'cheerio'
        options: {
            normalizeWhitespace: true
        }
    }
    callback: (e, res, $)->
        setTimeout timeOutKill, 10000
        if annoucement?
            clearInterval announcement
            process.stdout.clearLine()
            process.stdout.cursorTo(0)
            process.stdout.write "  \n"
        sections = $('#find-us').find 'section'
        d = new Date()
        date = d.getFullYear() + '-' + forceZeroes (d.getMonth() + 1) + '-' + forceZeroes d.getDate()
        rows = $("section[data-wcal-date=#{date}]").find('.map-row')
        rows.each ()->
            active = $ @
            title = active.find('h5').eq(0).text()
            location = active.find('.map-trigger').text().split('. ,').join(',')
            activeTime = active.find('.time').text().trim()
            if options.colors
                title = chalk.red title
                location = chalk.yellow location
                activeTime = chalk.green activeTime
            unless options.terse
                console.log "Senor Sisig will be available at \"#{title}\" near #{location} from #{activeTime}."
            else
                if options.json
                    time = activeTime.split ' to '
                    process.stdout.write JSON.stringify {
                        title: title
                        location: location
                        time: {
                            start: time[0]
                            end: time[1]
                        }
                    }
                else
                    console.log "#{title} | #{location} | #{activeTime}"
            return
        process.exit()
        return

c.queue 'http://senorsisig.com'