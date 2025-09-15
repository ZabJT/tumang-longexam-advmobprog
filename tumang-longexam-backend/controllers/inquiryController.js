const Inquiry = require("../models/Inquiry");
const Item = require("../models/Item");
const User = require("../models/User");

// Create a new inquiry (User only)
const createInquiry = async (req, res) => {
  try {
    const { itemId, userMessage } = req.body;
    const userId = req.user.id; // From JWT token

    // Validate required fields
    if (!itemId || !userMessage) {
      return res.status(400).json({
        message: "Item ID and message are required",
      });
    }

    // Check if item exists
    const item = await Item.findById(itemId);
    if (!item) {
      return res.status(404).json({ message: "Item not found" });
    }

    // Get user information
    const user = await User.findById(userId).select("firstName lastName");
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    // Check if user already has a pending inquiry for this item
    const existingInquiry = await Inquiry.findOne({
      userId: userId,
      itemId: itemId,
      status: "pending",
    });

    if (existingInquiry) {
      return res.status(400).json({
        message: "You already have a pending inquiry for this item",
      });
    }

    // Create new inquiry
    const inquiry = new Inquiry({
      itemId: itemId,
      itemName: item.name,
      itemPhotoUrl: item.photoUrl,
      userId: userId,
      userName: `${user.firstName} ${user.lastName}`,
      userMessage: userMessage,
      status: "pending",
    });

    await inquiry.save();

    // Populate the inquiry with item and user details
    await inquiry.populate([
      { path: "itemId", select: "name photoUrl" },
      { path: "userId", select: "firstName lastName email" },
    ]);

    res.status(201).json({
      message: "Inquiry created successfully",
      inquiry: inquiry,
    });
  } catch (error) {
    console.error("Create inquiry error:", error);
    res.status(500).json({ message: error.message });
  }
};

// Get user's inquiries (User only)
const getUserInquiries = async (req, res) => {
  try {
    const userId = req.user.id; // From JWT token
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const inquiries = await Inquiry.find({ userId: userId })
      .populate("itemId", "name photoUrl")
      .populate("userId", "firstName lastName email")
      .populate("repliedBy", "firstName lastName")
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await Inquiry.countDocuments({ userId: userId });

    res.json({
      message: "User inquiries retrieved successfully",
      inquiries: inquiries,
      total,
      page,
      totalPages: Math.ceil(total / limit),
      hasNextPage: page < Math.ceil(total / limit),
      hasPrevPage: page > 1,
    });
  } catch (error) {
    console.error("Get user inquiries error:", error);
    res.status(500).json({ message: error.message });
  }
};

// Get all inquiries (Admin/Editor only)
const getAllInquiries = async (req, res) => {
  try {
    const userType = req.user.type;

    // Check if user is admin or editor
    if (userType !== "admin" && userType !== "editor") {
      return res.status(403).json({
        message: "Access denied. Admin or Editor role required.",
      });
    }

    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const inquiries = await Inquiry.find()
      .populate("itemId", "name photoUrl")
      .populate("userId", "firstName lastName email")
      .populate("repliedBy", "firstName lastName")
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await Inquiry.countDocuments();

    res.json({
      message: "All inquiries retrieved successfully",
      inquiries: inquiries,
      total,
      page,
      totalPages: Math.ceil(total / limit),
      hasNextPage: page < Math.ceil(total / limit),
      hasPrevPage: page > 1,
    });
  } catch (error) {
    console.error("Get all inquiries error:", error);
    res.status(500).json({ message: error.message });
  }
};

// Reply to inquiry (Admin/Editor only)
const replyToInquiry = async (req, res) => {
  try {
    const { inquiryId } = req.params;
    const { adminReply, status } = req.body;
    const repliedBy = req.user.id; // From JWT token
    const userType = req.user.type;

    // Check if user is admin or editor
    if (userType !== "admin" && userType !== "editor") {
      return res.status(403).json({
        message: "Access denied. Admin or Editor role required.",
      });
    }

    // Validate required fields
    if (!adminReply || !status) {
      return res.status(400).json({
        message: "Admin reply and status are required",
      });
    }

    // Validate status
    if (!["approved", "rejected"].includes(status)) {
      return res.status(400).json({
        message: "Status must be either 'approved' or 'rejected'",
      });
    }

    // Find the inquiry
    const inquiry = await Inquiry.findById(inquiryId);
    if (!inquiry) {
      return res.status(404).json({ message: "Inquiry not found" });
    }

    // Check if inquiry is still pending
    if (inquiry.status !== "pending") {
      return res.status(400).json({
        message: "This inquiry has already been replied to",
      });
    }

    // Update the inquiry with admin reply
    inquiry.adminReply = adminReply;
    inquiry.status = status;
    inquiry.repliedBy = repliedBy;
    inquiry.repliedAt = new Date();
    inquiry.isReadByAdmin = true;

    await inquiry.save();

    // Populate the updated inquiry
    await inquiry.populate([
      { path: "itemId", select: "name photoUrl" },
      { path: "userId", select: "firstName lastName email" },
      { path: "repliedBy", select: "firstName lastName" },
    ]);

    res.json({
      message: "Reply sent successfully",
      inquiry: inquiry,
    });
  } catch (error) {
    console.error("Reply to inquiry error:", error);
    res.status(500).json({ message: error.message });
  }
};

// Mark inquiry as read (User only)
const markInquiryAsRead = async (req, res) => {
  try {
    const { inquiryId } = req.params;
    const userId = req.user.id;

    const inquiry = await Inquiry.findOne({
      _id: inquiryId,
      userId: userId,
    });

    if (!inquiry) {
      return res.status(404).json({ message: "Inquiry not found" });
    }

    inquiry.isRead = true;
    await inquiry.save();

    res.json({
      message: "Inquiry marked as read",
      inquiry: inquiry,
    });
  } catch (error) {
    console.error("Mark inquiry as read error:", error);
    res.status(500).json({ message: error.message });
  }
};

// Mark inquiry as read by admin (Admin/Editor only)
const markInquiryAsReadByAdmin = async (req, res) => {
  try {
    const { inquiryId } = req.params;
    const userType = req.user.type;

    // Check if user is admin or editor
    if (userType !== "admin" && userType !== "editor") {
      return res.status(403).json({
        message: "Access denied. Admin or Editor role required.",
      });
    }

    const inquiry = await Inquiry.findById(inquiryId);
    if (!inquiry) {
      return res.status(404).json({ message: "Inquiry not found" });
    }

    inquiry.isReadByAdmin = true;
    await inquiry.save();

    res.json({
      message: "Inquiry marked as read by admin",
      inquiry: inquiry,
    });
  } catch (error) {
    console.error("Mark inquiry as read by admin error:", error);
    res.status(500).json({ message: error.message });
  }
};

// Get inquiry statistics (Admin/Editor only)
const getInquiryStats = async (req, res) => {
  try {
    const userType = req.user.type;

    // Check if user is admin or editor
    if (userType !== "admin" && userType !== "editor") {
      return res.status(403).json({
        message: "Access denied. Admin or Editor role required.",
      });
    }

    const stats = await Inquiry.aggregate([
      {
        $group: {
          _id: "$status",
          count: { $sum: 1 },
        },
      },
    ]);

    const totalInquiries = await Inquiry.countDocuments();
    const unreadByAdmin = await Inquiry.countDocuments({
      isReadByAdmin: false,
    });

    res.json({
      message: "Inquiry statistics retrieved successfully",
      stats: {
        total: totalInquiries,
        unreadByAdmin: unreadByAdmin,
        byStatus: stats,
      },
    });
  } catch (error) {
    console.error("Get inquiry stats error:", error);
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  createInquiry,
  getUserInquiries,
  getAllInquiries,
  replyToInquiry,
  markInquiryAsRead,
  markInquiryAsReadByAdmin,
  getInquiryStats,
};
