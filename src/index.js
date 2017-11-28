import XRay from 'x-ray'
import {e0, e1, e2} from 'entrust'
import {
  curry,
  join,
  pipe,
  trim,
  map,
  split,
  triplet,
  K,
  I
} from 'f-utility'
import Future from 'fluture'

const X = XRay()

const DELIMITERS = Object.freeze({
  SPACE: ` `,
  NEWLINE: `\n`
})

const thingHas = curry(
  (thing, x) => thing.includes(x)
)

const splitTwice = curry(
  (d1, d2, x) => {
    // check to see if there's a prop on x
    const has = thingHas(x)
    console.log(`XXXXX`, x)
    // shortcut early
    if (!x || !has(d2)) {
      return []
    }
    return pipe(
      trim,
      split(d1),
      map(pipe(
        trim,
        split(d2),
        map(trim)
      ))
    )(x)
  }
)

const $ = X(`http://www.senorsisig.com`, `.map-row`, [{
  title: `h5`,
  location: `.map-trigger`,
  date: `.date`,
  time: `.time`
}])

const cleanify = map(pipe(
  map(splitTwice(DELIMITERS.NEWLINE, DELIMITERS.SPACE)),
  // map(join(DELIMITERS.SPACE))
))

const clean = pipe(
  cleanify
)
const barf = (x) => {
  throw x
}

$(
  triplet(I, barf, clean)
).write(`scrape.json`)
