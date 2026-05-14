function notFound(_req, res) {
  res.status(404).json({ error: "Route not found." });
}

function errorHandler(error, _req, res, _next) {
  if (error instanceof SyntaxError && error.status === 400 && "body" in error) {
    return res.status(400).json({ error: "Invalid JSON body." });
  }

  const status = error.statusCode || error.status || 500;
  if (status >= 500) {
    console.error(error);
  }

  return res.status(status).json({
    error: status >= 500 ? "Internal server error." : error.message,
  });
}

module.exports = {
  notFound,
  errorHandler,
};
