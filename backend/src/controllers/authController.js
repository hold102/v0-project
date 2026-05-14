const { login: loginService, register: registerService } = require("../services/authService");

async function register(req, res, next) {
  try {
    const result = await registerService(req.body);
    res.status(201).json(result);
  } catch (error) {
    next(error);
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
