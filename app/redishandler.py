# -*- encoding:utf-8 -*-

import os
import redis

class RedisHandler(object):
    '''IDをfieldにしたRedisDBクラス
    継承を前提にして作成されています。
    '''
    def __init__(self, key):
        self.key = key
        self.redis_url = 'redis://localhost:6379' # default: local
        self.redis_url_env = ""
        if "REDISTOGO_URL" in os.environ:
            self.redis_url = os.environ["REDISTOGO_URL"]
            self.redis_url_env = "REDISTOGO_URL"
        elif "REDISCLOUD_URL" in os.environ:
            self.redis_url = os.environ["REDISCLOUD_URL"]
            self.redis_url_env = "REDISCLOUD_URL"
        elif "BOXEN_REDIS_URL" in os.environ:
            self.redis_url = os.environ["BOXEN_REDIS_URL"]
            self.redis_url_env = "BOXEN_REDIS_URL"
        elif "REDIS_URL" in os.environ:
            self.redis_url = os.environ["REDIS_URL"]
            self.redis_url_env = "REDIS_URL"
        self.con = redis.Redis(host=self.redis_url.split(":")[1][2:], # TODO: validation
                          port=self.redis_url.split(":")[2], # TODO: validation
                          db=1)

    def set_value(self, value):
        id = self.__get_id()
        self.con.hset(self.key, id, value)
        return {"id": id, "value": value}

    def update_value(self, id, value):
        return self.con.hset(self.key, id, value)

    def get_value(self, field):
        return self.con.hget(self.key, field)

    def delete_field(self, field):
        return self.con.hdel(self.key, field)

    def __get_id(self):
        if self.con.hlen(self.key) == 0:
            return 0
        keys = self.con.hkeys(self.key)
        keys = [int(x) for x in keys]
        return sorted(keys)[-1] + 1

    def get_all(self):
        return self.con.hgetall(self.key)
