'use strict';

const chalk = require('chalk');
const messagePrefix = 'S3 Delete Bucket: ';

class ServerlessCleanupS3DeleteBucket {
  constructor(serverless, options) {
    this.serverless = serverless;
    this.options = options;
    this.provider = this.serverless.getProvider('aws');

    this.commands = {
      s3DeleteBucket: {
        usage: 'Delete S3 bucket',
        lifecycleEvents: ['s3_delete_bucket'],
        options: {
          verbose: {
            usage: 'Increase verbosity',
            shortcut: 'v',
            type: 'boolean'
          }
        }
      },
    };

    this.hooks = {
      'deploy:cleanup': this.s3DeleteBucket.bind(this),
      's3DeleteBucket:s3_delete_bucket': this.s3DeleteBucket.bind(this),
    };
  }

  log(message) {
    if (this.options.verbose) {
      this.serverless.cli.log(message);
    }
  }
  
  isTrue(value) {
    if(!value)return false;
    if(value=='false')return false;
    if(value==false)return false;
    if(value=='0')return false;
    if(value==0)return false;
    if(value=='null')return false;
    if(value==null)return false;
    return true;
  }

  s3DeleteBucket() {
    const self = this;

    const getAwsStackExist = () => {
      const stackName = this.provider.naming.getStackName();
      self.log(`${messagePrefix}Check stack exist ${stackName}`)
      return self.provider.request('CloudFormation', 'describeStacks', { StackName: stackName })
        .then((result)=>{return Promise.resolve(true);})
        .catch(e=>{
          if (e.message.indexOf('does not exist') > -1) {
            return Promise.resolve(false);
          }
          throw e;
        });
    };
    const getAwsBucketList = () => {
      self.log(`${messagePrefix}Get bucket list`)
      return self.provider.request('S3', 'listBuckets').then((result)=>{
        return new Promise((resolve) => {
          resolve(result.Buckets.map((item)=>{
            return item.Name;
          }));
        });
      });
    };
    const getAllKeys = (bucket) => {
      self.log(`${messagePrefix}Get bucket object list ${bucket}`)
      const get = (src = {}) => {
        const data = src.data;
        const keys = src.keys || [];
        const param = {
          Bucket: bucket
        };
        if (data) {
          param.ContinuationToken = data.NextContinuationToken;
        }
        return self.provider.request('S3', 'listObjectsV2', param).then((result) => {
          return new Promise((resolve) => {
            resolve({
              data: result, keys: keys.concat(result.Contents.map((item) => {
                return item.Key;
              }))
            });
          });
        });
      };
      const list = (src = {}) => {
        return get(src).then((result) => {
          if (result.data.IsTruncated) {
            return list(result);
          } else {
            const keys = result.keys;
            const batched = [];
            for (let i = 0; i < keys.length; i += 1000) {
              const objects = keys.slice(i, i + 1000).map((item) => {
                return {Key: item};
              });
              batched.push({
                Bucket: bucket,
                Delete: {
                  Objects: objects
                }
              });
            }
            return new Promise((resolve) => {
              resolve(batched);
            });
          }
        });
      };
      return list();
    };
    const executeRemove = (params) => {
      self.log(`${messagePrefix}Remove all bucket object`)
      return Promise.all(params.map(param => {
        return self.provider.request('S3', 'deleteObjects', param);
      }));
    };
    const executeDeleteBucket = (bucket) => {
      self.log(`${messagePrefix}Delete bucket ${bucket}`);
      return self.provider.request('S3', 'deleteBucket', {Bucket: bucket});
    };

    const populateConfig = () => {
      return this.serverless.variables.populateObject(this.serverless.service.custom.cleanupS3DeleteBucket)
        .then(fileConfig => {
          const defaultConfig = {
            enable: true,
            bucketList: [],
          };
          return Object.assign({}, defaultConfig, fileConfig);
        });
    };

    return new Promise((resolve) => {
      return populateConfig().then(config => {
        if (!this.isTrue(config.enable)) { return Promise.all([]).then(resolve); }
        const enableBucketList = config.bucketList.filter(i=>((!('enable' in i))||(this.isTrue(i['enable']))));
        if (enableBucketList.length<=0) { return Promise.all([]).then(resolve); }
        return getAwsStackExist().then(awsStackExist=>{
          if(awsStackExist){
            self.log(`${messagePrefix}Stack exist`)
            return Promise.all([]).then(resolve);
          }
          self.log(`${messagePrefix}Stack not exist`)
          return getAwsBucketList().then(awsBucketList=>{
            // self.log(awsBucketList);
            const awsBucketSet = new Set(awsBucketList);
            const processBucketList = enableBucketList.filter(i=>awsBucketSet.has(i.bucketName));
            const processBucketNameList = processBucketList.map(i=>i.bucketName);
            self.log(`processBucketNameList: ${processBucketNameList}`);
            let promisses = [];
            for (const bucketData of processBucketList) {
              const bucketName = bucketData.bucketName;
              promisses.push(getAllKeys(bucketName).then(executeRemove).then(() => {
                return executeDeleteBucket(bucketName);
              }).then(() => {
                const message = `Success: ${bucketName} is deleted.`;
                self.log(message);
                self.serverless.cli.consoleLog(`${messagePrefix}${chalk.yellow(message)}`);
              }).catch((err) => {
                const message = `Fail: ${bucketName} may not be deleted.`;
                self.log(message);
                self.log(err);
                self.serverless.cli.consoleLog(`${messagePrefix}${chalk.yellow(message)}`);
              }));
            }
            return Promise.all(promisses).then(resolve);
          });
        });
      });
    });
  }
}

module.exports = ServerlessCleanupS3DeleteBucket;
