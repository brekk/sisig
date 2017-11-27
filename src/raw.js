import {e0, e1} from 'entrust'
import {trace} from 'xtrace'
import {
  prop,
  I,
  fromPairs,
  toPairs,
  filter,
  map,
  pipe,
  curry,
  split,
  join,
  trim,
  length,
  alterLastIndex,
  reject,
  triplet
} from 'f-utility'
import {gt} from 'f-utility/lib/math'

const augmentTuples = curry((hoc, fn, x) => pipe(
  toPairs,
  hoc(fn),
  fromPairs
)(x))

const toLower = e0(`toLowerCase`)
const indexOf = e1(`indexOf`)
const hasString = curry((x, y) => pipe(
  toLower,
  indexOf(x),
  gt(-1)
)(y))

export const raw = [
  {
    "title": "Sorry, no results for that day."
  },
  {
    "title": "The Truck Stop",
    "location": "450 Mission St., San Francisco, CA 94105",
    "date": "\n                                                  TODAY\n                                                  Mon\n                          11/27\n                      ",
    "time": "\n                        11:00 am\n                         to\n                         2:00 pm\n                      "
  },
  {
    "title": "2nd & Minna ",
    "location": "120 2nd St, San Francisco, CA 94105",
    "date": "\n                                                  TODAY\n                                                  Mon\n                          11/27\n                      ",
    "time": "\n                        11:00 am\n                         to\n                         2:00 pm\n                      "
  },
  {
    "title": "300 Pine",
    "location": "300 Pine, San Francisco, CA 94104",
    "date": "\n                                                  TODAY\n                                                  Mon\n                          11/27\n                      ",
    "time": "\n                        11:00 am\n                         to\n                         2:00 pm\n                      "
  },
  {
    "title": "10th & Market",
    "location": "8 10th St, San Francisco, CA 94103",
    "date": "\n                                                  TODAY\n                                                  Mon\n                          11/27\n                      ",
    "time": "\n                        11:00 am\n                         to\n                         2:00 pm\n                      "
  },
  {
    "title": "San Francisco State University (Hensil Hall)",
    "location": "1600 Holloway, San Francisco, CA 94132",
    "date": "\n                                                  Tue\n                          11/28\n                      ",
    "time": "\n                        11:00 am\n                         to\n                         2:30 pm\n                      "
  },
  {
    "title": "2nd & Minna",
    "location": "120 2nd St, San Francisco, CA 94105",
    "date": "\n                                                  Tue\n                          11/28\n                      ",
    "time": "\n                        11:00 am\n                         to\n                         2:00 pm\n                      "
  },
  {
    "title": "300 Pine",
    "location": "300 Pine, San Francisco, CA 94104",
    "date": "\n                                                  Tue\n                          11/28\n                      ",
    "time": "\n                        11:00 am\n                         to\n                         2:00 pm\n                      "
  },
  {
    "title": "Broadway & Front",
    "location": "90 Broadway, San Francisco, CA 94111",
    "date": "\n                                                  Tue\n                          11/28\n                      ",
    "time": "\n                        11:00 am\n                         to\n                         2:00 pm\n                      "
  },
  {
    "title": "Off The Grid \"Serramonte\"",
    "location": "Hwy 280 & Serramonte Blvd, Daly City, CA 94015",
    "date": "\n                                                  Tue\n                          11/28\n                      ",
    "time": "\n                        5:00 pm\n                         to\n                         8:00 pm\n                      "
  },
  {
    "title": "2nd & Minna",
    "location": "120 2nd St, San Francisco, CA 94105",
    "date": "\n                                                  Wed\n                          11/29\n                      ",
    "time": "\n                        11:00 am\n                         to\n                         2:00 pm\n                      "
  },
  {
    "title": "300 Pine",
    "location": "300 Pine, San Francisco, CA 94104",
    "date": "\n                                                  Wed\n                          11/29\n                      ",
    "time": "\n                        11:00 am\n                         to\n                         2:00 pm\n                      "
  },
  {
    "title": "10th & Market",
    "location": "8 10th St, San Francisco, CA 94103",
    "date": "\n                                                  Wed\n                          11/29\n                      ",
    "time": "\n                        11:00 am\n                         to\n                         2:00 pm\n                      "
  },
  {
    "title": "Off the Grid \"5M\"",
    "location": "5th and Minna, San Francisco, CA 94105",
    "date": "\n                                                  Wed\n                          11/29\n                      ",
    "time": "\n                        11:00 am\n                         to\n                         2:00 pm\n                      "
  },
  {
    "title": "Kaiser Center ",
    "location": "300 Lakeside Drive, Oakland, CA 94612",
    "date": "\n                                                  Wed\n                          11/29\n                      ",
    "time": "\n                        11:00 am\n                         to\n                         2:00 pm\n                      "
  },
  {
    "title": "Spark Social SF",
    "location": "601 Mission Bay Blvd. North, San Francisco, CA 94158",
    "date": "\n                                                  Thu\n                          11/30\n                      ",
    "time": "\n                        11:00 am\n                         to\n                         3:00 pm\n                      "
  },
  {
    "title": "2nd & Minna",
    "location": "120 2nd St, San Francisco, CA 94105",
    "date": "\n                                                  Thu\n                          11/30\n                      ",
    "time": "\n                        11:00 am\n                         to\n                         2:00 pm\n                      "
  },
  {
    "title": "300 Pine",
    "location": "300 Pine, San Francisco, CA 94104",
    "date": "\n                                                  Thu\n                          11/30\n                      ",
    "time": "\n                        11:00 am\n                         to\n                         2:00 pm\n                      "
  },
  {
    "title": "5th & Mission",
    "location": "901 Mission St, San Francisco, CA 94103",
    "date": "\n                                                  Thu\n                          11/30\n                      ",
    "time": "\n                        11:00 am\n                         to\n                         2:00 pm\n                      "
  },
  {
    "title": "Off The Grid \"Haight\"",
    "location": "Stanyan St. and Waller St., San Francisco, CA 94117",
    "date": "\n                                                  Thu\n                          11/30\n                      ",
    "time": "\n                        5:00 pm\n                         to\n                         8:00 pm\n                      "
  },
  {
    "title": "2nd & Minna",
    "location": "120 2nd St, San Francisco, CA 94105",
    "date": "\n                                                  Fri\n                          12/01\n                      ",
    "time": "\n                        11:00 am\n                         to\n                         2:00 pm\n                      "
  },
  {
    "title": "Off the Grid \"Civic Center\"",
    "location": "Civic Center/City Hall, San Francisco, CA 94102",
    "date": "\n                                                  Fri\n                          12/01\n                      ",
    "time": "\n                        11:00 am\n                         to\n                         2:00 pm\n                      "
  },
  {
    "title": "300 Pine",
    "location": "300 Pine, San Francisco, CA 94104",
    "date": "\n                                                  Fri\n                          12/01\n                      ",
    "time": "\n                        11:00 am\n                         to\n                         2:00 pm\n                      "
  },
  {
    "title": "10th & Market",
    "location": "8 10th St, San Francisco, CA 94103",
    "date": "\n                                                  Fri\n                          12/01\n                      ",
    "time": "\n                        11:00 am\n                         to\n                         2:00 pm\n                      "
  },
  {
    "title": "Off The Grid \"Stockton Street Winter Walk\"",
    "location": "120 Stockton St., San Francisco, CA 94102",
    "date": "\n                                                  Fri\n                          12/01\n                      ",
    "time": "\n                        11:00 am\n                         to\n                         9:00 pm\n                      "
  },
  {
    "title": "Off The Grid \"Lake Merritt\"",
    "location": "1000 Oak St., Oakland, CA 94607",
    "date": "\n                                                  Fri\n                          12/01\n                      ",
    "time": "\n                        5:00 pm\n                         to\n                         9:00 pm\n                      "
  },
  {
    "title": "Powell & Ellis",
    "location": "120 Ellis St, San Francisco, CA 94102",
    "date": "\n                                                  Sat\n                          12/02\n                      ",
    "time": "\n                        11:00 am\n                         to\n                         5:00 pm\n                      "
  },
  {
    "title": "Off The Grid \"Alameda\"",
    "location": "2310 S Shore Center, Alameda, CA  94501",
    "date": "\n                                                  Sat\n                          12/02\n                      ",
    "time": "\n                        11:00 am\n                         to\n                         3:00 pm\n                      "
  },
  {
    "title": "Off The Grid \"Stockton Street Winter Walk\"",
    "location": "120 Stockton St., San Francisco, CA 94102",
    "date": "\n                                                  Sat\n                          12/02\n                      ",
    "time": "\n                        11:00 am\n                         to\n                         9:00 pm\n                      "
  },
  {
    "title": "701 Valencia ",
    "location": "701 Valencia St., San Francisco, California 94110",
    "date": "\n                                                  Sat\n                          12/02\n                      ",
    "time": "\n                        11:00 am\n                         to\n                         5:00 pm\n                      "
  },
  {
    "title": "Powell & Ellis",
    "location": "120 Ellis St, San Francisco, CA 94102",
    "date": "\n                                                  Sun\n                          12/03\n                      ",
    "time": "\n                        11:00 am\n                         to\n                         5:00 pm\n                      "
  },
  {
    "title": "701 Valencia",
    "location": "701 Valencia St., San Francisco, California 94110",
    "date": "\n                                                  Sun\n                          12/03\n                      ",
    "time": "\n                        11:00 am\n                         to\n                         5:00 pm\n                      "
  },
  {
    "title": "Off The Grid \"Stockton Street Winter Walk\"",
    "location": "120 Stockton St., San Francisco, CA 94102",
    "date": "\n                                                  Sun\n                          12/03\n                      ",
    "time": "\n                        4:00 pm\n                         to\n                         8:30 pm\n                      "
  }
]

const NEWLINE = `\n`
const SPACE = ` `

const cleanProperties = map(
  ([k, v]) => ([
    k,
    pipe(
      split(NEWLINE),
      map(trim),
      join(SPACE),
      trim
    )(v)
  ]
))

const convertToDate = (x) => new Date(`${x}/${(new Date()).getFullYear()}`)

const substrUnary = curry((x, y) => y.substr(x))
const subTrimDate = curry((x, v) => pipe(
  substrUnary(x),
  trim,
  convertToDate
)(v))

const onlyWhen = curry((condition, fn, x) => {
  if (condition(x)) {
    return fn(x)
  }
  return x
})

const keyIsDate = ([k]) => k === `date`
const keyIsTime = ([k]) => k === `time`

// const cleanTodayDate = map(
//   ([k, v]) => {
//     if (k === `date`) {
//       if (hasString(`today`, v)) {
//         // return [k, datify(v.substr(5).trim())]
//         return [k, subTrimDate(5, v)]
//       }
//       return [k, subTrimDate(3, v)]
//     }
//     return [k, v]
//   }
// )
// const cleanTodayDate = map(
//   onlyWhen(keyIsDate, ([k, v]) => {
//     if (hasString(`today`, v)) {
//       // return [k, datify(v.substr(5).trim())]
//       return [k, subTrimDate(5, v)]
//     }
//     return [k, subTrimDate(3, v)]
//   })
// )

const trimDate = triplet(hasString(`today`), subTrimDate(5), subTrimDate(3))
const cleanTodayDate = map(
  onlyWhen(
    keyIsDate,
    alterLastIndex(trimDate)
  )
)

const convertTimeIntoParts = map(
  onlyWhen(
    keyIsTime,
    ([k, v]) => {
      const [start, end] = v.split(` to `)
      return [k, {start, end}]
    }
  )
)

const militarize = (x) => {
  const [time, median] = x.split(` `)
  const [_hours, minutes] = time.split(`:`)
  const hours = parseInt(_hours)
  if (median === `pm` && hours < 10) {
    return `${hours + 10}:${minutes}`
  }
  return `${hours}:${minutes}`
}

const keyIsTimeAndStartAndEndExist = pipe(
  ([k, v]) => k === `time` && v.start && v.end
)

// const twentyFourHourClock = map(
//   ([k, v]) => {
//     if (k === `time` && v.start && v.end) {
//       return [k, map(militarize, v)]
//     }
//     return [k, v]
//   }
// )
const twentyFourHourClock = map(
  onlyWhen(
    keyIsTimeAndStartAndEndExist,
    alterLastIndex(map(militarize))
  )
)

const alterRight = curry((fn, [k, v]) => fn(v))
const alterLeft = curry((fn, [k, v]) => fn(k))
const valuesWith = (x) => alterRight(hasString(x))
const rejectThingsWith = (x) => reject(valuesWith(x))

const hasKeys = pipe(
  length,
  gt(0),
  Boolean
)

const addHumanDate = onlyWhen(
  prop(`date`),
  (x) => {
    x.humanDate = x.date
    return x
  }
)

const clean = pipe(
  map(
    pipe(
      addHumanDate,
      toPairs,
      // reject(([k, v]) => hasString(`sorry`, v)),
      // reject(alterRight(hasString(`sorry`))),
      // reject(valuesWith(`sorry`)),
      rejectThingsWith(`sorry`),
      cleanProperties,
      cleanTodayDate,
      convertTimeIntoParts,
      twentyFourHourClock,
      fromPairs
    )
  ),
  filter(hasKeys)
)

console.log(`uhhhh`, clean(raw))
