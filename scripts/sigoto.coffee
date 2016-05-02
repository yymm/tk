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
  gitlabApiUrl = if process.env.GITLAB_API_URL?
               gitlabApiUrlEnv = "GITLAB_API_URL"
               process.env.GITLAB_API_URL
             else
               "http://192.168.5.56/api/v3"
  gitlabToken = if process.env.GITLAB_TOKEN
              gitlabTokenEnv = "GITLAB_TOKEN"
              process.env.GITLAB_TOKEN
            else
              "Vrz8de3zCXK9N9oEdy8q"

  robot.respond /gitlab (.*) (.*)/i, (res) ->
    name = res.match[1]
    info = {label: res.match[2]}
    request
      .get( "#{gitlabApiUrl}/projects" )
      .query( {private_token: gitlabToken} )
      .end( (err, resp) ->
        if err || !resp.ok
          res.send "GitLab APIダメー\n> #{err}"
          return
        data = resp.body.map (d) -> d.name
        if name not in data
          res.send "ないよー"
          return
        data = resp.body.filter (d) -> d.name == name
        info.id = data[0].id
        con.hset "gitlab", name, JSON.stringify( info ), (err, rep) ->
          if err
            res.send "Redisがエラーどばぁ\n#{err}"
            return
          res.send "GitLabのプロジェクト追加ー\n> project_name: #{name}\n> project_id: #{info.id}\n> label: #{info.label}"
      )

  robot.respond /gitlab del (.*)/i, (res) ->
    name = res.match[1]
    con.hdel "gitlab", name, (err, rep) ->
      if err
        res.send "Redisがエラーどばぁ\n#{err}"
        return
      res.send "#{name}の設定消したよー"

  robot.respond /gitlab status/i, (res) ->
    con.hgetall "gitlab", (err, rep) ->
      if err
        res.send "Redisがエラーどばぁ\n#{err}"
        return
      if not rep or rep.length == 0
        res.send "まだGitLab使ってないよー"
        return
      message = "GitLabの登録状況ー\n```\n"
      for k, v of rep
        v = JSON.parse v
        message += "#{k} |  user: #{v.user}, label: #{v.label}\n"
      message += "```"
      res.send message

  robot.respond "gitlab issue", (res) ->
    get_gitlab_issues res

  get_gitlab_issues = (res) ->
    con.hgetall "gitlab", (err, rep) ->
      if err
        res.send "Redisがエラーどばぁ\n#{err}"
        return
      if not rep or rep.length == 0
        return
      promise_agent = (val) ->
        return new Promise (resolve) ->
          query = {private_token: gitlabToken, state: "opened", labels: val.label}
          request
            .get( "#{gitlabApiUrl}/projects/#{val.id}/issues" )
            .query(  )
            .end( (err, resp) ->
              if err || !resp.ok
                return
              else
                resolve(resp.body)
            )
      l = []
      for k, v of rep
        l.push JSON.parse v
      Promise.all l.map promise_agent
        .then (results) ->
          # ここにコールバックを入れる感じ
          console.log results
          return
        .catch (error) ->
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

  #
  # Task
  #
  robot.hear /仕事/, (res) ->
    con.hgetall "task", (err, rep) ->
      if err
        res.send "Redisがエラーどばぁ\n#{err}"
        return
      if not rep
        return
      message = "今日の仕事だよー\n```\n"
      for key, val of rep
        val = JSON.parse val
        status = if val.status then "x" else " "
        message += "[#{status}] #{key}: #{val.name}\n"
      message += "```"
      res.send message

  robot.respond /task add (.*)/i, (res) ->
    name = res.match[1]
    con.hkeys "task", (err, rep) ->
      if err
        res.send "Redisがエラーどばぁ\n#{err}"
        return
      id = 0
      if not rep of rep.length != 0
        id = rep.length
      con.hset "task", id, JSON.stringify({name: name, status: false}), (err, rep) ->
        if err
          res.send "Redisがエラーどばぁ\n#{err}"
          return
        res.send "追加したよー IDは#{id}だよー"

  robot.respond /task del (\d+)/i, (res) ->
    id = res.match[1]
    con.hdel "task", id, (err, rep) ->
      if err
        res.send "Redisがエラーどばぁ\n#{err}"
        return
      res.send "#{id}番目はいらない子..."

  robot.respond /done (\d+)/i, (res) ->
    id = res.match[1]
    con.hget "task", id, (err, rep) ->
      if err
        res.send "Redisがエラーどばぁ\n#{err}"
        return
      val = JSON.parse rep
      val.status = if val.status then false else true
      con.hset "task", id, JSON.stringify(val), (err, rep) ->
        if err
          res.send "Redisがエラーどばぁ\n#{err}"
          return
        res.send "> #{id}: #{val.name}\n完了ーおつかれおつかれー"
