/*
 * groupController.js — Group CRUD handlers
 * Thin request handlers. They pull data from req.params / req.body and
 * delegate to groupService for all business logic and validation.
 */
const {
  createGroup: createGroupService,
  deleteGroup: deleteGroupService,
  getGroupById: getGroupByIdService,
  listGroups: listGroupsService,
  updateGroup: updateGroupService,
} = require("../services/groupService");

async function listGroups(_req, res, next) {
  try {
    const groups = await listGroupsService();
    res.json(groups);
  } catch (error) {
    next(error);
  }
}

async function getGroupById(req, res, next) {
  try {
    const group = await getGroupByIdService(req.params.id);
    res.json(group);
  } catch (error) {
    next(error);
  }
}

async function createGroup(req, res, next) {
  try {
    const group = await createGroupService(req.body);
    res.status(201).json(group);
  } catch (error) {
    next(error);
  }
}

async function updateGroup(req, res, next) {
  try {
    const group = await updateGroupService(req.params.id, req.body);
    res.json(group);
  } catch (error) {
    next(error);
  }
}

async function deleteGroup(req, res, next) {
  try {
    const result = await deleteGroupService(req.params.id);
    res.json(result);
  } catch (error) {
    next(error);
  }
}

module.exports = {
  createGroup,
  deleteGroup,
  getGroupById,
  listGroups,
  updateGroup,
};
