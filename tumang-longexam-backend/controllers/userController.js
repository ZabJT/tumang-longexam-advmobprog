const User = require("../models/User");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

const getUsers = async (req, res) => {
  try {
    const users = await User.find({}, "-password");
    res.json({ users });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getCurrentUser = async (req, res) => {
  try {
    const userId = req.user.id; // From JWT token
    const user = await User.findById(userId).select("-password");

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json(user);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const createUser = async (req, res) => {
  try {
    if (!req.body.password) {
      return res.status(400).json({ message: "Password is required" });
    }

    const hashedPassword = await bcrypt.hash(req.body.password, 10);

    // Set approval status based on user type
    let approvalStatus = "approved";
    if (req.body.type === "admin" || req.body.type === "editor") {
      approvalStatus = "pending";
    }

    const user = await User.create({
      ...req.body,
      password: hashedPassword,
      approvalStatus: approvalStatus,
    });

    res.status(201).json({
      ...user.toObject(),
      message:
        approvalStatus === "pending"
          ? "Account created successfully. Please wait for admin approval."
          : "Account created successfully.",
    });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

const loginUser = async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }
    if (!user.isActive) {
      return res
        .status(403)
        .json({ message: "Your account is inactive. Please contact support." });
    }

    if (user.approvalStatus === "pending") {
      return res.status(403).json({
        message:
          "Your account is pending approval. Please wait for admin approval.",
      });
    }

    if (user.approvalStatus === "rejected") {
      return res.status(403).json({
        message: "Your account has been rejected. Please contact support.",
      });
    }
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ message: "Invalid credentials" });
    }
    const token = jwt.sign(
      { id: user._id, email: user.email, type: user.type },
      process.env.JWT_SECRET,
      { expiresIn: "1h" }
    );
    res.json({
      message: "Login successful",
      token,
      type: user.type,
      firstName: user.firstName,
      lastName: user.lastName,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const updateUser = async (req, res) => {
  try {
    const { id } = req.params;
    const user = await User.findByIdAndUpdate(id, req.body, {
      new: true,
      runValidators: true,
    }).select("-password");

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json(user);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

const getPendingUsers = async (req, res) => {
  try {
    const pendingUsers = await User.find({
      approvalStatus: "pending",
    }).select("-password");
    res.json({ users: pendingUsers });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const approveUser = async (req, res) => {
  try {
    const { id } = req.params;
    const user = await User.findByIdAndUpdate(
      id,
      { approvalStatus: "approved" },
      { new: true }
    ).select("-password");

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json({
      message: "User approved successfully",
      user: user,
    });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

const rejectUser = async (req, res) => {
  try {
    const { id } = req.params;
    const user = await User.findByIdAndUpdate(
      id,
      { approvalStatus: "rejected" },
      { new: true }
    ).select("-password");

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json({
      message: "User rejected successfully",
      user: user,
    });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

module.exports = {
  getUsers,
  getCurrentUser,
  createUser,
  loginUser,
  updateUser,
  getPendingUsers,
  approveUser,
  rejectUser,
};
