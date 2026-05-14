/*
 * healthController.js — Simple liveness probe
 * Returns { status: "ok" }. Used by load balancers and monitoring to verify
 * the server process is alive and responding.
 */
function getHealth(req, res) {
  res.json({ status: "ok" });
}

module.exports = {
  getHealth,
};
