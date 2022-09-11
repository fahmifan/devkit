#!/usr/bin/bash

# load env
set -o allexport # enable all variable definitions to be exported
source <(sed -e "s/\r//" -e '/^#/d;/^\s*$/d' -e "s/'/'\\\''/g" -e "s/=\(.*\)/=\"\1\"/g" ".env")
set +o allexport

mermerd --encloseWithMermaidBackticks \
    -c "postgresql://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=${DB_SSL_MODE}" \
    --outputFileName ./doc/erd.md \
    --schema public \
    --useAllTables \
    --showAllConstraints \
    --omitConstraintLabels=false