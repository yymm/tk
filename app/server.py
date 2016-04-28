# -*- encoding:utf-8 -*-

from task import Task
from flask import Flask, jsonify, request

'''タスク管理のメインインターフェイス
'''

app = Flask(__name__)
task = Task()

@app.route("/task/today", methods=["GET"])
def task_today():
    return jsonify( {"message": task.today()} )

@app.route("/task/remaining", methods=["GET"])
def task_remaining():
    return jsonify( {"message": task.remaining_and_clean()} )

@app.route("/task/update", methods=["GET"])
def task_update():
    return jsonify( task.update( request.args.get("id") ) )

@app.route("/task/add", methods=["GET"])
def task_add():
    return jsonify( task.add( request.args.get("name") ) )

@app.route("/task/delete", methods=["GET"])
def task_delete():
    return jsonify( task.delete( request.args.get("id") ) )

if __name__ == "__main__":
    app.debug = True
    app.run(host="0.0.0.0")
