const path = require("path");

const port = Number.parseInt(process.env.PORT || "3000", 10);
const configuredDataFile = process.env.DATA_FILE || process.env.APP_DB_PATH;
const dataFile = configuredDataFile
  ? path.resolve(configuredDataFile)
  : path.join(__dirname, "..", "..", "data", "app-db.json");

module.exports = {
  port: Number.isFinite(port) ? port : 3000,
  dataFile,
};
