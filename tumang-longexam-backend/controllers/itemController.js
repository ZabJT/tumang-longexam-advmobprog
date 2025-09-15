const Item = require("../models/Item");
const User = require("../models/User");

const getItems = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    // Check if we should filter for active/inactive items
    const activeOnly = req.query.active === "true";
    const inactiveOnly = req.query.inactive === "true";

    // Get sorting options from query parameters
    const sortBy = req.query.sortBy || "createdAt"; // Default to createdAt
    const sortOrder = req.query.sortOrder || "desc"; // Default to descending (latest first)

    // Get search parameter
    const searchQuery = req.query.search || "";

    // If requesting inactive items, require authentication and admin/editor role
    if (inactiveOnly) {
      // Check if user is authenticated (req.user should be set by auth middleware)
      if (!req.user) {
        return res.status(401).json({
          message: "Authentication required to access archived items",
        });
      }

      // Check if user is admin or editor
      const userType = req.user.type;
      if (userType !== "admin" && userType !== "editor") {
        return res.status(403).json({
          message:
            "Access denied. Admin or Editor role required to view archived items.",
        });
      }
    }

    let query = {};
    if (activeOnly) {
      query = { isActive: true };
    } else if (inactiveOnly) {
      query = { isActive: false };
    }

    // Add search functionality
    if (searchQuery && searchQuery.trim() !== "") {
      const searchRegex = new RegExp(searchQuery.trim(), "i"); // Case-insensitive search
      query.$or = [
        { name: searchRegex },
        { description: { $in: [searchRegex] } },
      ];
    }

    // Build sort object
    const sortObj = {};
    sortObj[sortBy] = sortOrder === "desc" ? -1 : 1;

    console.log("Item Query Debug:", {
      query,
      sortObj,
      page,
      limit,
      skip,
      sortBy,
      sortOrder,
    });

    const items = await Item.find(query).skip(skip).limit(limit).sort(sortObj);

    console.log("Items found:", items.length);
    if (items.length > 0) {
      console.log("First item createdAt:", items[0].createdAt);
      console.log("Last item createdAt:", items[items.length - 1].createdAt);
    }

    const total = await Item.countDocuments(query);

    res.json({
      items,
      total,
      page,
      totalPages: Math.ceil(total / limit),
      hasNextPage: page < Math.ceil(total / limit),
      hasPrevPage: page > 1,
      sortBy,
      sortOrder,
      searchQuery,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const createItem = async (req, res) => {
  try {
    const { name, description, photoUrl, qtyTotal, qtyAvailable, isActive } =
      req.body;
    if (!name) return res.status(400).json({ message: "Name is required" });
    const total = Number(qtyTotal ?? 0);
    const avail = Number(qtyAvailable ?? total);
    if (total < 0 || avail < 0)
      return res.status(400).json({ message: "Quantities must be >= 0" });
    if (avail > total)
      return res
        .status(400)
        .json({ message: "qtyAvailable cannot exceed qtyTotal" });
    const item = await Item.create({
      name,
      description: description ?? [""],
      photoUrl: photoUrl ?? "",
      qtyTotal: total,
      qtyAvailable: avail,
      isActive: isActive ?? true,
    });
    res.status(201).json(item);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

const updateItem = async (req, res) => {
  try {
    const payload = { ...req.body };
    if (payload.qtyTotal !== undefined || payload.qtyAvailable !== undefined) {
      const current = await Item.findById(req.params.id);
      if (!current) return res.status(404).json({ message: "Item not found" });
      const total = Number(payload.qtyTotal ?? current.qtyTotal);
      const avail = Number(payload.qtyAvailable ?? current.qtyAvailable);
      if (total < 0 || avail < 0)
        return res.status(400).json({ message: "Quantities must be >= 0" });
      if (avail > total)
        return res
          .status(400)
          .json({ message: "qtyAvailable cannot exceed qtyTotal" });
      payload.qtyTotal = total;
      payload.qtyAvailable = avail;
    }
    const item = await Item.findByIdAndUpdate(req.params.id, payload, {
      new: true,
    });
    if (!item) return res.status(404).json({ message: "Item not found" });
    res.json(item);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

const deleteItem = async (req, res) => {
  try {
    await Item.findByIdAndDelete(req.params.id);
    res.json({ message: "Item deleted successfully" });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

// Wishlist functionality
const addToWishlist = async (req, res) => {
  try {
    const userId = req.user.id;
    const { itemId } = req.body;

    if (!itemId) {
      return res.status(400).json({ message: "Item ID is required" });
    }

    // Check if item exists
    const item = await Item.findById(itemId);
    if (!item) {
      return res.status(404).json({ message: "Item not found" });
    }

    // Get user and add item to wishlist
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    if (!user.wishlist) {
      user.wishlist = [];
    }

    // Check if item is already in wishlist
    if (user.wishlist.includes(itemId)) {
      return res.status(400).json({ message: "Item already in wishlist" });
    }

    user.wishlist.push(itemId);
    await user.save();

    res.json({
      message: "Item added to wishlist successfully",
      wishlist: user.wishlist,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const removeFromWishlist = async (req, res) => {
  try {
    const userId = req.user.id;
    const { itemId } = req.body;

    if (!itemId) {
      return res.status(400).json({ message: "Item ID is required" });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    if (!user.wishlist) {
      user.wishlist = [];
    }

    // Remove item from wishlist
    user.wishlist = user.wishlist.filter((id) => id.toString() !== itemId);
    await user.save();

    res.json({
      message: "Item removed from wishlist successfully",
      wishlist: user.wishlist,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getWishlist = async (req, res) => {
  try {
    const userId = req.user.id;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    // First get the total count
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    const total = user.wishlist ? user.wishlist.length : 0;

    // Then get the paginated wishlist items
    const userWithWishlist = await User.findById(userId).populate({
      path: "wishlist",
      options: {
        skip: skip,
        limit: limit,
        sort: { createdAt: -1 },
      },
    });

    const wishlistItems = userWithWishlist.wishlist || [];

    res.json({
      message: "Wishlist retrieved successfully",
      data: wishlistItems,
      total,
      page,
      totalPages: Math.ceil(total / limit),
      hasNextPage: page < Math.ceil(total / limit),
      hasPrevPage: page > 1,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  getItems,
  createItem,
  updateItem,
  deleteItem,
  addToWishlist,
  removeFromWishlist,
  getWishlist,
};
