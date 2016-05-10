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

  robot.respond /gitlab add (.*) (.*)/i, (res) ->
    name = res.match[1]
    info = if res.match[2] != "null" then {label: res.match[2]} else {label: null}
    # プロジェクト名の確認
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
        # Redisにgitlab情報を登録
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
      if rep == 0
        res.send "ないよー"
      else
        res.send "#{name}の設定消したよー"

  robot.respond /gitlab ls/i, (res) ->
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

  robot.respond /gitlab issue/i, (res) ->
    get_gitlab_issues res

  get_gitlab_issues = (res, msg=null) ->
    # Redisからgitlab情報を取得
    con.hgetall "gitlab", (err, rep) ->
      if err
        res.send "Redisがエラーどばぁ\n#{err}"
        return
      if not rep or rep.length == 0
        if msg
          res.send "今日の仕事だよー\n```\n#{msg}```"
        return
      # 複数回APIを非同期でコールするのでPromiseで並列実行する
      promise_agent = (val) ->
        new Promise (resolve, reject) ->
          if val.label
            query = {private_token: gitlabToken, state: "opened", labels: val.label}
          else
            query = {private_token: gitlabToken, state: "opened"}
          request
            .get( "#{gitlabApiUrl}/projects/#{val.id}/issues" )
            .query( query )
            .end( (err, resp) ->
              if err || !resp.ok
                reject(err)
              else
                resolve(resp.body)
            )
      # Promiseオブジェクトのリストを作成
      l = []
      for k, v of rep
        d = JSON.parse v
        d.name = k
        l.push d
      pl = l.map(promise_agent)
      # Promiseでgitlab issueを取得
      Promise.all(pl)
        .then( (results) ->
          message = ""
          for data, i in results
            message += "[#{l[i].name}]\n"
            for d in data
              message += "##{d.iid}: #{d.title}\n"
          #res.send message
          if msg
            res.send "```\n> GitLab\n#{message}\n> Today\n#{msg}```"
          else
            res.send "\n```\n> GitLab\n#{message}```"
          return
        )
        .catch( (error) ->
          res.send "GitLab APIのエラーどばあぁ\n#{error}"
          return
        )

  #
  # 定時タスク
  #
  morning = null
  report  = null
  evening = null

  robot.respond /task on/i, (res) ->
    if not morning
      morning = new CronJob "00 30 09 * * 1-5", -> # 平日の9:30
        res.send "今日すること何ー？"
        # 終了しているTaskを削除, 残っているTaskを整理
        con.hgetall "task", (err, rep) ->
          if err
            res.send "Redisがエラーどばぁ\n#{err}"
            return
          if not rep
            return
          l = []
          for key, val of rep
            val = JSON.parse val
            if not val.status
              l.push val
            con.hdel "task", key, (err, rep) ->
              if err
                res.send "Redisがエラーどばぁ\n#{err}"
                return
          for val, i in l
            console.log val, i
            con.hset "task", i, JSON.stringify(val), (err, rep) ->
              if err
                res.send "Redisがエラーどばぁ\n#{err}"
                return
      , null, false, "Asia/Tokyo"

    if not report
      report = new CronJob "00 30 10 * * 1-5", -> # 平日の10:30
        res.send "今日することはこれ!"
        get_task res
      , null, false, "Asia/Tokyo"

    if not evening
      evening = new CronJob "00 15 17 * * 1-5", -> # 平日の17:15
        res.send "今日のけっかー"
        get_task res
      , null, false, "Asia/Tokyo"
    morning.start()
    report.start()
    evening.start()
    res.send "通知するよー"

  robot.respond /task off/i, (res) ->
    if morning
      morning.stop()
    if report
      report.stop()
    if evening
      evening.stop()
    res.send "やすむーおやすみー"

  #
  # Task
  #
  get_task = (res) ->
    con.hgetall "task", (err, rep) ->
      if err
        res.send "Redisがエラーどばぁ\n#{err}"
        return
      if not rep
        get_gitlab_issues res
        return
      message = ""
      for key, val of rep
        val = JSON.parse val
        status = if val.status then "x" else " "
        message += "[#{status}] #{key}: #{val.name}\n"
      get_gitlab_issues res, message

  robot.hear /仕事/, (res) ->
     res.send "今日の仕事だよー"
     get_task res

  robot.respond /task add (.*)/i, (res) ->
    name = res.match[1]
    con.hkeys "task", (err, rep) ->
      if err
        res.send "Redisがエラーどばぁ\n#{err}"
        return
      id = 0
      if not rep or rep.length != 0
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
      if rep == 0
        res.send "知らないIDだよー"
      else
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

  #
  # Work
  #
  robot.respond /work add (.*) (\d{4}\/\d{2}\/\d{2})?/i, (res) ->
    name = res.match[1]
    date = res.match[2]
    con.hkeys "work", (err, rep) ->
      if err
        res.send "Redisがエラーどばぁ\n#{err}"
        return
      id = 0
      if not rep or rep.length != 0
        max = Math.max rep
        id = max + 1
      con.hset "work", id, JSON.stringify({name: name, status: false, date: date}), (err, rep) ->
        if err
          res.send "Redisがエラーどばぁ\n#{err}"
          return
        res.send "追加したよー IDは#{id}だよー"

  robot.respond /work add ((?!.*\/).*)/i, (res) ->
    name = res.match[1]
    con.hkeys "work", (err, rep) ->
      if err
        res.send "Redisがエラーどばぁ\n#{err}"
        return
      id = 0
      if not rep or rep.length != 0
        rep = rep.map (i) -> Number(i)
        max = Math.max.apply null, rep
        id = max + 1
      con.hset "work", id, JSON.stringify({name: name, status: false}), (err, rep) ->
        if err
          res.send "Redisがエラーどばぁ\n#{err}"
          return
        res.send "追加したよー IDは#{id}だよー"

  robot.respond /work del (.*)/i, (res) ->
    id = res.match[1]
    con.hdel "work", id, (err, rep) ->
      if err
        res.send "Redisがエラーどばぁ\n#{err}"
        return
      if rep == 0
        res.send "知らないIDだよー"
      else
        res.send "##{id}を消したよー"

  robot.respond /work done (\d+)/i, (res) ->
    id = res.match[1]
    con.hget "work", id, (err, rep) ->
      if err
        res.send "Redisがエラーどばぁ\n#{err}"
        return
      val = JSON.parse rep
      val.status = if val.status then false else true
      con.hset "work", id, JSON.stringify(val), (err, rep) ->
        if err
          res.send "Redisがエラーどばぁ\n#{err}"
          return
        res.send "> #{id}: #{val.name}\n完了ーおつかれおつかれー"

  get_work = (res) ->
    con.hgetall "work", (err, rep) ->
      msg = ""
      dmsg= ""
      for k, v of rep
        v = JSON.parse v
        status = if v.status then "x" else " "
        if v.date
          dmsg += "##{k}: [#{status}] #{v.name} [#{v.date}]\n"
        else
          msg += "##{k}: [#{status}] #{v.name}\n"
      message = "```\n#{msg}\n期限付き\n#{dmsg}```"
      res.send message

  robot.respond /work ls/i, (res) ->
    get_work res
