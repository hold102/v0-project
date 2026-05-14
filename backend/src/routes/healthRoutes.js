const express = require("express");

const { getHealth } = require("../controllers/healthController");

const router = express.Router();

router.get("/health", getHealth);
router.get("/api/health", getHealth);

module.exports = router;
