const _ = require("lodash");
const fs = require("fs");

const query = fs.read("./queries/all-branches.aql");
const panelsT = require("./templates/panels.json");
const fieldsT = require("./templates/fields.json");
const dashboardT = require("./templates/dashboard.json");

const data = db._query(query, { branches: [
  "3.4", "3.5", "3.6", "3.7", "devel"
]}).toArray();

const panels = [];
let pid = 1;

for (let d of data) {
  const x = (pid - 1) % 2;
  const y = (pid - 1 - x) / 2;

  const panel = _.merge({}, panelsT);
  panel.id = pid++;

  const fields = [];

  for (let l of d.list) {
    const obj = _.merge({}, fieldsT);
    obj.fields[0].name = l.configuration;
    obj.fields[0].values = l.values;
    obj.fields[1].values = l.times;
    obj.name = l.configuration;

    fields.push(obj);
  }

  panel.gridPos.x = panel.gridPos.w * x;
  panel.gridPos.y = panel.gridPos.h * y;
  panel.title = d.test;
  panel.snapshotData = fields;
  panels.push(panel);
}

const dashboard = _.merge({}, dashboardT);
dashboard.key = "simple-performance-single-server";
dashboard.deleteKey = "simple-performance-single-server-delete";
dashboard.name = "Simple - Single Server";
dashboard.dashboard.title = "Simple - Single Server";
dashboard.dashboard.panels = panels;

fs.writeFileSync("snapshot.json", JSON.stringify(dashboard));

// SNAPSHOT-LINK
// https://grafana.arangodb.biz/d/UVAhBwiMk/performance-single-server?orgId=3

// SNAPSHOT-DATE
// 2020-06-25T14:53:41.228Z
