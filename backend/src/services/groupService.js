const { createId, todayIsoDate } = require("./idService");
const { readDb, updateDb } = require("./dbService");
const { RequestError } = require("../models/requestError");

function normalizeText(value) {
  return typeof value === "string" ? value.trim() : "";
}

function normalizeOptionalId(value, label) {
  if (value === undefined) return undefined;
  const id = normalizeText(value);
  if (!id) {
    throw new RequestError(`${label} must be text.`);
  }
  return id;
}

function validateMemberIds(memberIds) {
  if (!Array.isArray(memberIds) || memberIds.length < 2) {
    throw new RequestError("At least two members are required.");
  }

  if (!memberIds.every((id) => typeof id === "string" && id.trim())) {
    throw new RequestError("All selected members must be valid user ids.");
  }

  const normalized = memberIds.map((id) => id.trim());
  const unique = new Set(normalized);

  if (unique.size !== normalized.length) {
    throw new RequestError("Selected members must be unique.");
  }

  return normalized;
}

function resolveMembers(db, memberIds) {
  const memberIdSet = new Set(memberIds);
  const members = db.users.filter((user) => memberIdSet.has(user.id));

  if (members.length !== memberIdSet.size) {
    throw new RequestError("One or more selected members do not exist.");
  }

  if (!memberIdSet.has(db.currentUserId)) {
    throw new RequestError("Selected members must include the current user.");
  }

  return members;
}

function assertGroupIsVisible(db, group) {
  const isMember = group.members.some((member) => member.id === db.currentUserId);
  if (!isMember) {
    throw new RequestError("Group not found.", 404);
  }
}

async function listGroups() {
  const db = await readDb();
  return db.groups.filter((group) =>
    group.members.some((member) => member.id === db.currentUserId)
  );
}

async function getGroupById(id) {
  if (typeof id !== "string" || !id.trim()) {
    throw new RequestError("Group id is required.");
  }

  const db = await readDb();
  const group = db.groups.find((candidate) => candidate.id === id);
  if (!group) {
    throw new RequestError("Group not found.", 404);
  }
  assertGroupIsVisible(db, group);

  return group;
}

async function createGroup(body) {
  const id = normalizeOptionalId(body?.id, "Group id");
  const name = normalizeText(body?.name);
  const emoji = normalizeText(body?.emoji);
  const memberIds = validateMemberIds(body?.memberIds);

  if (!name) {
    throw new RequestError("Group name is required.");
  }

  if (!emoji) {
    throw new RequestError("Group emoji is required.");
  }

  return updateDb((db) => {
    if (id && db.groups.some((group) => group.id === id)) {
      throw new RequestError("Group id already exists.", 409);
    }

    const members = resolveMembers(db, memberIds);

    const group = {
      id: id || createId("g"),
      name,
      emoji,
      members,
      createdAt: todayIsoDate(),
      expenses: [],
    };

    db.groups.push(group);
    return group;
  });
}

async function updateGroup(id, body) {
  const groupId = normalizeOptionalId(id, "Group id");
  const name = body?.name === undefined ? undefined : normalizeText(body.name);
  const emoji = body?.emoji === undefined ? undefined : normalizeText(body.emoji);
  const memberIds = body?.memberIds === undefined ? undefined : validateMemberIds(body.memberIds);

  if (!groupId) {
    throw new RequestError("Group id is required.");
  }

  if (body?.name !== undefined && !name) {
    throw new RequestError("Group name is required.");
  }

  if (body?.emoji !== undefined && !emoji) {
    throw new RequestError("Group emoji is required.");
  }

  return updateDb((db) => {
    const group = db.groups.find((candidate) => candidate.id === groupId);
    if (!group) {
      throw new RequestError("Group not found.", 404);
    }
    assertGroupIsVisible(db, group);

    if (name !== undefined) group.name = name;
    if (emoji !== undefined) group.emoji = emoji;

    if (memberIds !== undefined) {
      const memberIdSet = new Set(memberIds);
      const referencedUserIds = new Set();
      group.expenses.forEach((expense) => {
        referencedUserIds.add(expense.paidBy);
        expense.splitBetween.forEach((userId) => referencedUserIds.add(userId));
      });

      const removesReferencedUser = [...referencedUserIds].some((userId) => !memberIdSet.has(userId));
      if (removesReferencedUser) {
        throw new RequestError("Members with existing expenses cannot be removed.", 409);
      }

      group.members = resolveMembers(db, memberIds);
    }

    return group;
  });
}

async function deleteGroup(id) {
  const groupId = normalizeOptionalId(id, "Group id");
  if (!groupId) {
    throw new RequestError("Group id is required.");
  }

  return updateDb((db) => {
    const index = db.groups.findIndex((group) => group.id === groupId);
    if (index === -1) {
      throw new RequestError("Group not found.", 404);
    }

    const group = db.groups[index];
    assertGroupIsVisible(db, group);
    db.groups.splice(index, 1);
    return { group };
  });
}

module.exports = {
  createGroup,
  deleteGroup,
  getGroupById,
  listGroups,
  updateGroup,
};
