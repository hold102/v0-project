/*
 * requestError.js — Custom error class for HTTP error responses
 * Throw a RequestError in a service to return a specific HTTP status code
 * and message to the client. The errorHandler middleware catches it.
 *
 * Example: throw new RequestError("User not found.", 404);
 */
class RequestError extends Error {
  constructor(message, statusCode, code) {
    super(message);
    this.name = "RequestError";
    this.statusCode = statusCode || 400;
    this.code = code || null;  // machine-readable code for client error handling
  }
}

module.exports = {
  RequestError,
};
