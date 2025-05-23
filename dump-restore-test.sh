#!/usr/bin/bash
set -euxo pipefail

export TERM=dumb

cleanup() {
  docker compose --ansi never -p dump-restore-test --env-file compose.env -f sqlite.compose.yaml -f mongo.compose.yaml down --remove-orphans -v
  rm -fR /tmp/my-mongodump-test
}
# cleanup volumes on exit
trap cleanup exit

# make /tmp/my-mongodump-test folder with 777 permissions
mkdir -p /tmp/my-mongodump-test/dump
chmod -R 777 /tmp/my-mongodump-test

# First let's boot komodo once with sqlite to init everything
docker compose --ansi never -p dump-restore-test --env-file compose.env -f sqlite.compose.yaml up --remove-orphans &
sleep 10s # Wait for the containers to start and the data to be init'd
docker compose --ansi never -p dump-restore-test --env-file compose.env -f sqlite.compose.yaml down --remove-orphans
sleep 5s

# Now let's dump the data
docker compose --ansi never -p dump-restore-test --env-file compose.env -f sqlite.compose.yaml -f mongodump.yaml up --exit-code-from mongodump --abort-on-container-exit --remove-orphans
docker compose --ansi never -p dump-restore-test --env-file compose.env -f sqlite.compose.yaml -f mongodump.yaml down --remove-orphans
sleep 5s

# Now let's restore the data
docker compose --ansi never -p dump-restore-test --env-file compose.env -f mongo.compose.yaml -f mongorestore.yaml up --exit-code-from mongorestore --abort-on-container-exit --remove-orphans
docker compose --ansi never -p dump-restore-test --env-file compose.env -f mongo.compose.yaml -f mongorestore.yaml down --remove-orphans
sleep 5s

# Now let's boot komodo back up
docker compose --ansi never -p dump-restore-test --env-file compose.env -f mongo.compose.yaml up --abort-on-container-exit --remove-orphans
