# -*- encoding:utf-8 -*-

import ast
import datetime
from gitlabapi import GitLabAPI
from redishandler import RedisHandler

'''タスク管理
- GitLabのIssue
- Redisに保存されたデータ
'''

class Task(RedisHandler):
    '''Redisデータベース構成
    key: "task"
    
    field: id<Int>
    value: { name<String>, status<Bool> }
    '''
    def __init__(self):
        super(Task, self).__init__("task")
        self.gitlab = GitLabAPI()

    def today(self):
        message = "```\n"
        message += self.get_gitlab_issues()
        tasks = self.get_all()
        if len(tasks.keys()) != 0: message += "\n"
        for key in sorted(tasks.keys()):
            value = self.__decode_dict( tasks[key] )
            status = "x" if value["status"] else " "
            message += "\n[%s] (%d) %s" % (status, int(key), value["name"])
        return message + "\n```"

    def remaining_and_clean(self):
        # clean
        tasks = self.get_all()
        del_keys = []
        for key in tasks.keys():
            value = self.__decode_dict( tasks[key] )
            if value["status"]:
                self.delete(int(key))
                del_keys.append(key)
        for key in del_keys: del tasks[key]
        # remaining
        if len(tasks) == 0: return ""
        message = "```"
        for key in sorted(tasks.keys()):
            # value = self.__decode_dict( tasks[key] )
            message += "\n[ ] (%d) %s" % (int(key), value["name"])
        return message + "\n```"

    def get(self, id):
        return self.__decode_dict( self.get_value(id) )
    
    def add(self, name):
        return self.set_value({ "name": name, "status": False })
    
    def delete(self, id):
        return self.delete_field(id)

    def update(self, id):
        task = self.get(id)
        task["status"] = not task["status"]
        return self.update_value(id, task)

    def __decode_dict(self, byte):
        # TODO: utf-8じゃない文字列が入力された場合ダメな気がする
        return ast.literal_eval( byte.decode("utf-8") )

    def get_gitlab_issues(self):
        message = ""
        projects = ["mos"]

        def get_opened_issues(project_name):
            message = ""
            pid = self.gitlab.get_project_id("mos")
            if not pid:
                return None
            json = self.gitlab.issues(pid,
                    {"state": "opened", "labels": "Priority1"})
            for d in json:
                message += "\n[#%d] %s" % (d["iid"], d["title"])
            return message

        for project in projects:
            message += "> %s [GitLab]" % project
            message += get_opened_issues(project)

        return message
