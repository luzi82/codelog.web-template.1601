import datetime
import flask
import werkzeug.middleware.proxy_fix

app = flask.Flask(__name__)
app.wsgi_app = werkzeug.middleware.proxy_fix.ProxyFix(app.wsgi_app)

@app.route('/')
def index():
    print(flask.request.headers)
    now = datetime.datetime.now()
    flask_request_host_url = flask.request.host_url
    return flask.render_template(
        'index.html.tmpl',
        now = now,
        flask_request_host_url = flask_request_host_url,
    )

@app.route('/testme')
def testme():
  return 'testme'
