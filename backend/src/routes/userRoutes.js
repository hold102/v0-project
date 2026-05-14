/*
 * userRoutes.js — User routes
 * GET  /     — list all users
 * GET  /:id  — get a single user by ID
 * POST /     — create a new user (or return an existing one with the same name/email)
 */
const express = require("express");
const { createUser, getUserById, listUsers } = require("../controllers/userController");

const router = express.Router();

router.get("/", listUsers);
router.get("/:id", getUserById);
router.post("/", createUser);

module.exports = router;
