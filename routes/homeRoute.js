const express = require("express");
const router = express.Router();
const multer = require("multer");
const upload = multer({ dest: "uploads/" });

const homeController = require("../controllers/homeController.js");

/* GET home page. */
router.get("/", homeController.index);
router.get("/lab4checker", homeController.showlab4checker);
router.post(
    "/lab4checker",
    upload.single("rtlFile"),
    homeController.lab4checker
);
router.get("/lab5checker", homeController.showlab5checker);
router.post(
    "/lab5checker",
    upload.single("rtlFile"),
    homeController.lab5checker
);

module.exports = router;
