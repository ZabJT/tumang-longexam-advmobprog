const express = require("express");
const {
  getItems,
  createItem,
  updateItem,
  deleteItem,
  addToWishlist,
  removeFromWishlist,
  getWishlist,
} = require("../controllers/itemController");
const auth = require("../middleware/auth");

const router = express.Router();

// Public route for active items only
router.get("/", getItems);

// Protected route for archived items (admin/editor only)
router.get("/archived", auth, getItems);

// All item management routes require authentication
router.use(auth); // All routes below require authentication
router.post("/", createItem); // Create item (admin/editor only)
router.route("/:id").put(updateItem).delete(deleteItem); // Update/Delete item (admin/editor only)

// Wishlist routes (require authentication)
router.post("/wishlist/add", addToWishlist);
router.post("/wishlist/remove", removeFromWishlist);
router.get("/wishlist", getWishlist);

module.exports = router;
