# mongo-dumper

mongo-dumper is a simple cli script to easily dump, compress, encrypt and optionally upload your mongodb database/cluster.
The tool is using the --archive and optional the --gzip option from mongodump to create a backup. Keep this in mind if you restore your backup with mongorestore.

---

### Requirements
In order to run the script you need to have gnupg, the minio client (mc) and mongodump installed (version should match the mongodb server).

### Make script executable
```shell
chmod +x mongo-dumper.sh
```

### Backup with encryption enabled
```shell
./mongo-dumper.sh --host localhost --db app --password password --user root --port 27017 --backup-password supersecret --location ./
```

### Backup with encryption disabled
```shell
./mongo-dumper.sh --host localhost --db app --password password --user root --port 27017 location ./ --encryption false
```

---

### Extract backup with encryption enabled
```shell
gpg -o backup_file.gz -d backup_file.gpg
```

### Parameters

| Parameter      | Description | Default |
| ----------- | ----------- | ----------- | 
| host      | Mongodb host       | (required)
| user   | Mongodb user        | (required)
| password   | Mongodb password        | (required)
| db   | Mongodb db        | (required if cluster-wide is false)
| port   | Mongodb port        | 27017
| authenticationDatabase   | Authentication db for the user credentials        | mongodump assumes the admin database hold the user credentials authenticationDatabase. If cluster-wide is false mongodump assumes that the db specified holds the user credentials
| location   | Location for the backup        | $HOME
| backup-password   | Password for encryption        | (required if encryption is true)
| encryption   | Enable/disable encryption        | true
| cluster-wide   | Backup whole mongodb cluster        | false
| upload   | If true it will upload the backup to a s3 compatible storage        | false
| endpoint   | s3 compatible endpoint       | (required if upload is true)
| bucket   | s3 bucket for uploading (needs to end with a slash)       | (required if upload is true)
| access-key   | s3 compatible storage access-key       | (required if upload is true)
| access-secret   | s3 compatible storage secret-key       | (required if upload is true)
| api-version   | api-signature (minio client)       | S3v4
| minio-client   | custom location of the minio client (e.g ./mc)      | mc

### Build docker image
```shell
# Example to build for mongodb 5.0
docker build --no-cache --build-arg MONGODB_VERSION=5.0 -t mongo-dumper:mongo-5.0 .
```

### Prebuild docker images
https://hub.docker.com/r/gtuk/mongo-dumper

```shell
docker run gtuk/mongo-dumper:mongo-5.0 --host <HOST> --password <PASSWORD> --user <USER> --port <PORT> --backup-password <SUPER_SECRET_PASSWORD> --location ./ --cluster-wide true --upload true --endpoint <ENDPOINT> --access-key <ACCESS_KEY> --secret-key <SECRET_KEY> --bucket <BUCKET> --minio-client ./mc
```
