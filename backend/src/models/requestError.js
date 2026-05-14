/*
 * requestError.js — Custom error class for HTTP error responses
 * Throw a RequestError in a service to return a specific HTTP status code
 * and message to the client. The errorHandler middleware catches it.
 *
 * Example: throw new RequestError("User not found.", 404);
 */
class RequestError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.name = "RequestError";
    // Default to 400 (Bad Request) for validation-type errors
    this.statusCode = statusCode || 400;
  }
}

module.exports = {
  RequestError,
};
