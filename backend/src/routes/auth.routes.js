const router = require('express').Router();
const { signup, login, getMe, forgotPassword, resetPassword, logout } = require('../controllers/auth.controller');
const { protect } = require('../middleware/auth.middleware');
const { authLimiter } = require('../middleware/rateLimiter.middleware');
const { signupRules, loginRules, forgotPasswordRules, resetPasswordRules } = require('../middleware/validate.middleware');

router.post('/signup', authLimiter, signupRules, signup);
router.post('/login', authLimiter, loginRules, login);
router.get('/me', protect, getMe);
router.post('/forgot-password', authLimiter, forgotPasswordRules, forgotPassword);
router.put('/reset-password/:resetToken', resetPasswordRules, resetPassword);
router.post('/logout', protect, logout);

module.exports = router;
