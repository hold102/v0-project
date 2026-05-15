/*
 * friendshipService.js — Friend request + friendship management
 *
 * Uses a single `friendships` table (separate from the sync RPC) so the
 * friend graph is independent of the in-memory blob model.
 *
 * Each row represents either a pending friend request (status='pending')
 * or an accepted friendship (status='accepted'). The requester_id is whoever
 * initiated the request; for accepted rows the pair stays in the order it was
 * stored (we don't normalize ordering — both directions are queried instead).
 */
const supabase = require("../config/supabase");
const { RequestError } = require("../models/requestError");
const { readDb } = require("./supabaseService");

function publicUser(user) {
  return user
    ? { id: user.id, name: user.name, avatar: user.avatar, email: user.email }
    : null;
}

async function getRowBetween(a, b) {
  const { data, error } = await supabase
    .from("friendships")
    .select("*")
    .or(
      `and(requester_id.eq.${a},target_id.eq.${b}),and(requester_id.eq.${b},target_id.eq.${a})`
    )
    .maybeSingle();
  if (error) throw new Error(`Friendship lookup failed: ${error.message}`);
  return data;
}

async function sendRequest(currentUserId, targetUserId) {
  if (!currentUserId) throw new RequestError("Not signed in.", 401);
  if (!targetUserId || typeof targetUserId !== "string")
    throw new RequestError("Target user id is required.");
  if (currentUserId === targetUserId)
    throw new RequestError("Cannot send a friend request to yourself.");

  const db = await readDb();
  const target = db.users.find((u) => u.id === targetUserId);
  if (!target) throw new RequestError("User not found.", 404);

  const existing = await getRowBetween(currentUserId, targetUserId);
  if (existing) {
    if (existing.status === "accepted")
      throw new RequestError("Already friends.", 409);
    if (existing.requester_id === currentUserId)
      throw new RequestError("Friend request already sent.", 409);
    // Other side already sent us one — auto-accept it as the polite default
    return acceptRequest(currentUserId, targetUserId);
  }

  const { error } = await supabase.from("friendships").insert({
    requester_id: currentUserId,
    target_id: targetUserId,
    status: "pending",
  });
  if (error) throw new Error(`Friend request failed: ${error.message}`);
  return { status: "pending" };
}

async function acceptRequest(currentUserId, otherUserId) {
  if (!currentUserId) throw new RequestError("Not signed in.", 401);

  // The pending row must have currentUserId as the target (someone sent to us).
  const { data, error } = await supabase
    .from("friendships")
    .update({ status: "accepted" })
    .eq("requester_id", otherUserId)
    .eq("target_id", currentUserId)
    .eq("status", "pending")
    .select()
    .maybeSingle();
  if (error) throw new Error(`Accept failed: ${error.message}`);
  if (!data) throw new RequestError("No pending request from that user.", 404);
  return { status: "accepted" };
}

async function rejectRequest(currentUserId, otherUserId) {
  if (!currentUserId) throw new RequestError("Not signed in.", 401);
  const { error } = await supabase
    .from("friendships")
    .delete()
    .eq("requester_id", otherUserId)
    .eq("target_id", currentUserId)
    .eq("status", "pending");
  if (error) throw new Error(`Reject failed: ${error.message}`);
  return { status: "rejected" };
}

async function listIncomingRequests(currentUserId) {
  if (!currentUserId) throw new RequestError("Not signed in.", 401);
  const { data, error } = await supabase
    .from("friendships")
    .select("requester_id, created_at")
    .eq("target_id", currentUserId)
    .eq("status", "pending");
  if (error) throw new Error(`List requests failed: ${error.message}`);

  const db = await readDb();
  const userMap = new Map(db.users.map((u) => [u.id, u]));
  return (data || [])
    .map((r) => ({
      user: publicUser(userMap.get(r.requester_id)),
      createdAt: r.created_at,
    }))
    .filter((r) => r.user !== null);
}

async function listOutgoingRequests(currentUserId) {
  if (!currentUserId) throw new RequestError("Not signed in.", 401);
  const { data, error } = await supabase
    .from("friendships")
    .select("target_id, created_at")
    .eq("requester_id", currentUserId)
    .eq("status", "pending");
  if (error) throw new Error(`List outgoing failed: ${error.message}`);

  const db = await readDb();
  const userMap = new Map(db.users.map((u) => [u.id, u]));
  return (data || [])
    .map((r) => ({
      user: publicUser(userMap.get(r.target_id)),
      createdAt: r.created_at,
    }))
    .filter((r) => r.user !== null);
}

async function listFriends(currentUserId) {
  if (!currentUserId) throw new RequestError("Not signed in.", 401);
  const { data, error } = await supabase
    .from("friendships")
    .select("requester_id, target_id, created_at")
    .or(`requester_id.eq.${currentUserId},target_id.eq.${currentUserId}`)
    .eq("status", "accepted");
  if (error) throw new Error(`List friends failed: ${error.message}`);

  const db = await readDb();
  const userMap = new Map(db.users.map((u) => [u.id, u]));
  return (data || [])
    .map((r) => {
      const otherId =
        r.requester_id === currentUserId ? r.target_id : r.requester_id;
      return { user: publicUser(userMap.get(otherId)), since: r.created_at };
    })
    .filter((r) => r.user !== null);
}

// Bulk-fetch statuses with all other users — used by the frontend to render
// friend-status badges in search results without N round-trips.
async function getStatusMap(currentUserId) {
  if (!currentUserId) return {};
  const { data, error } = await supabase
    .from("friendships")
    .select("requester_id, target_id, status")
    .or(`requester_id.eq.${currentUserId},target_id.eq.${currentUserId}`);
  if (error) throw new Error(`Status map failed: ${error.message}`);

  const map = {};
  for (const r of data || []) {
    const otherId =
      r.requester_id === currentUserId ? r.target_id : r.requester_id;
    if (r.status === "accepted") {
      map[otherId] = "friend";
    } else if (r.requester_id === currentUserId) {
      map[otherId] = "outgoing"; // I sent them a request
    } else {
      map[otherId] = "incoming"; // They sent me a request
    }
  }
  return map;
}

module.exports = {
  sendRequest,
  acceptRequest,
  rejectRequest,
  listIncomingRequests,
  listOutgoingRequests,
  listFriends,
  getStatusMap,
};
