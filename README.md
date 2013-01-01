description
===

AWS CLI Tools collection.

usage
------
1) clone repo to your home dir
```
git clone https://github.com/j3tm0t0/aws.git ~/.aws
```

2) prepare key dir
```
$ . ~/.aws/env
$ key hogehoge
/Users/j3tm0t0/.aws/keys-hogehoge does not exist.
input AWSAccessKeyId : AWSACCESSKEY
input AWSSecretKey : AWSSECRETKEY
using keys-hogehoge
```

3) add following to your .bashrc
```
. ~/.aws/env
[ "$EC2_REGION" = "" ] && region ap-northeast-1
[ "$AWS_KEY_DIR" = "" ] && key hogehoge
```

You can change region to use by typing "region API_REGION_NAME".
Also, you can use alias use/usw/usw2/euw/apn/aps/aps2 to change region.

You can change user to use by typing "key FOOBAR" (you need to prepare keys-FOOBAR).

4) optional settings

change symlink from EB/bin to tools/AWS-ElasticBeanstalk-CLI-X.X/eb/OSTYPE/pythonX.X/ depending on your environment.

s3 --configure to setup s3cmd credential
