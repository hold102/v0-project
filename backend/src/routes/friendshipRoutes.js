/*
 * friendshipRoutes.js — Routes mounted at /api/friends
 */
const express = require("express");
const {
  postRequest,
  postAccept,
  postReject,
  getIncoming,
  getOutgoing,
  getFriends,
  getStatuses,
} = require("../controllers/friendshipController");

const router = express.Router();

router.get("/", getFriends);
router.get("/statuses", getStatuses);
router.get("/requests/incoming", getIncoming);
router.get("/requests/outgoing", getOutgoing);
router.post("/request", postRequest);
router.post("/requests/:userId/accept", postAccept);
router.post("/requests/:userId/reject", postReject);

module.exports = router;
