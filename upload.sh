#!/bin/sh
failed=false
logfile=/tmp/logfile.$$

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

      url="https://grafana.arangodb.biz/api/snapshots/$a-${panel}"
      echo $url >> $logfile
      curl $url -s -k \
        -H 'accept: application/json, text/plain, */*' \
        -H "x-grafana-org-id: ${GRAFANA_ORG_ID}" \
        -H 'content-type: application/json' \
        -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
        -X DELETE >> $logfile || failed=true
      echo

      url='https://grafana.arangodb.biz/api/snapshots'
      echo $url >> $logfile
      curl $url -s -k \
      curl 'https://grafana.arangodb.biz/api/snapshots' \
        -H 'accept: application/json, text/plain, */*' \
        -H "x-grafana-org-id: ${GRAFANA_ORG_ID}" \
        -H 'content-type: application/json' \
        -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
        --data-binary @${file} \
        --compressed >> $logfile || failed=true
      echo
    else
      echo "ERROR: $file missing"
      failed=true
    fi
  done
done

url='https://grafana.arangodb.biz/api/snapshots/simple-performance-cluster'
echo $url >> $logfile
curl $url -s -k \
  -H 'accept: application/json, text/plain, */*' \
  -H "x-grafana-org-id: ${GRAFANA_ORG_ID}" \
  -H 'content-type: application/json' \
  -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
  -X DELETE >> $logfile || failed=true
echo

url='https://grafana.arangodb.biz/api/snapshots'
echo $url >> $logfile
curl $url -s -k \
  -H 'accept: application/json, text/plain, */*' \
  -H "x-grafana-org-id: ${GRAFANA_ORG_ID}" \
  -H 'content-type: application/json' \
  -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
  --data-binary @cluster.json \
  --compressed >> $logfile || failed=true
echo

url='https://grafana.arangodb.biz/api/snapshots/simple-performance-singleserver-cluster'
echo $url >> $logfile
curl $url -s -k \
  -H 'accept: application/json, text/plain, */*' \
  -H "x-grafana-org-id: ${GRAFANA_ORG_ID}" \
  -H 'content-type: application/json' \
  -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
  -X DELETE >> $logfile || failed=true
echo

url='https://grafana.arangodb.biz/api/snapshots'
echo $url >> $logfile
curl $url -s -k \
  -H 'accept: application/json, text/plain, */*' \
  -H "x-grafana-org-id: ${GRAFANA_ORG_ID}" \
  -H 'content-type: application/json' \
  -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
  --data-binary @single-cluster.json \
  --compressed >> $logfile || failed=true
echo

if grep -B 3 -i fail $logfile; then
    rm -f $logfile
    exit 1
fi

rm -f $logfile

if test "$failed" = "true"; then
    exit 1
fi

