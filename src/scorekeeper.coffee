# Description:
#   Helper class responsible for storing scores
#
# Dependencies:
#
# Configuration:
#
# Commands:
#
# Author:
#   ajacksified
class ScoreKeeper
  constructor: (@robot) ->
    storageLoaded = =>
      @storage = @robot.brain.data.plusPlus ||= {
        scores: {}
        log: {}
        reasons: {}
        last: {}
      }
      if typeof @storage.last == "string"
        @storage.last = {}

      @robot.logger.debug "Plus Plus Data Loaded: " + JSON.stringify(@storage, null, 2)
    @robot.brain.on "loaded", storageLoaded
    storageLoaded() # just in case storage was loaded before we got here


  getUser: (room, user) ->
    @storage.scores[room] ||= {}
    @storage.reasons[room] ||= {}
    @storage.scores[room][user] ||= 0
    @storage.reasons[room][user] ||= {}
    user

  saveUser: (user, from, room, reason) ->
    @saveScoreLog(user, from, room, reason)
    @robot.brain.save()

    [@storage.scores[room][user], @storage.reasons[room][user][reason] || "none"]

  add: (user, from, room, reason) ->
    if @validate(user, from)
      user = @getUser(room, user)
      @storage.scores[room][user]++
#      @storage.reasons[user] ||= {}

      if reason
        @storage.reasons[room][user][reason] ||= 0
        @storage.reasons[room][user][reason]++

      @saveUser(user, from, room, reason)
    else
      [null, null]

  subtract: (user, from, room, reason) ->
    if @validate(user, from)
      user = @getUser(room, user)
      @storage.scores[room][user]--
#      @storage.reasons[user] ||= {}

      if reason
        @storage.reasons[room][user][reason] ||= 0
        @storage.reasons[room][user][reason]--

      @saveUser(user, from, room, reason)
    else
      [null, null]

  erase: (user, from, room, reason) ->
    user = @getUser(room, user)

    if reason
      delete @storage.reasons[room][user][reason]
      return true
    else
      delete @storage.scores[room][user]
      delete @storage.reasons[room][user]
      return true

    @saveUser(user, from, room, reason)
    false

  scoreForUser: (room, user) ->
    user = @getUser(room, user)
    @storage.scores[room][user]

  reasonsForUser: (room, user) ->
    user = @getUser(room, user)
    @storage.reasons[room][user]

  saveScoreLog: (user, from, room, reason) ->
    unless typeof @storage.log[from] == "object"
      @storage.log[from] = {}

    @storage.log[from][user] = new Date()
    @storage.last[room] = {user: user, reason: reason}

  last: (room) ->
    last = @storage.last[room]
    if typeof last == 'string'
      [last, '']
    else
      [last.user, last.reason]

  isSpam: (user, from) ->
    @storage.log[from] ||= {}

    if !@storage.log[from][user]
      return false

    dateSubmitted = @storage.log[from][user]

    date = new Date(dateSubmitted)
    messageIsSpam = date.setSeconds(date.getSeconds() + 5) > new Date()

    if !messageIsSpam
      delete @storage.log[from][user] #clean it up

    messageIsSpam

  validate: (user, from) ->
    user != from && user != "" && !@isSpam(user, from)

  length: () ->
    @storage.log.length

  top: (room, amount) ->
    tops = []

    for name, score of @storage.scores[room]
      tops.push(name: name, score: score)

    tops.sort((a,b) -> b.score - a.score).slice(0,amount)

  bottom: (amount) ->
    all = @top(@storage.scores.length)
    all.sort((a,b) -> b.score - a.score).reverse().slice(0,amount)

#  normalize: (fn) ->
#    scores = {}
#
#    _.each(@storage.scores, (score, name) ->
#      scores[name] = fn(score)
#      delete scores[name] if scores[name] == 0
#    )
#
#    @storage.scores = scores
#    @robot.brain.save()

module.exports = ScoreKeeper
