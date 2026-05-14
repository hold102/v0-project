const express = require("express");
const { createUser, getUserById, listUsers } = require("../controllers/userController");

const router = express.Router();

router.get("/", listUsers);
router.get("/:id", getUserById);
router.post("/", createUser);

module.exports = router;
