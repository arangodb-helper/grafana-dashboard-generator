const _ = require("lodash");
const strftime = require("./strftime");
const fs = require("fs");

const generateDashboard = function(cfg) {
  const dashboardT = cfg.dashboard;
  const panelsT = cfg.panels;
  const fieldsT = cfg.fields;

  // print(cfg.query);
  // print(cfg.data);

  const data = db._query(cfg.query, cfg.data).toArray();
  print(`INFO ${cfg.title} has ${data.length} entries`);

  const panels = [];
  let pid = 1;

  for (let d of data) {
    const x = (pid - 1) % cfg.perRows;
    const y = (pid - 1 - x) / cfg.perRows;

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
  dashboard.key = cfg.key;
  dashboard.deleteKey = cfg.key + "-delete";
  dashboard.name = cfg.title;
  dashboard.dashboard.title = cfg.title;
  dashboard.dashboard.panels = panels;

  return dashboard;
};

const nowDate = new Date();
const now = nowDate.getTime();

const writeSnapshot = function(file, definition, reps) {
  const dashboard = generateDashboard(definition);
  let text = JSON.stringify(dashboard);

  for (let key in reps) {
    let find = "{{" + key + "}}";
    let re = new RegExp(find, 'g');
    text = text.replace(re, reps[key]);
  }

  fs.writeFileSync(file, text);
}

let intervals = [
  {
    ms: 6 * 30 * 24 * 3600 * 1000,
    title: "Simple - Single Server - 6 Months",
    key: "simple-performance-single-server-6-months",
    file: "single-server-6-months",
    timeRange: "6M"
  },
  {
    ms: 1 * 30 * 24 * 3600 * 1000,
    title: "Simple - Single Server - 1 Month",
    key: "simple-performance-single-server-1-month",
    file: "single-server-1-month",
    timeRange: "1M"
  },
  {
    ms: 14 * 24 * 3600 * 1000,
    title: "Simple - Single Server - 2 Weeks",
    key: "simple-performance-single-server-2-weeks",
    file: "single-server-2-weeks",
    timeRange: "14d"
  },
  {
    ms: 2 * 24 * 3600 * 1000,
    title: "Simple - Single Server - 2 Days",
    key: "simple-performance-single-server-2-days",
    file: "single-server-2-days",
    timeRange: "2d"
  },
];

const allTime = (db._query(`
  FOR p IN simple
    FILTER p.size.size == 'big'
       and p.configuration.mode == 'singleserver'
    SORT p.ms ASC
    LIMIT 1
    RETURN p.ms
`).toArray())[0];

const allInterval = Math.floor((now - allTime) / (1000 * 60 * 60 * 24));

intervals.push({
  ms: (now - allTime),
  title: "Simple - Single Server - All Time",
  key: "simple-performance-single-server-all-time",
  file: "single-server-all-time",
  timeRange: allInterval + "d"
});

for (let cfg of intervals) {
  for (let panel of ["trend", "gauge"]) {
    let startDate = now - cfg.ms;
    let stopDate = now;

    let versions = db._query(`
      FOR p IN simple
        FILTER p.size.size == 'big'
           and p.configuration.mode == 'singleserver'
           and p.ms > @from and p.ms <= @to
        RETURN distinct p.configuration.version
    `, { from: startDate, to: stopDate }).toArray();

    writeSnapshot(cfg.file + "-" + panel + ".json", {
      title: cfg.title + " - " + panel,
      key: cfg.key + "-" + panel,
      perRows: (panel === "trend") ? 2 : 1,

      dashboard: require("./templates/dashboard.json"),
      panels: require("./templates/" + panel + ".json"),
      fields: require("./templates/fields.json"),

      query: fs.read("./queries/given-versions.aql"),
      data: {
        versions: versions,
        size: "big",
        mode: "singleserver",
        from: startDate,
        to: stopDate
      }
    },
    {
      TIME_RANGE: cfg.timeRange,
      DASHBOARD_NAME: cfg.title,
      SNAPSHOT_NAME: cfg.title,
      FROM_RANGE: strftime('%FT%TZ', new Date(nowDate - cfg.ms)),
      TO_RANGE:  strftime('%FT%TZ', nowDate)
    });
  }
}

writeSnapshot("cluster.json", {
  title: "Simple - Cluster",
  key: "simple-performance-cluster",

  dashboard: require("./templates/dashboard.json"),
  panels: require("./templates/trend.json"),
  fields: require("./templates/fields.json"),

  query: fs.read("./queries/given-versions.aql"),
  data: {
    versions: [ "3.4", "3.5", "3.6", "3.7", "devel" ],
    size: "medium",
    mode: "cluster",
    from: now - 6 * 30 * 24 * 3600 * 1000,
    to: now
  }
});

writeSnapshot("single-cluster.json", {
  title: "Simple - Single Server vs. Cluster (devel)",
  key: "simple-performance-singleserver-cluster-devel",

  dashboard: require("./templates/dashboard.json"),
  panels: require("./templates/trend.json"),
  fields: require("./templates/fields.json"),

  query: fs.read("./queries/compare-single-cluster.aql"),
  data: {
    version: "devel",
    size: "medium",
    from: now - 6 * 30 * 24 * 3600 * 1000,
    to: now
  }
});
