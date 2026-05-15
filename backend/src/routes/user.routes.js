const router = require('express').Router();
const { updateProfile, updatePreferences, changePassword, deleteAccount, getPublicProfile } = require('../controllers/user.controller');
const { protect } = require('../middleware/auth.middleware');
const { profileRules } = require('../middleware/validate.middleware');

router.put('/profile', protect, profileRules, updateProfile);
router.put('/preferences', protect, updatePreferences);
router.put('/change-password', protect, changePassword);
router.delete('/account', protect, deleteAccount);
router.get('/:username', getPublicProfile);

module.exports = router;
