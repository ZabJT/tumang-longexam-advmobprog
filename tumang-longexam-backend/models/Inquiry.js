const mongoose = require("mongoose");

const inquirySchema = new mongoose.Schema(
  {
    // Item information
    itemId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Item",
      required: true,
    },
    itemName: { type: String, required: true },
    itemPhotoUrl: { type: String, default: "" },

    // User information
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    userName: { type: String, required: true },

    // Inquiry details
    userMessage: { type: String, required: true },
    status: {
      type: String,
      enum: ["pending", "approved", "rejected"],
      default: "pending",
    },

    // Admin/Staff reply
    adminReply: {
      type: String,
      default: "",
    },
    repliedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },
    repliedAt: { type: Date },

    // Additional fields
    isRead: { type: Boolean, default: false }, // For user to mark as read
    isReadByAdmin: { type: Boolean, default: false }, // For admin to mark as read
  },
  { timestamps: true }
);

// Index for better query performance
inquirySchema.index({ userId: 1, createdAt: -1 });
inquirySchema.index({ status: 1 });
inquirySchema.index({ itemId: 1 });

module.exports =
  mongoose.models.Inquiry || mongoose.model("Inquiry", inquirySchema);
