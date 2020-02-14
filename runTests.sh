:
#Should work in any Bourne shell descendant, tested with dash and bash.


set -o errexit -o nounset
server="$1"

#Stops and removes the docker container named "server", reporting this with $serverKind.
cleanServer () {
  echo Status $? before cleaning server
  echo Stopping server $serverKind ...
  docker stop server

  echo Removing server $serverKind ...
  docker rm server
}

waitIfTrellis () {
  case "$server" in 
    trellis)
      docker logs server
      echo Waiting for ten seconds ...
      sleep 10
      docker logs server 
      ;; 
  esac
}

#Install clean up action:
serverKind="on unexpected exit"
trap "cleanServer; exit" INT TERM EXIT

echo Testing $server ...
echo Building image ...
docker build -t $server servers/$server


serverKind="without WAC"
echo Starting server $serverKind ...
docker run -d --name=server --env SKIP_WAC=true --network=testnet $server

waitIfTrellis

echo Running ldp-basic tester ...
docker run --network=testnet ldp-basic > reports/$server-ldp-basic.txt || echo ... Errors in ldp-basic tester

cleanServer

serverKind="with WAC"
echo Starting server $serverKind ...
docker run -d --name=server --network=testnet $server

waitIfTrellis

echo Running websockets-pubsub tester ...
docker run --network=testnet websockets-pubsub 2> reports/$server-websockets-pubsub.txt || echo ... Errors in websockets-pubsub tester

echo Running rdf-fixtures tester ...
docker run --network=testnet rdf-fixtures > reports/$server-rdf-fixtures.txt || echo ... Errors in rdf-fixtures tester

#cleanServer here automatically called by upper trap

