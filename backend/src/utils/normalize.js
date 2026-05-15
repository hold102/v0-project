// normalize.js — Shared input-normalization helpers
const { RequestError } = require("../models/requestError");

function normalizeText(value) {
  return typeof value === "string" ? value.trim() : "";
}

function normalizeEmail(value) {
  return typeof value === "string" ? value.trim().toLocaleLowerCase() : "";
}

// Returns undefined when value is undefined (caller generates the id), throws for empty strings.
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
