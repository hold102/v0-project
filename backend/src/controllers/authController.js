/*
 * authController.js — Thin layer between routes and auth service
 * Controllers extract data from the request and delegate to the service.
 * On success they send the response; on error they forward to the error handler.
 */
const { login: loginService, register: registerService } = require("../services/authService");

async function register(req, res, next) {
  try {
    const result = await registerService(req.body);
    res.status(201).json(result);  // 201 Created for new resources
  } catch (error) {
    next(error);  // Forward to errorHandler middleware
  }
}

async function login(req, res, next) {
  try {
    const result = await loginService(req.body);
    res.json(result);
  } catch (error) {
    next(error);
  }
}

module.exports = {
  login,
  register,
};
