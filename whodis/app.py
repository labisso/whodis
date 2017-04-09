from flask import Flask, request
app = Flask(__name__)


@app.route('/')
def root():
    return 'hello %s' % (request.remote_addr,)
