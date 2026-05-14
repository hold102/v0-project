/*
 * server.js — Entry point that starts the HTTP server
 * Loads environment variables via dotenv, imports the configured Express app,
 * and binds it to the configured port.
 * Run with: node src/server.js
 */

require("dotenv").config();

const app = require("./app");
const { port } = require("./config/env");


// Start listening — the callback fires once the server is ready
app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
