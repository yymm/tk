# -*- encoding:utf-8 -*-

import datetime
import redis
from gitlab_api import *

'''タスク管理の根幹部分
'''

redis_url = 'redis://localhost:6379'
redis_url_env = ""
if "REDISTOGO_URL" in os.environ:
    redis_url = os.environ["REDISTOGO_URL"]
    redis_url_env = "REDISTOGO_URL"
elif "REDISCLOUD_URL" in os.environ:
    redis_url = os.environ["REDISCLOUD_URL"]
    redis_url_env = "REDISCLOUD_URL"
elif "BOXEN_REDIS_URL" in os.environ:
    redis_url = os.environ["BOXEN_REDIS_URL"]
    redis_url_env = "BOXEN_REDIS_URL"
elif "REDIS_URL" in os.environ:
    redis_url = os.environ["REDIS_URL"]
    redis_url_env = "REDIS_URL"

con = redis.Redis(host=redis_url.split(":")[1][2:], # TODO: validation
                  port=redis_url.split(":")[2], # TODO: validation
                  db=0)

#
# Redisデータベース構成
#
# key: "task"
#
# field: "today"
# - List<Dictionary>
#   - name   : String
#   - id     : Int
#   - status : Bool
# field: "log"
# - Dictionary
#   - key: datetime(yyyy/mm/dd)
#     - List<Dictionary>
#       - name   : String
#       - id     : Int
#       - status : Bool
#

class Task:
    def __init__(self, name):
        self.name = name
        self.__id = self.get_id()
        self.__status = False

    def dictionary():
        return { "name": self.name, "id": self.__id, "status": self.__status }

def get_remaining_tasks():
    if con.exist("today"):
        pass
    pass

def get_today_tasks():
    pass

def get_result():
    pass

def add_task(name):
    pass

def delete_task(name_or_id):
    pass
