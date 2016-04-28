# Description:
#   タスク管理
#
# Notes:
#   定時のpush通知をメイン機能にする
#   respondはタスク進捗の更新、励まして
#   cronを使って上手いこと実現したい

request = require "superagent"
CronJob = require("cron").CronJob

# TODO: 環境変数から取得
url = "localhost:5000"
call_api = (api, query, res, callback) ->
  request
    .get( "#{url}#{api}" )
    .query( query )
    .end( (err, resp) ->
      if err || !resp.ok
        res.reply "何やらサーバがダメみたい\n[Error]\n#{err}\n[Response]\n#{resp}"
        return
      callback(res, resp)
    )

module.exports = (robot) ->
  # 定時タスク
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
    # WebAPI: 今日のタスクを取得
    call_api "/task/today", {}, res, (res, resp) ->
      res.send resp.body.message

  robot.respond /task add (.*)/i, (res) ->
    task_name = res.match[1]
    # WebAPI: タスクの追加
    query = {"name": task_name}
    call_api "/task/add", query, res, (res, resp) ->
      res.send "追加完了ー IDは#{resp.body.id}\n(#{resp.body.value.name})"

  robot.respond /task delete (\d+)/i, (res) ->
    id = res.match[1]
    # WebAPI: タスクの削除
    query = {"id", id}
    call_api "/task/delete", query, res, (res, resp) ->
      res.send "追加完了ー IDは#{resp.body.id}\n(#{resp.body.value.name})"

  robot.respond /進捗 (\d+)/i, (res) ->
    id = res.match[1]
    # WebAPI: タスクの更新
    query = {"id", id}
    call_api "/task/update", query, res, (res, resp) ->
      res.send "おつかれおつかれー"
