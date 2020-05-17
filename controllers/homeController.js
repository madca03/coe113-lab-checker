"use strict";
const fs = require("fs-extra");
const util = require("util");
const path = require("path");
const { exec } = require("child_process");
const streamZip = require("node-stream-zip");

exports.index = (req, res, next) => {
  res.render("home/index", {
    title: "CoE113 Laboratory",
  });
};

exports.showlab4checker = (req, res, next) => {
  res.render("home/lab4checker", {
    title: "CoE113 ME4 checker",
  });
};

exports.lab4checker = async (req, res, next) => {
  console.log(req.file);

  const uploadsDirPath = path.join(__dirname, "..", "uploads");

  try {
    const renameToOriginalFileName = util.promisify(fs.rename);
    const oldPath = path.join(__dirname, "..", req.file.path);
    const newPath = path.join(uploadsDirPath, req.file.originalname);

    await renameToOriginalFileName(oldPath, newPath);
  } catch (err) {
    throw err;
  }

  try {
    const createNewDirectory = util.promisify(fs.mkdir);
    const pathName = path.join(__dirname, "..", "uploads", req.file.filename);
    const options = { recursive: true };

    await createNewDirectory(pathName, options);
  } catch (err) {
    throw err;
  }

  try {
    const moveRTLFileToNewDirectory = util.promisify(fs.rename);
    const newUploadDirPath = path.join(uploadsDirPath, req.file.filename);
    const oldZipFilePath = path.join(uploadsDirPath, req.file.originalname);
    const newZipFilePath = path.join(newUploadDirPath, req.file.originalname);

    await moveRTLFileToNewDirectory(oldZipFilePath, newZipFilePath);

    const zip = new streamZip({
      file: newZipFilePath,
      storeEntries: true,
    });

    zip.on("error", (err) => {
      throw err;
    });

    const topLevelMipsVerilogFile = path.join("rtl", "single_cycle_mips.v");
    const RTLDirInZipFile = "rtl/";
    let hasRTLDirInZipFile = false;
    let hasTopLevelMipsVerilogFile = false;

    zip.on("ready", () => {
      console.log(`Entries read: ${zip.entriesCount}`);

      // read the contents of the zip file before extraction
      for (const entry of Object.values(zip.entries())) {
        // check for the existence of the "rtl" directory in the extracted zip file
        if (entry.isDirectory && entry.name === RTLDirInZipFile) {
          hasRTLDirInZipFile = true;
        }

        // check for the existence of the top level verilog file in the extracted zip file
        if (!entry.isDirectory && entry.name === topLevelMipsVerilogFile) {
          hasTopLevelMipsVerilogFile = true;
        }

        const desc = entry.isDirectory ? "directory" : `${entry.size} bytes`;
        console.log(`Entry ${entry.name}: ${desc}`);
      }

      if (!hasRTLDirInZipFile) {
        deleteNewUploadDir(newUploadDirPath);
        res.json({ status: "rtl folder was not found in your zip file " });
      }

      if (!hasTopLevelMipsVerilogFile) {
        deleteNewUploadDir(newUploadDirPath);
        res.json({
          status: `${topLevelMipsVerilogFile} was not found in your zip file`,
        });
      }

      // extract zip file if it's valid
      if (hasRTLDirInZipFile && hasTopLevelMipsVerilogFile) {
        zip.extract(null, newUploadDirPath, async (err, count) => {
          console.log(err ? "Extract error" : `Extracted ${count} entries`);
          zip.close();

          const removeZipFile = util.promisify(fs.unlink);

          try {
            await removeZipFile(newZipFilePath);
          } catch (err) {
            throw err;
          }

          copyLab4CheckerToNewRTLDir(newUploadDirPath);
          runLab4Checker(newUploadDirPath);

          res.json({ fields: req.file });
        });
      }
    });
  } catch (err) {
    throw err;
  }
};

exports.showlab5checker = (req, res, next) => {
  res.render("home/lab5checker", {
    title: "CoE113 ME5 checker",
  });
};

async function deleteNewUploadDir(dirPath) {
  const rmdir = util.promisify(fs.rmdir);

  try {
    await rmdir(dirPath, { recursive: true });
  } catch (err) {
    throw err;
  }
}

async function copyLab4CheckerToNewRTLDir(dirPath) {
  const checkerPath = path.join(__dirname, "..", "checkers", "me4");

  try {
    await fs.copy(checkerPath, dirPath);
  } catch (err) {
    throw err;
  }
}

function runLab4Checker(dirPath) {
  const cwd = path.join(dirPath, "sim");
  console.log(cwd);

  const command = "python run.py";
  const options = { cwd: cwd };

  exec(command, options, (err, stdout, stderr) => {
    if (err) {
      console.log(err);
      return;
    }
    console.log(`stdout: ${stdout}`);
    console.log(`stderr: ${stderr}`);
  });
}
