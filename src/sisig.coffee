_ = require 'lodash'
_.mixin {
    matchesAnyKey: (pipe, addition)->
        if _.isObject pipe
            pipe = _.keys pipe
        remaining = _(arguments).toArray()
                                .rest()
                                .value()
        if remaining.length is 1
            if _(_.first(remaining)).isArray()
                remaining = remaining[0]
        return _.intersection(pipe, remaining).length > 0
}, {
    chain: false
}
fs = require 'fs'
moment = require 'moment'
pp = require 'parkplace'

Crawler = require 'crawler'

prettyHTML = require('js-beautify').html

promise = require 'promised-io/promise'
pfs = require 'promised-io/fs'
Deferred = promise.Deferred

Model = require 'ampersand-model'

Sisig = {}
___ = pp.scope Sisig

___.mutable 'staleDataThreshold', 72e5
___.mutable 'databaseLocation', 'cachefile.json'

Cachefile = Model.extend {
    session:
        hasFile: ['boolean', true, false]

    props: 
        lastCalled: 
            type: 'number'
            required: true
            default: ()->
                return Date.now()
        dates:
            type: 'array'
            required: true
        lastScrape:
            type: 'string'
            required: false
            default: ''

    derived:
        calendar:
            deps: [
                'dates'
            ]
            cache: true
            fn: ()->
                return _ @dates
        staleData:
            deps: [
                'lastCalled'
            ]
            cache: false
            fn: ()->
                diff = Math.abs @lastCalled - Date.now()
                return diff > Sisig.staleDataThreshold


    filterByDate: (givenTime)->
        d = new Date()
        if givenTime?
            if givenTime instanceof Date
                d = givenTime
            else if _.isString givenTime
                if givenTime is 'all'
                    return @calendar.value()
                if givenTime is 'tomorrow'
                    d.setDate(d.getDate() + 1)
                else if givenTime.indexOf('-') isnt -1
                    hyphenated = givenTime.split '-'
                    if hyphenated.length is 3
                        d = Sisig.parseDate givenTime
                    else if _(hyphenated).matchesAnyKey 'days|day'.split '|'
                        days = parseInt _.first hyphenated
                        d = new Date moment(d).add days, 'days'
        matching = {
            date: Sisig.formatDate d
        }
        return @calendar.where matching
                        .value()
}

___.readable 'formatDate', (d, verbose=false)->
    if _.isNumber d
        d = new Date d
    if d instanceof Date
        if verbose
            return moment(d).format 'YYYY[-]MM[-]DD[ ]HH:mm:ss'
        return moment(d).format 'YYYY[-]MM[-]DD'
    return false

___.readable 'parseDate', (str)->
    d = new Date()
    parts = str.split '-'
    d.setMonth parts[1] - 1
    d.setDate parts[2]
    d.setYear parts[0]
    return d

___.mutable 'cachefile', new Cachefile()

_([
    'on'
    'once'
    'trigger'
    'off'
    'filterByDate'
]).each (method)->
    ___.readable method, ()->
        Sisig.cachefile[method].apply Sisig.cachefile, arguments

___.constant 'consume', (input)->
    if input?.lastScrape?
        @cachefile.lastScrape = input.lastScrape
    if input?.lastCalled?
        @cachefile.lastCalled = input.lastCalled
    if input?.dates?
        @cachefile.dates = input.dates
        @trigger 'loaded', @

___.readable 'writeFile', (file, output, json=true)->
    d = new Deferred()
    good = ()->
        d.resolve true
    bad = (e)->
        d.reject e
    if json
        output = JSON.stringify output, null, 4
    pfs.writeFile(file, output).then good, bad
    return d

___.readable 'readFile', (filename, json=true)->
    d = new Deferred()
    file = pfs.readFile filename, {
        charset: 'utf8'
    }
    good = (input)->
        output = input.toString()
        if !output? or output.length is 0
            d.reject new Error "File is empty."
            return
        if json
            output = JSON.parse output
        d.resolve output
    bad = (e)->
        d.reject e
    file.then good, bad
    return d

___.readable 'parse', (e, res, $)->
    try
        d = new Deferred()
        self = Sisig
        if e?
            d.reject e
            console.log "error during parsing", e
            # self.trigger 'error:parse', e
            return
        if res?.body?
            Sisig.cachefile.lastScrape = res.body
        else
            Sisig.cachefile.lastScrape = res
        scrape = ()->
            try
                sections = $('#find-us').find "section:not([data-wcal-date=error])"
                output = []
                sections.each ()->
                    section = $ @
                    rawDateData = section.attr 'data-wcal-date'
                    relativeDate = self.parseDate rawDateData
                    rows = section.find '.map-row'
                    rows.each ()->
                        active = $ @
                        title = active.find 'h5'
                                      .eq 0
                                      .text()
                                      .trim()
                        location = active.find '.map-trigger'
                                         .text()
                                         .split '. ,'
                                         .join ','
                        activeTime = active.find '.time'
                                           .text()
                                           .trim()
                        activeTime = _(activeTime.split('\n')).map((word)->
                            return word.trim()
                        ).value().join(' ')
                        data = {
                            date: self.formatDate relativeDate
                            title: title
                            open: if location.length isnt 0 then true else false
                        }
                        if data.open
                            data.location = location
                            time = activeTime.split ' to '
                            data.time = {
                                start: time[0]
                                end: time[1]
                            }
                            convertToFullTime = (time)->
                                moment time, 'HH:mm[ ]a'
                            time[0] = Number convertToFullTime time[0]
                            time[1] = Number convertToFullTime time[1]
                            data.pedanticTime = {
                                start: self.formatDate time[0], true
                                end: self.formatDate time[1], true
                            }
                        output.push data
                        return
                    return
                self.consume {dates: output}
                d.resolve output
                return
            catch e
                d?.reject? e
        scrape()
        return d
    catch e
        d?.reject? e

___.readable 'crawler', _.once ()->
    return new Crawler {
        maxConnections: 1
        jQuery:
            name: 'cheerio'
            options:
                normalizeWhitespace: true
        callback: Sisig.parse
    }

___.readable 'loadFromWeb', ()->
    self = @
    d = new Deferred()
    @once 'error:parse', (e)->
        d.reject e
    @once 'loaded', ()->
        d.resolve self
    @crawler().queue 'http://senorsisig.com'
    return d

___.readable 'loadFromFile', (filename)->
    d = new Deferred()
    self = @
    bad = (error)->
        d.reject error
    good = (input)->
        self.consume input
        d.resolve Sisig
    @readFile(filename).then good, bad
    return d

___.readable 'load', ()->
    self = @
    d = new Deferred()

    self.once 'error:parse', (e)->
        d.reject e

    self.once 'loaded', ()->
        d.resolve self

    scrape = self.loadFromWeb

    good = ()->
        # we have a file, so we can infer staleness
        self.cachefile.hasFile = true
        if self.cachefile.staleData
            scrape()
        else
            d.resolve self

    bad = (e)->
        # we don't have a file, so we'll have to scrape
        scrape()

    @loadFromFile(@databaseLocation).then good, bad
    return d

___.readable 'writeCache', ()->
    @cachefile.lastCalled = Date.now()
    return @writeFile @databaseLocation, @cachefile.toJSON()

module.exports = Sisig