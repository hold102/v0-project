/*
 * normalize.js — Shared input-normalization helpers
 *
 * Previously each service (authService, expenseService, groupService,
 * userService) contained its own copy of normalizeText / normalizeEmail /
 * normalizeOptionalId. Centralising them here removes the duplication and
 * ensures consistent behaviour across the whole API.
 */
const { RequestError } = require("../models/requestError");

/**
 * Trim a string value; return "" for anything that isn't a string.
 * @param {unknown} value
 * @returns {string}
 */
function normalizeText(value) {
  return typeof value === "string" ? value.trim() : "";
}

/**
 * Normalise an email: trim and lowercase.
 * Returns "" when the value isn't a string.
 * @param {unknown} value
 * @returns {string}
 */
function normalizeEmail(value) {
  return typeof value === "string" ? value.trim().toLocaleLowerCase() : "";
}

/**
 * Normalise an ID that the caller may or may not provide.
 * - undefined → undefined (the caller will generate one)
 * - non-empty string → trimmed string
 * - empty string → throws RequestError
 * @param {unknown} value
 * @param {string} label  Used in the error message, e.g. "Group id"
 * @returns {string | undefined}
 */
function normalizeOptionalId(value, label) {
  if (value === undefined) return undefined;
  const id = normalizeText(value);
  if (!id) {
    throw new RequestError(`${label} must be text.`);
  }
  return id;
}

module.exports = {
  normalizeEmail,
  normalizeOptionalId,
  normalizeText,
};
