_ = require 'lodash'
_.mixin {
    matchesAnyKey: (pipe)->
        # force array
        remaining = _(arguments).toArray()
                                .rest()
                                .value()
        # console.log remaining, "arguments extra", remaining.length
        # unless remaining.length >= 1
        if remaining.length is 1
            if _.isArray _.first remaining
                remaining = _.flatten remaining
                # console.log "flattened the remainder", remaining
        else
            # console.log "what is remaining?", remaining
        # addition = [addition]
        # console.log "match wits with the pipe", pipe
        outcome = _.intersection(pipe, remaining).length > 0
        # console.log "the outcome is neigh: #{outcome}\n\n\n"
        return outcome
}, {
    chain: false
}

module.exports = _