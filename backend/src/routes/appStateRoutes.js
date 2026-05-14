const express = require("express");
const { getAppState } = require("../controllers/appStateController");

const router = express.Router();

router.get("/", getAppState);

module.exports = router;
