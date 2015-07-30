_ = require './yolodash'
fs = require 'fs'
moment = require 'moment'

# pp = require 'parkplace'
prr = require 'prr'

# Crawler = require 'crawler'
xray = require 'x-ray'

prettyHTML = require('js-beautify').html

# promise = require 'promised-io/promise'
Promise = require 'bluebird'
# pfs = require 'promised-io/fs'
pfs = Promise.promisifyAll fs

Model = require 'ampersand-model'

debug = require('debug') 'sisig'
verbose = require('debug') 'sisig-verbose'
j4 = ->
    return _.map arguments, (arg)->
        return JSON.stringify arg, null, 4

Sisig = {}
generateDefiner = (Runner)->
    define = ()->
        args = _.toArray arguments
        args.unshift Runner
        out = prr.apply null, args
        return out

    define.mutable = (x)->
        return define x, {
            enumerable: true
            configurable: true
            writable: true
        }

    define.readable = (x)->
        return define x, {
            enumerable: true
            configurable: true
            writable: false
        }

    define.constant = (x)->
        return define x, {
            enumerable: false
            writable: false
            configurable: false
        }
    define.jetset = (x, config)->
        if config.get? or config.set?
            return Object.defineProperty Runner, x, config
        return false
    return define


Cachefile = ()->
    $ = {name: 'cachefile'}
    ___ = @
    chacha = generateDefiner $
    chacha.readable {
        hasFile: false
        isVerbose: false
        lastCalled: Date.now()
    }
    return $

burrito = generateDefiner Sisig

burrito.mutable {
    staleDataThreshold: 72e5
    databaseLocation: 'cachefile.json'
    cachefile: new Cachefile()
}

lastCalled = null

burrito.jetset 'lastCalled', {
    get: ->
        unless lastCalled?
            lastCalled = Date.now()
        return lastCalled
    set: (x)->
        if _.isNumber x
            lastCalled = x
            return true
        return false
    enumerable: true
    configurable: true
}

burrito.readable {
    dates: []
}

module.exports = Sisig


