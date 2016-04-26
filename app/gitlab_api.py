# -*- encoding:utf-8 -*-

import requests
import redis
import json
import os

'''GitLab API interface
'''

gitlab_private_token = "Vrz8de3zCXK9N9oEdy8q" # TODO: 開発のみ
gitlab_private_token_url = ""
if "GITLAB_PRIVATE_TOKEN" in os.environ:
    gitlab_private_token = os.environ["GITLAB_PRIVATE_TOKEN"]
    gitlab_private_token_env = "GITLAB_PRIVATE_TOKEN"

gitlab_api_url = "http://192.168.5.56/api/v3" # TODO: 開発のみ
gitlab_api_url_env = ""
if "GITLAB_API_URL" in os.environ:
    gitlab_api_url = os.environ["GITLAB_API_URL"]
    gitlab_api_url_env = "GITLAB_API_URL"

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

token = {"private_token": gitlab_private_token}
url = lambda api: gitlab_api_url + api

def gitlab_api_request(api, callback):
    r = requests.get( url(api), params=token )
    if r.status_code == requests.codes.ok:
        # err: r.text
        pass
    return callback( r.json() )

def projects(callback):
    return gitlab_api_request("/projects", callback)

def issues(callback):
    return gitlab_api_request("/issues", callback)

def issues(project_id, callback):
    return gitlab_api_request("/projects/%d/issues"%(project_id), callback)

def get_project_id(project_name):
    def get_id(json):
        match = [x for x in json if x["name"] == project_name]
        return match[0] if len(match) == 1 else None
    return projects(get_id)

