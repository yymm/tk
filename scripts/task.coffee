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
call_api = (api, res, callback) ->
  request
    .get( "#{url}#{api}" )
    .end( (err, resp) ->
      if err || !resp.ok
        res.reply "何やらサーバがダメみたい\n[Error]\n#{err}\n[Response]\n#{resp}"
        return
      callback(res)


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

  robot.hear /仕事/i, (res) ->
    res.reply "今日の仕事一覧だよー"
    # WebAPI: 今日のタスクを取得

  robot.respond /task add (.*)/, (res) ->
    task_title = res.match[1]
    res.reply task_title
    # WebAPI: タスクの追加

  robot.respond /task delete (.*)/, (res) ->
    task = res.match[1]
    res.reply task
    # WebAPI: タスクの削除
