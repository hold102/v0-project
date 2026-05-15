/*
 * friendshipController.js — Friend request HTTP handlers
 * Resolves the current user from app_state (matches the rest of the app's auth
 * pattern) and delegates to friendshipService.
 */
const { readDb } = require("../services/supabaseService");
const {
  sendRequest,
  acceptRequest,
  rejectRequest,
  listIncomingRequests,
  listOutgoingRequests,
  listFriends,
  getStatusMap,
} = require("../services/friendshipService");
const { RequestError } = require("../models/requestError");

async function currentUserId() {
  const db = await readDb();
  if (!db.currentUserId) throw new RequestError("Not signed in.", 401);
  return db.currentUserId;
}

async function postRequest(req, res, next) {
  try {
    const uid = await currentUserId();
    const result = await sendRequest(uid, req.body?.userId);
    res.status(201).json(result);
  } catch (e) {
    next(e);
  }
}

async function postAccept(req, res, next) {
  try {
    const uid = await currentUserId();
    const result = await acceptRequest(uid, req.params.userId);
    res.json(result);
  } catch (e) {
    next(e);
  }
}

async function postReject(req, res, next) {
  try {
    const uid = await currentUserId();
    const result = await rejectRequest(uid, req.params.userId);
    res.json(result);
  } catch (e) {
    next(e);
  }
}

async function getIncoming(_req, res, next) {
  try {
    const uid = await currentUserId();
    res.json(await listIncomingRequests(uid));
  } catch (e) {
    next(e);
  }
}

async function getOutgoing(_req, res, next) {
  try {
    const uid = await currentUserId();
    res.json(await listOutgoingRequests(uid));
  } catch (e) {
    next(e);
  }
}

async function getFriends(_req, res, next) {
  try {
    const uid = await currentUserId();
    res.json(await listFriends(uid));
  } catch (e) {
    next(e);
  }
}

async function getStatuses(_req, res, next) {
  try {
    const uid = await currentUserId();
    res.json(await getStatusMap(uid));
  } catch (e) {
    next(e);
  }
}

module.exports = {
  postRequest,
  postAccept,
  postReject,
  getIncoming,
  getOutgoing,
  getFriends,
  getStatuses,
};
