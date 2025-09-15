const express = require("express");
const router = express.Router();
const auth = require("../middleware/auth");
const {
  createInquiry,
  getUserInquiries,
  getAllInquiries,
  replyToInquiry,
  markInquiryAsRead,
  markInquiryAsReadByAdmin,
  getInquiryStats,
} = require("../controllers/inquiryController");

// All routes require authentication
router.use(auth);

// User routes
router.post("/", createInquiry); // Create new inquiry
router.get("/user", getUserInquiries); // Get user's own inquiries
router.patch("/:inquiryId/read", markInquiryAsRead); // Mark inquiry as read by user

// Admin/Editor routes
router.get("/all", getAllInquiries); // Get all inquiries (admin/editor only)
router.post("/:inquiryId/reply", replyToInquiry); // Reply to inquiry (admin/editor only)
router.patch("/:inquiryId/read-admin", markInquiryAsReadByAdmin); // Mark as read by admin
router.get("/stats", getInquiryStats); // Get inquiry statistics

module.exports = router;
