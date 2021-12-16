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

      curl "https://grafana.arangodb.biz/api/snapshots/$a-${panel}" \
        -H 'accept: application/json, text/plain, */*' \
        -H "x-grafana-org-id: ${GRAFANA_ORG_ID}" \
        -H 'content-type: application/json' \
        -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
        -k \
        -X DELETE || failed=true >> $logfile
      echo

      curl 'https://grafana.arangodb.biz/api/snapshots' \
        -H 'accept: application/json, text/plain, */*' \
        -H "x-grafana-org-id: ${GRAFANA_ORG_ID}" \
        -H 'content-type: application/json' \
        -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
        -k \
        --data-binary @${file} \
        --compressed || failed=true >> $logfile
      echo
    else
      echo "ERROR: $file missing"
      failed=true
    fi
  done
done

curl 'https://grafana.arangodb.biz/api/snapshots/simple-performance-cluster' \
  -H 'accept: application/json, text/plain, */*' \
  -H "x-grafana-org-id: ${GRAFANA_ORG_ID}" \
  -H 'content-type: application/json' \
  -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
  -k \
  -X DELETE || failed=true >> $logfile
echo

curl 'https://grafana.arangodb.biz/api/snapshots' \
  -H 'accept: application/json, text/plain, */*' \
  -H "x-grafana-org-id: ${GRAFANA_ORG_ID}" \
  -H 'content-type: application/json' \
  -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
  -k \
  --data-binary @cluster.json \
  --compressed || failed=true >> $logfile
echo

curl 'https://grafana.arangodb.biz/api/snapshots/simple-performance-singleserver-cluster' \
  -H 'accept: application/json, text/plain, */*' \
  -H "x-grafana-org-id: ${GRAFANA_ORG_ID}" \
  -H 'content-type: application/json' \
  -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
  -k \
  -X DELETE || failed=true >> $logfile
echo

curl 'https://grafana.arangodb.biz/api/snapshots' \
  -H 'accept: application/json, text/plain, */*' \
  -H "x-grafana-org-id: ${GRAFANA_ORG_ID}" \
  -H 'content-type: application/json' \
  -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
  -k \
  --data-binary @single-cluster.json \
  --compressed || failed=true >> $logfile
echo

if grep -qi fail $logfile; then
    rm -f $logfile
    exit 1
fi

rm -f $logfile

if test "$failed" = "true"; then
    exit 1
fi

