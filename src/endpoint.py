import boto3
import datetime
import flask
import futsu.json
import futsu.storage
import middleware
import os
import random
import werkzeug.middleware.proxy_fix

app = flask.Flask(__name__)
app.wsgi_app = middleware.WebTemplateMiddleWare(app.wsgi_app, app)
app.wsgi_app = werkzeug.middleware.proxy_fix.ProxyFix(app.wsgi_app)

STAGE = os.environ['STAGE']
CONF_PATH = os.environ['CONF_PATH']
PUBLIC_COMPUTE_URL_PREFIX   = os.environ['PUBLIC_COMPUTE_URL_PREFIX']
PUBLIC_STATIC_URL_PREFIX    = os.environ['PUBLIC_STATIC_URL_PREFIX']
PUBLIC_DEPLOYGEN_URL_PREFIX = os.environ['PUBLIC_DEPLOYGEN_URL_PREFIX']
PUBLIC_MUTABLE_URL_PREFIX   = os.environ['PUBLIC_MUTABLE_URL_PREFIX']
PUBLIC_TMP_URL_PREFIX       = os.environ['PUBLIC_TMP_URL_PREFIX']
PUBLIC_STATIC_PATH          = os.environ['PUBLIC_STATIC_PATH']
PUBLIC_MUTABLE_PATH         = os.environ['PUBLIC_MUTABLE_PATH']
PRIVATE_STATIC_PATH         = os.environ['PRIVATE_STATIC_PATH']
PRIVATE_MUTABLE_PATH        = os.environ['PRIVATE_MUTABLE_PATH']
DB_TABLE_NAME = os.environ['DB_TABLE_NAME']
DYNAMODB_ENDPOINT_URL = os.environ.get('DYNAMODB_ENDPOINT_URL',None)
DYNAMODB_REGION       = os.environ.get('DYNAMODB_REGION',None)

@app.route('/')
def index():
    now_ts = int(datetime.datetime.now().timestamp())

    private_dummy_path = futsu.storage.join(PRIVATE_STATIC_PATH,'private.txt')
    private_txt = futsu.storage.path_to_bytes(private_dummy_path).decode('utf-8')

    timestamp_path = futsu.storage.join(PRIVATE_MUTABLE_PATH,'timestamp')
    last_ts = futsu.storage.path_to_bytes(timestamp_path).decode('utf-8') if futsu.storage.is_blob_exist(timestamp_path) else -1
    futsu.storage.bytes_to_path(timestamp_path,f'{now_ts}'.encode('utf-8'))

    job0_timestamp_path = futsu.storage.join(PRIVATE_MUTABLE_PATH,'job0_timestamp')
    job0_ts = futsu.storage.path_to_bytes(job0_timestamp_path).decode('utf-8') if futsu.storage.is_blob_exist(job0_timestamp_path) else -1

    dynamodb = boto3.resource('dynamodb', endpoint_url=DYNAMODB_ENDPOINT_URL, region_name=DYNAMODB_REGION)
    table = dynamodb.Table(DB_TABLE_NAME)
    query_ret = table.query(
      KeyConditionExpression=boto3.dynamodb.conditions.Key('HashKey').eq('rand_txt'),
      Limit=1,
    )
    now_rand = str(random.randrange(100))
    last_rand = query_ret['Items'][0]['Valuee'] if len(query_ret['Items'])>0 else ''
    table.update_item(
      Key={'HashKey':'rand_txt','SortKey':0},
      UpdateExpression='SET Valuee = :v',
      ExpressionAttributeValues={':v':now_rand},
    )

    return flask.render_template('index.html.tmpl',
        STAGE=STAGE,
        PRIVATE_TXT=private_txt,
        LAST_TS=last_ts,
        NOW_TS=now_ts,
        JOB0_TS=job0_ts,
        LAST_RAND=last_rand,
        NOW_RAND=now_rand,
        PUBLIC_COMPUTE_URL_PREFIX=PUBLIC_COMPUTE_URL_PREFIX,
        PUBLIC_STATIC_URL_PREFIX=PUBLIC_STATIC_URL_PREFIX,
        PUBLIC_DEPLOYGEN_URL_PREFIX=PUBLIC_DEPLOYGEN_URL_PREFIX,
        PUBLIC_MUTABLE_URL_PREFIX=PUBLIC_MUTABLE_URL_PREFIX,
        PUBLIC_TMP_URL_PREFIX=PUBLIC_TMP_URL_PREFIX,
    )

@app.route('/compute_domain')
def get_compute_domain():
    conf_data = futsu.json.path_to_data(futsu.storage.join(CONF_PATH,'conf.json'))
    return conf_data['COMPUTE_DOMAIN']

@app.route('/testme')
def testme():
  return 'testme'

# To enable this func:
# serverless.yml > custom.vpcConfig.createNatGateway = 1
@app.route('/testweb')
def testweb():
  return futsu.storage.path_to_bytes('https://httpbin.org/get').decode('utf-8')
