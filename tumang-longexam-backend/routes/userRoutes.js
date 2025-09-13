const express = require("express");
const {
  getUsers,
  getCurrentUser,
  createUser,
  loginUser,
  updateUser,
  getPendingUsers,
  approveUser,
  rejectUser,
} = require("../controllers/userController");
const auth = require("../middleware/auth");

const router = express.Router();

router.route("/").get(getUsers).post(createUser);
router.route("/me").get(auth, getCurrentUser);
router.route("/:id").put(updateUser);
router.route("/pending").get(getPendingUsers);
router.route("/:id/approve").patch(approveUser);
router.route("/:id/reject").patch(rejectUser);

router.post("/login", loginUser);

module.exports = router;
