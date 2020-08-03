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
    -H "x-grafana-org-id: ${GRAFANA_ORG_ID}" \
    -H 'content-type: application/json' \
    -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
    -X DELETE
  echo

  curl 'https://grafana.arangodb.biz/api/snapshots' \
    -H 'accept: application/json, text/plain, */*' \
    -H "x-grafana-org-id: ${GRAFANA_ORG_ID}" \
    -H 'content-type: application/json' \
    -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
    --data-binary @$b \
    --compressed
  echo
done

curl 'https://grafana.arangodb.biz/api/snapshots/simple-performance-cluster' \
  -H 'accept: application/json, text/plain, */*' \
  -H "x-grafana-org-id: ${GRAFANA_ORG_ID}" \
  -H 'content-type: application/json' \
  -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
  -X DELETE
echo

curl 'https://grafana.arangodb.biz/api/snapshots' \
  -H 'accept: application/json, text/plain, */*' \
  -H "x-grafana-org-id: ${GRAFANA_ORG_ID}" \
  -H 'content-type: application/json' \
  -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
  --data-binary @cluster.json \
  --compressed
echo

curl 'https://grafana.arangodb.biz/api/snapshots/simple-performance-singleserver-cluster' \
  -H 'accept: application/json, text/plain, */*' \
  -H "x-grafana-org-id: ${GRAFANA_ORG_ID}" \
  -H 'content-type: application/json' \
  -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
  -X DELETE
echo

curl 'https://grafana.arangodb.biz/api/snapshots' \
  -H 'accept: application/json, text/plain, */*' \
  -H "x-grafana-org-id: ${GRAFANA_ORG_ID}" \
  -H 'content-type: application/json' \
  -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
  --data-binary @single-cluster.json \
  --compressed
echo

