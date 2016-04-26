# -*- encoding:utf-8 -*-

from gitlab_api import *
from flask import Flask, jsonify

'''タスク管理のメインインターフェイス
'''

app = Flask(__name__)

@app.route("/task/today", methods=["GET"])
def task_today():
    pass

@app.route("/task/remaining", methods=["GET"])
def task_remaining():
    pass

@app.route("/task/result", methods=["GET"])
def task_result():
    pass

@app.route("/task/add", methods=["GET"])
def task_add():
    pass

@app.route("/task/delete", methods=["GET"])
def task_delete():
    pass

if __name__ == "__main__":
    app.debug = True
    app.run(host="0.0.0.0")
