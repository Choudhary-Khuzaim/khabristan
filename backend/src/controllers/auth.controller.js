const crypto = require('crypto');
const User = require('../models/User.model');
const { sendEmail } = require('../utils/email');

// ============================================
// @desc    Register new user
// @route   POST /api/v1/auth/signup
// @access  Public
// ============================================
const signup = async (req, res) => {
  try {
    const { name, email, username, password } = req.body;

    // Check if user already exists
    const existingUser = await User.findOne({
      $or: [{ email }, { username }],
    });

    if (existingUser) {
      const field = existingUser.email === email ? 'email' : 'username';
      return res.status(400).json({
        success: false,
        message: `This ${field} is already registered`,
      });
    }

    // Create user
    const user = await User.create({
      name,
      email,
      username,
      password,
    });

    // Generate token and respond
    const token = user.getSignedToken();

    res.status(201).json({
      success: true,
      message: 'Account created successfully',
      data: {
        token,
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          username: user.username,
          role: user.role,
          avatar: user.avatar,
          isVerified: user.isVerified,
          preferredRegion: user.preferredRegion,
        },
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error during registration',
      error: error.message,
    });
  }
};

// ============================================
// @desc    Login user
// @route   POST /api/v1/auth/login
// @access  Public
// ============================================
const login = async (req, res) => {
  try {
    const { username, password } = req.body;

    // Find user by username or email (allow both)
    const user = await User.findOne({
      $or: [{ username }, { email: username }],
    }).select('+password');

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    // Check password
    const isMatch = await user.matchPassword(password);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    // Generate token
    const token = user.getSignedToken();

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        token,
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          username: user.username,
          role: user.role,
          bio: user.bio,
          phone: user.phone,
          location: user.location,
          avatar: user.avatar,
          isVerified: user.isVerified,
          preferredRegion: user.preferredRegion,
          notificationsEnabled: user.notificationsEnabled,
          darkMode: user.darkMode,
        },
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error during login',
      error: error.message,
    });
  }
};

// ============================================
// @desc    Get current logged-in user
// @route   GET /api/v1/auth/me
// @access  Private
// ============================================
const getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);

    res.json({
      success: true,
      data: {
        id: user._id,
        name: user.name,
        email: user.email,
        username: user.username,
        role: user.role,
        bio: user.bio,
        phone: user.phone,
        location: user.location,
        avatar: user.avatar,
        isVerified: user.isVerified,
        preferredRegion: user.preferredRegion,
        notificationsEnabled: user.notificationsEnabled,
        darkMode: user.darkMode,
        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching profile',
      error: error.message,
    });
  }
};

// ============================================
// @desc    Forgot password
// @route   POST /api/v1/auth/forgot-password
// @access  Public
// ============================================
const forgotPassword = async (req, res) => {
  try {
    const user = await User.findOne({ email: req.body.email });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'No account found with this email',
      });
    }

    // Generate reset token
    const resetToken = user.getResetPasswordToken();
    await user.save({ validateBeforeSave: false });

    // Create reset URL
    const resetUrl = `${process.env.FRONTEND_URL}/reset-password/${resetToken}`;

    const emailContent = `
      <h2>Password Reset - KhabarIsTan</h2>
      <p>You requested a password reset. Click the link below to reset your password:</p>
      <a href="${resetUrl}" style="
        display: inline-block;
        padding: 12px 24px;
        background-color: #0F172A;
        color: #FFD700;
        text-decoration: none;
        border-radius: 8px;
        font-weight: bold;
      ">Reset Password</a>
      <p>This link expires in 30 minutes.</p>
      <p>If you didn't request this, please ignore this email.</p>
    `;

    try {
      await sendEmail({
        to: user.email,
        subject: 'KhabarIsTan - Password Reset',
        html: emailContent,
      });

      res.json({
        success: true,
        message: 'Password reset link sent to your email',
      });
    } catch (emailError) {
      user.resetPasswordToken = undefined;
      user.resetPasswordExpire = undefined;
      await user.save({ validateBeforeSave: false });

      // Even if email fails, return success in development for testing
      if (process.env.NODE_ENV === 'development') {
        return res.json({
          success: true,
          message: 'Password reset link sent (dev mode — email might not deliver)',
          devToken: resetToken,
        });
      }

      return res.status(500).json({
        success: false,
        message: 'Email could not be sent',
      });
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error processing forgot password',
      error: error.message,
    });
  }
};

// ============================================
// @desc    Reset password
// @route   PUT /api/v1/auth/reset-password/:resetToken
// @access  Public
// ============================================
const resetPassword = async (req, res) => {
  try {
    // Hash the token from URL
    const resetPasswordToken = crypto
      .createHash('sha256')
      .update(req.params.resetToken)
      .digest('hex');

    const user = await User.findOne({
      resetPasswordToken,
      resetPasswordExpire: { $gt: Date.now() },
    });

    if (!user) {
      return res.status(400).json({
        success: false,
        message: 'Invalid or expired reset token',
      });
    }

    // Set new password
    user.password = req.body.password;
    user.resetPasswordToken = undefined;
    user.resetPasswordExpire = undefined;
    await user.save();

    // Auto-login after reset
    const token = user.getSignedToken();

    res.json({
      success: true,
      message: 'Password reset successful',
      data: { token },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error resetting password',
      error: error.message,
    });
  }
};

// ============================================
// @desc    Logout (client-side — just acknowledge)
// @route   POST /api/v1/auth/logout
// @access  Private
// ============================================
const logout = async (req, res) => {
  res.json({
    success: true,
    message: 'Logged out successfully',
  });
};

module.exports = {
  signup,
  login,
  getMe,
  forgotPassword,
  resetPassword,
  logout,
};
