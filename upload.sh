#!/bin/bash
failed=false
logfile=/tmp/logfile.$$
curllog=/tmp/curllog.$$

function logDelete {
  url=$1

  echo "DELETE $url"
  cat $curllog
  echo
  echo

  (
    echo "DELETE $url"
    echo
  ) >> $logfile
}

function logCreate {
  url=$1

  echo "POST $url"
  cat $curllog
  echo
  echo

  (
    echo "DELETE $url"
    cat $curllog
    echo
  ) >> $logfile
}

for panel in trend gauge; do
  (
cat << 'EOF'
simple-performance-single-server-all-time single-server-all-time
simple-performance-single-server-6-months single-server-6-months
simple-performance-single-server-6-months single-server-6-months
simple-performance-single-server-1-month  single-server-1-month
simple-performance-single-server-2-weeks  single-server-2-weeks
simple-performance-single-server-2-days   single-server-2-days
EOF
  ) | while read a b; do
    file=${b}-${panel}.json

    if test -f $file; then
      echo "Uploading $file"

      url="https://g-dc685c4b12.grafana-workspace.eu-central-1.amazonaws.com/api/snapshots/$a-${panel}"
      curl $url -s -k -v \
        -H 'accept: application/json, text/plain, */*' \
        -H "x-grafana-org-id: ${GRAFANA_ORG_ID}" \
        -H 'content-type: application/json' \
        -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
        -X DELETE > $curllog
      logDelete $url

      sleep 5

      url='https://g-dc685c4b12.grafana-workspace.eu-central-1.amazonaws.com/api/snapshots'
      curl $url -s -k -v \
        -H 'accept: application/json, text/plain, */*' \
        -H "x-grafana-org-id: ${GRAFANA_ORG_ID}" \
        -H 'content-type: application/json' \
        -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
        --data-binary @${file} \
        --compressed > $curllog || failed=true
      logCreate $url
    else
      echo "ERROR: $file missing"
      failed=true
    fi
  done
done

echo "Uploading simple-performance-cluster"

url='https://g-dc685c4b12.grafana-workspace.eu-central-1.amazonaws.com/api/snapshots/simple-performance-cluster'
curl $url -s -k -v \
  -H 'accept: application/json, text/plain, */*' \
  -H "x-grafana-org-id: ${GRAFANA_ORG_ID}" \
  -H 'content-type: application/json' \
  -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
  -X DELETE > $curllog
logDelete $url

sleep 5

url='https://g-dc685c4b12.grafana-workspace.eu-central-1.amazonaws.com/api/snapshots'
curl $url -s -k -v \
  -H 'accept: application/json, text/plain, */*' \
  -H "x-grafana-org-id: ${GRAFANA_ORG_ID}" \
  -H 'content-type: application/json' \
  -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
  --data-binary @cluster.json \
  --compressed > $curllog || failed=true
logCreate $url

echo "Uploading simple-performance-singleserver-cluster-devel"

url='https://g-dc685c4b12.grafana-workspace.eu-central-1.amazonaws.com/api/snapshots/simple-performance-singleserver-cluster-devel'
curl $url -s -k -v \
  -H 'accept: application/json, text/plain, */*' \
  -H "x-grafana-org-id: ${GRAFANA_ORG_ID}" \
  -H 'content-type: application/json' \
  -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
  -X DELETE > $curllog
logDelete $url

sleep 5

url='https://g-dc685c4b12.grafana-workspace.eu-central-1.amazonaws.com/api/snapshots'
curl $url -s -k -v \
  -H 'accept: application/json, text/plain, */*' \
  -H "x-grafana-org-id: ${GRAFANA_ORG_ID}" \
  -H 'content-type: application/json' \
  -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
  --data-binary @single-cluster.json \
  --compressed > $curllog || failed=true
logCreate $url

rm -f $curllog

if grep -B 3 -i fail $logfile; then
    echo "ERROR found fail in log file"
    cat $logfile
    rm -f $logfile
    exit 1
fi

if test "$failed" = "true"; then
    cat $logfile
    rm -f $logfile
    exit 1
fi

rm -f $logfile
