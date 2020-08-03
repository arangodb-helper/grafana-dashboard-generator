#!/bin/sh
(
cat << 'EOF'
simple-performance-single-server-all-time single-server-all-time.json
simple-performance-single-server-6-months single-server-6-months.json
simple-performance-single-server-6-months single-server-6-months.json
simple-performance-single-server-1-month  single-server-1-month.json
simple-performance-single-server-2-weeks  single-server-2-weeks.json
simple-performance-single-server-2-days   single-server-2-days.json
EOF
) | while read a b; do
  curl "https://grafana.arangodb.biz/api/snapshots/$a" \
    -H 'accept: application/json, text/plain, */*' \
    -H "x-grafana-org-id: ${ORGID}" \
    -H 'content-type: application/json' \
    -H "Authorization: Bearer ${APIKEY}" \
    -X DELETE
  echo

  curl 'https://grafana.arangodb.biz/api/snapshots' \
    -H 'accept: application/json, text/plain, */*' \
    -H "x-grafana-org-id: ${ORGID}" \
    -H 'content-type: application/json' \
    -H "Authorization: Bearer ${APIKEY}" \
    --data-binary @$b \
    --compressed
  echo
done

curl 'https://grafana.arangodb.biz/api/snapshots/simple-performance-cluster' \
  -H 'accept: application/json, text/plain, */*' \
  -H "x-grafana-org-id: ${ORGID}" \
  -H 'content-type: application/json' \
  -H "Authorization: Bearer ${APIKEY}" \
  -X DELETE
echo

curl 'https://grafana.arangodb.biz/api/snapshots' \
  -H 'accept: application/json, text/plain, */*' \
  -H "x-grafana-org-id: ${ORGID}" \
  -H 'content-type: application/json' \
  -H "Authorization: Bearer ${APIKEY}" \
  --data-binary @cluster.json \
  --compressed
echo

curl 'https://grafana.arangodb.biz/api/snapshots/simple-performance-singleserver-cluster' \
  -H 'accept: application/json, text/plain, */*' \
  -H "x-grafana-org-id: ${ORGID}" \
  -H 'content-type: application/json' \
  -H "Authorization: Bearer ${APIKEY}" \
  -X DELETE
echo

curl 'https://grafana.arangodb.biz/api/snapshots' \
  -H 'accept: application/json, text/plain, */*' \
  -H "x-grafana-org-id: ${ORGID}" \
  -H 'content-type: application/json' \
  -H "Authorization: Bearer ${APIKEY}" \
  --data-binary @single-cluster.json \
  --compressed
echo

