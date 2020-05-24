"use strict";
const fs = require("fs-extra");
const util = require("util");
const path = require("path");
const child_process = require("child_process");
const streamZip = require("node-stream-zip");

exports.index = (req, res, next) => {
  res.render("home/index", {
    title: "CoE 113 Laboratory",
  });
};

exports.showlab4checker = (req, res, next) => {
  res.render("home/lab4checker", {
    title: "CoE 113 ME4 checker",
    results: null,
  });
};

exports.lab4checker = async (req, res, next) => {
  // console.log(req.file);

  const uploadsDirPath = path.join(__dirname, "..", "uploads");

  try {
    const renameToOriginalFileName = util.promisify(fs.rename);
    const oldPath = path.join(__dirname, "..", req.file.path);
    const newPath = path.join(uploadsDirPath, req.file.originalname);

    await renameToOriginalFileName(oldPath, newPath);
  } catch (err) {
    console.log(err);
  }

  try {
    const createNewDirectory = util.promisify(fs.mkdir);
    const pathName = path.join(__dirname, "..", "uploads", req.file.filename);
    const options = { recursive: true };

    await createNewDirectory(pathName, options);
  } catch (err) {
    console.log(err);
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
      console.log(err);
    });

    const topLevelMipsVerilogFile = path.join("rtl", "single_cycle_mips.v");
    const RTLDirInZipFile = "rtl/";
    let hasRTLDirInZipFile = false;
    let hasTopLevelMipsVerilogFile = false;

    zip.on("ready", () => {
      // console.log(`Entries read: ${zip.entriesCount}`);

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
        // console.log(`Entry ${entry.name}: ${desc}`);
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
          // console.log(err ? "Extract error" : `Extracted ${count} entries`);
          zip.close();

          const removeZipFile = util.promisify(fs.unlink);
          const rtlDir = path.join(newUploadDirPath, "rtl");

          try {
            await removeZipFile(newZipFilePath);
          } catch (err) {
            console.log(err);
          }

          try {
            await copyLab4CheckerToNewRTLDir(rtlDir);
          } catch (err) {
            console.log(err);
          }

          runLab4Checker(rtlDir)
            .then((checkerResponse) => {
              console.log(checkerResponse);

              const result = checkerResponse.stdout
                .split("\n")
                .filter((line) => line.length)
                .map((line) => line.split(" "))
                .map((line) => {
                  const grade = line[2].split("/").map((e) => parseInt(e));

                  return {
                    inst: line[0],
                    passed: line[1] === "PASSED" ? true : false,
                    score: grade[0],
                    test_length: grade[1],
                  };
                });

              // remove created directory inside uploads after simulation run
              const removeSimulationDirectory = util.promisify(fs.rmdir);
              const simulationPathDirectory = newUploadDirPath;
              const options = { recursive: true };
              removeSimulationDirectory(simulationPathDirectory, options)
                .then(() => {
                  res.render("home/lab4checker", {
                    title: "CoE113 ME4 checker",
                    results: result,
                  });
                })
                .catch((error) => console.log(error));
            })
            .catch((err) => {
              console.log(err);
            });
        });
      }
    });
  } catch (err) {
    console.log(err);
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
    console.log(err);
  }
}

async function copyLab4CheckerToNewRTLDir(dirPath) {
  const checkerPath = path.join(__dirname, "..", "checkers", "me4");

  try {
    await fs.copy(checkerPath, dirPath);
  } catch (err) {
    console.log(err);
  }
}

async function runLab4Checker(dirPath) {
  const cwd = path.join(dirPath);
  const simulationTimeout = 3;
  const options = { cwd: cwd, timeout: simulationTimeout };

  const runPythonChecker = util.promisify(child_process.execFile);
  return runPythonChecker("python3", ["run.py"], options);
}
