const User = require('../models/User.model');

// ============================================
// @desc    Update user profile
// @route   PUT /api/v1/users/profile
// @access  Private
// ============================================
const updateProfile = async (req, res) => {
  try {
    const allowedFields = ['name', 'bio', 'phone', 'location', 'avatar'];
    const updates = {};

    allowedFields.forEach((field) => {
      if (req.body[field] !== undefined) {
        updates[field] = req.body[field];
      }
    });

    const user = await User.findByIdAndUpdate(req.user.id, updates, {
      new: true,
      runValidators: true,
    });

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        id: user._id,
        name: user.name,
        email: user.email,
        username: user.username,
        bio: user.bio,
        phone: user.phone,
        location: user.location,
        avatar: user.avatar,
        role: user.role,
        isVerified: user.isVerified,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error updating profile',
      error: error.message,
    });
  }
};

// ============================================
// @desc    Update user preferences
// @route   PUT /api/v1/users/preferences
// @access  Private
// ============================================
const updatePreferences = async (req, res) => {
  try {
    const allowedFields = ['preferredRegion', 'notificationsEnabled', 'darkMode'];
    const updates = {};

    allowedFields.forEach((field) => {
      if (req.body[field] !== undefined) {
        updates[field] = req.body[field];
      }
    });

    const user = await User.findByIdAndUpdate(req.user.id, updates, {
      new: true,
      runValidators: true,
    });

    res.json({
      success: true,
      message: 'Preferences updated successfully',
      data: {
        preferredRegion: user.preferredRegion,
        notificationsEnabled: user.notificationsEnabled,
        darkMode: user.darkMode,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error updating preferences',
      error: error.message,
    });
  }
};

// ============================================
// @desc    Change password
// @route   PUT /api/v1/users/change-password
// @access  Private
// ============================================
const changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Please provide current and new password',
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'New password must be at least 6 characters',
      });
    }

    const user = await User.findById(req.user.id).select('+password');

    const isMatch = await user.matchPassword(currentPassword);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Current password is incorrect',
      });
    }

    user.password = newPassword;
    await user.save();

    const token = user.getSignedToken();

    res.json({
      success: true,
      message: 'Password changed successfully',
      data: { token },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error changing password',
      error: error.message,
    });
  }
};

// ============================================
// @desc    Delete user account
// @route   DELETE /api/v1/users/account
// @access  Private
// ============================================
const deleteAccount = async (req, res) => {
  try {
    await User.findByIdAndDelete(req.user.id);

    res.json({
      success: true,
      message: 'Account deleted successfully',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error deleting account',
      error: error.message,
    });
  }
};

// ============================================
// @desc    Get public user profile
// @route   GET /api/v1/users/:username
// @access  Public
// ============================================
const getPublicProfile = async (req, res) => {
  try {
    const user = await User.findOne({ username: req.params.username })
      .select('name username bio avatar role isVerified createdAt');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    res.json({
      success: true,
      data: user,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching user profile',
      error: error.message,
    });
  }
};

module.exports = {
  updateProfile,
  updatePreferences,
  changePassword,
  deleteAccount,
  getPublicProfile,
};
