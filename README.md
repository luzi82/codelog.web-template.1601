[![Gitpod ready-to-code](https://img.shields.io/badge/Gitpod-ready--to--code-blue?logo=gitpod)](https://gitpod.io/#https://github.com/luzi82/codelog.web-template.1601)

# codelog.web-template.1601

Code template of AWS + serverless + Flask so I dont need to do things from zero.

## Example

https://compute-codelog-webtemplate1601-sample.aws-public.luzi82.com

https://static-codelog-webtemplate1601-sample.aws-public.luzi82.com

## Run gitpod

```
./s08_dev_run_local.sh
```

## Run local

```
aws configure # configure credentials
./s00_dev_init_env.sh
./s08_dev_run_local.sh
```

## Deploy to AWS

1. Create domain in AWS Route 53.
1. Create cert for domain.
1. Create and edit `conf/conf.json` from `conf/conf.json.sample`.
1. `./s50_aws_init_env.sh && ./s58_aws_deploy.sh`

## Undeploy from AWS

1. `./s50_aws_init_env.sh && ./s59_aws_undeploy.sh`
