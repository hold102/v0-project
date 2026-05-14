const express = require("express");

const appStateRoutes = require("./appStateRoutes");
const expenseRoutes = require("./expenseRoutes");
const groupRoutes = require("./groupRoutes");
const healthRoutes = require("./healthRoutes");
const userRoutes = require("./userRoutes");

const router = express.Router();

router.use(healthRoutes);
router.use("/api/app-state", appStateRoutes);
router.use("/api/users", userRoutes);
router.use("/api/groups", groupRoutes);
router.use("/api/expenses", expenseRoutes);

module.exports = router;
