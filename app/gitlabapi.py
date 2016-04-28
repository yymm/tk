# -*- encoding:utf-8 -*-

import requests
import redis
import json
import os

class GitLabAPI:
    '''GitLab API interface
    '''
    def __init__(self):
        self.gitlab_private_token = "Vrz8de3zCXK9N9oEdy8q" # TODO: 開発のみ
        self.gitlab_private_token_url = ""
        if "GITLAB_PRIVATE_TOKEN" in os.environ:
            self.ggitlab_private_token = os.environ["GITLAB_PRIVATE_TOKEN"]
            self.ggitlab_private_token_env = "GITLAB_PRIVATE_TOKEN"
        
        self.gitlab_api_url = "http://192.168.5.56/api/v3" # TODO: 開発のみ
        self.gitlab_api_url_env = ""
        if "GITLAB_API_URL" in os.environ:
            self.gitlab_api_url = os.environ["GITLAB_API_URL"]
            self.gitlab_api_url_env = "GITLAB_API_URL"
        
        self.token = {"private_token": self.gitlab_private_token}
        self.url = lambda api: self.gitlab_api_url + api
    
    def gitlab_api_request(self, api, params=dict()):
        params = dict( self.token, **params )
        r = requests.get( self.url(api), params=params )
        if r.status_code == requests.codes.ok:
            # err: r.text
            pass
        return r.json()
    
    def projects(self):
        return self.gitlab_api_request("/projects")
    
    def issues(self, project_id, params):
        return self.gitlab_api_request("/projects/%d/issues"%(project_id),
                params)
    
    def get_project_id(self, project_name):
        json = self.projects()
        match = [x for x in json if x["name"] == project_name]
        return match[0]["id"] if len(match) == 1 else None
