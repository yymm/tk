# Description:
#   sigoto
#
# Notes:
#   They are commented out by default, because most of them are pretty silly and
#   wouldn't be useful and amusing enough for day to day huboting.
#   Uncomment the ones you want to try and experiment with.
#
#   These are from the scripting documentation: https://github.com/github/hubot/blob/master/docs/scripting.md

request = require "superagent"
CronJob = require("cron").CronJob
Redis = require "redis"
Url = require "url"

module.exports = (robot) ->
  #
  # Redis
  #
  redisUrl = if process.env.REDISTOGO_URL?
               redisUrlEnv = "REDISTOGO_URL"
               process.env.REDISTOGO_URL
             else if process.env.REDISCLOUD_URL?
               redisUrlEnv = "REDISCLOUD_URL"
               process.env.REDISCLOUD_URL
             else if process.env.BOXEN_REDIS_URL?
               redisUrlEnv = "BOXEN_REDIS_URL"
               process.env.BOXEN_REDIS_URL
             else if process.env.REDIS_URL?
               redisUrlEnv = "REDIS_URL"
               process.env.REDIS_URL
             else
               'redis://localhost:6379'

  info   = Url.parse redisUrl, true
  con = if info.auth then Redis.createClient(info.port, info.hostname, {no_ready_check: true}) else Redis.createClient(info.port, info.hostname)

  #
  # GitLab Issue
  #

  #
  # Task
  #
  today_task = ->
    return

  add_task = (name) ->
    id = 0
    keys = con.hkeys "task"
    console.log keys
    #con.hset "task",
    return {name: name, id: id}

  delete_task = (id) ->
    return

  update_task = (id) ->
    return

  clean_task = ->
    return

  #
  # 定時タスク
  #
  morning = null
  report  = null
  evening = null

  robot.respond /task start/i, (res) ->
    if not morning
      morning = new CronJob "00 14 08 * * 1-5", -> # 平日の9:30
        # WebAPI: 昨日の残タスクを取得
        date = new Date()
        res.send "今日すること何ー？ #{date.getSeconds()}"
      , null, false, "Asia/Tokyo"

    if not report
      report = new CronJob "00 29 09 * * 1-5", -> # 平日の10:30
        # WebAPI: 今日のタスクを取得
        date = new Date()
        res.send "今日することはこれ!  #{date.getSeconds()}"
      , null, false, "Asia/Tokyo"

    if not evening
      evening = new CronJob "00 14 16 * * 1-5", -> # 平日の17:15
        # WebAPI: 今日の結果取得
        date = new Date()
        res.send "今日のけっか #{date.getSeconds()}"
      , null, false, "Asia/Tokyo"
    morning.start()
    report.start()
    evening.start()
    res.reply "働けー"

  robot.respond /task stop/i, (res) ->
    if morning
      morning.stop()
    if report
      report.stop()
    if evening
      evening.stop()
    res.reply "やすむーおやすみー"

  robot.hear /仕事/, (res) ->
    res.send "今日の仕事だよー"
    res.send today_task()

  robot.respond /task add (.*)/i, (res) ->
    task = add_task res.match[1]
    res.send "追加したよー IDは#{task.id}だよー"

  robot.respond /task delete (\d+)/i, (res) ->
    task = delete_task res.match[1]
    res.send "#{task.id}番目はいらない子だったんや..."

  robot.respond /done (\d+)/i, (res) ->
    task = update_task res.match[1]
    res.send "完了ーおつかれおつかれー (#{task.name} )"

