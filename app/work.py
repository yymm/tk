# -*- encoding:utf-8 -*-

import datetime
import redis
from gitlab_api import *

'''やりたいこと管理の根幹部分
'''

class Work:
    def __init__(self, name, deadline=None):
        self.name = name
        self.__id = self.get_id()
        self.__progress = 0
        self.__deadline = deadline

