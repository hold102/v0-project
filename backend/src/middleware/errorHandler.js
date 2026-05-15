/*
 * errorHandler.js — Express error-handling middleware
 *
 * notFound: Catches requests that didn't match any route and returns a 404.
 * errorHandler: Central error handler. Returns user-friendly messages for
 *   known errors (RequestError) and hides internal details for 500s.
 */
function notFound(_req, res) {
  res.status(404).json({ error: "Route not found." });
}

function errorHandler(error, _req, res, _next) {
  // JSON parse errors (malformed request body)
  if (error instanceof SyntaxError && error.status === 400 && "body" in error) {
    return res.status(400).json({ error: "Invalid JSON body." });
  }

  // Extract a numeric status code from the error object, or default to 500
  const status = error.statusCode || error.status || 500;
  if (status >= 500) {
    console.error(error);  // Log server errors for debugging
  }

  const body = { error: status >= 500 ? "Internal server error." : error.message };
  if (error.code) body.code = error.code;
  return res.status(status).json(body);
}

module.exports = {
  notFound,
  errorHandler,
};
