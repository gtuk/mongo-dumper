#!/bin/bash
set -eo pipefail

port=27017
location=$(echo "$HOME")
encryption=true
cluster_wide=false
upload=false
api_version=S3v4
minio_client=mc

while test $# -gt 0; do
  case "$1" in
    --host)
      shift
      host=$1
      shift
      ;;
    --port)
      shift
      port=$1
      shift
      ;;
    --db)
      shift
      db=$1
      shift
      ;;
    --user)
      shift
      user=$1
      shift
      ;;
    --password)
      shift
      password=$1
      shift
      ;;
    --authentication-database)
      shift
      authentication_database=$1
      shift
      ;;
    --location)
      shift
      location=$1
      shift
      ;;
    --backup-password)
      shift
      backup_password=$1
      shift
      ;;
    --encryption)
      shift
      encryption=$1
      shift
      ;;
    --cluster-wide)
      shift
      cluster_wide=$1
      shift
      ;;
    --upload)
      shift
      upload=$1
      shift
      ;;
    --endpoint)
      shift
      endpoint=$1
      shift
      ;;
    --access-key)
      shift
      access_key=$1
      shift
      ;;
    --secret-key)
      shift
      secret_key=$1
      shift
      ;;
    --bucket)
      shift
      bucket=$1
      shift
      ;;
    --api-version)
      shift
      api_version=$1
      shift
      ;;
    --minio-client)
      shift
      minio_client=$1
      shift
      ;;
    *)
     echo "$1 is not a valid flag!"
     exit 1;
     ;;
  esac
done

# Validate flags
if [ -z "${host}" ]; then
  echo "host parameter needs to be set"
  exit 1
fi

if [ "$cluster_wide" = false ] && [ -z "${db}" ]; then
  echo "db parameter needs to be set if cluster-wide is false"
  exit 1
fi

if [ -z "${user}" ]; then
  echo "user parameter needs to be set"
  exit 1
fi

if [ -z "${password}" ]; then
  echo "password parameter needs to be set"
  exit 1
fi

if [ "$encryption" = true ] && [ -z "${backup_password}" ]; then
  echo "backup-password parameter needs to be set if encryption is true"
  exit 1
fi

if [ "$upload" = true ];then
  if [ -z "${endpoint}" ] || [ -z "${access_key}" ] || [ -z "${secret_key}" ] || [ -z "${bucket}" ]; then
    echo "endpoint, access-key, secret-key and bucket parameter need to be set if upload is true"
    exit 1
  fi
fi

# Check requirements
if [ "$encryption" = true ] && ! [ -x "$(command -v gpg)" ]; then
  echo "gpg is not installed or not executable"
  exit 1
fi

if ! [ -x "$(command -v mongodump)" ]; then
  echo "mongodump is not installed or not executable"
  exit 1
fi

name=$(date "+%Y-%m-%d")_$(openssl rand -hex 10)
name_without_extension=$name

if [ "$cluster_wide" = true ]; then
  name=$(date "+%Y-%m-%d")_$(openssl rand -hex 10)_cluster
  name_without_extension=$name

  if [ -z "$authentication_database" ]; then
    authentication_database="admin"
  fi
else
  if [ -z "$authentication_database" ]; then
    authentication_database=$db
  fi
fi

echo $authentication_database

if [ "$encryption" = true ]; then
  name="${name}.gpg"
else
  name="${name}.gz"
fi

# Backup
echo "Backup"

backup_result=0
if [ "$encryption" = true ]; then
  if [ "$cluster_wide" = true ]; then
    if mongodump --archive --username="$user" --host="$host" --port="$port" --password="$password" --authenticationDatabase="$authentication_database" --gzip | gpg --batch --passphrase "$backup_password" -c -o "$location"/"$name"; then backup_result=0; else backup_result=1; fi
  elif [ "$db" ]; then
    if mongodump --archive --username="$user" --host="$host" --port="$port" --password="$password" --db="$db" --authenticationDatabase="$authentication_database" --gzip | gpg --batch --passphrase "$backup_password" -c -o "$location"/"$name"; then backup_result=0; else backup_result=1; fi
  else
    echo "Backup failed. Db parameter needs to when cluster_wide parameter is false"
  fi
elif [ "$encryption" = false ]; then
  if [ "$cluster_wide" = true ]; then
    if mongodump --archive --username="$user" --host="$host" --port="$port" --password="$password" --authenticationDatabase="$authentication_database" --gzip > "$location"/"$name"; then backup_result=0; else backup_result=1; fi
  elif [ "$db" ]; then
    if mongodump --archive --username="$user" --host="$host" --port="$port" --password="$password" --db="$db" --authenticationDatabase="$authentication_database" --gzip > "$location"/"$name"; then backup_result=0; else backup_result=1; fi
  else
    echo "Backup failed. Db parameter needs to when cluster-wide parameter is false"
  fi
else
  echo "Backup failed. Backup-password parameter needs to be set when encryption parameter is true"
fi

if [ "$backup_result" != 0 ]; then
  rm "$location"/"$name_without_extension"* 2> /dev/null
  echo "Backup failed"
  exit 1
fi

if [ "$upload" = true ]; then
  echo "Upload"

  upload_result=0

  if "$minio_client" alias set minio "$endpoint" "$access_key" "$secret_key" --api "$api_version"; then upload_result=0; else upload_result=1; fi

  if "$minio_client" cp "$location"/"$name" minio/"$bucket"; then upload_result=0; else upload_result=1; fi

  if [ "$upload_result" != 0 ]; then
    rm "$location"/"$name_without_extension"* 2> /dev/null
    echo "Upload failed"
    exit 1
  fi
fi
