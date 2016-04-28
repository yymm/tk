# -*- encoding:utf-8 -*-

import redis

con = redis.Redis(db=1)

# key_name = "task"
# d = {"hoge": 10}

# 登録
# con.hmset(key_name, d)
# 上書き
# 別DB
# print("フィールド取得", con.hkeys(key_name))
# print("バリュー取得", con.hvals(key_name))
# print("フィールドとバリュー取得", con.hgetall(key_name))
con.flushall()
print("全redisキー取得", con.keys())
print(con.exists("tasks"))
