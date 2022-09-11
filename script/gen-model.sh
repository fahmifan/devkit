#!/usr/bin/bash

# load env
set -o allexport # enable all variable definitions to be exported
source <(sed -e "s/\r//" -e '/^#/d;/^\s*$/d' -e "s/'/'\\\''/g" -e "s/=\(.*\)/=\"\1\"/g" ".env")
set +o allexport

gen --sqltype=postgres \
   	--connstr "host=${DB_HOST} port=${DB_PORT} user=${DB_USER} password=${DB_PASS} dbname=${DB_NAME} sslmode=disable" \
   	--database main  \
   	--json \
   	--gorm \
   	--guregu \
   	--out . \
   	--json-fmt=snake