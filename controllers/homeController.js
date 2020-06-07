"use strict";
const fs = require("fs-extra");
const util = require("util");
const path = require("path");
const child_process = require("child_process");
const streamZip = require("node-stream-zip");
const me4PythonCheckerConstants = require("../constants/me4PythonCheckerConstants.js");
const me5PythonCheckerConstants = require("../constants/me5PythonCheckerConstants.js");
const renderConstants = require("../constants/renderConstants.js");

exports.index = (req, res, next) => {
    res.render("home/index", {
        title: renderConstants.HOME.PAGE_TITLE,
        description: renderConstants.HOME.PAGE_DESCRIPTION
    });
};

exports.showlab4checker = (req, res, next) => {
    res.render("home/lab4checker", {
        title: renderConstants.ME4.PAGE_TITLE,
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

            if (zip.entriesCount === 1) 
            {
                const entry = Object.values(zip.entries())[0]
                hasRTLDirInZipFile = entry.name.includes("rtl/");
                hasTopLevelMipsVerilogFile = entry.name.includes(topLevelMipsVerilogFile);
            } 
            else 
            {
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

                    // const desc = entry.isDirectory ? "directory" : `${entry.size} bytes`;
                    // console.log(`Entry ${entry.name}: ${desc}`);
                }
            }

           
            if (!hasRTLDirInZipFile || !hasTopLevelMipsVerilogFile) {
                deleteNewUploadDir(newUploadDirPath);
            }

            if (!hasRTLDirInZipFile) {
                res.render("home/lab4checkerResultError", {
                    title: renderConstants.ME4.PAGE_TITLE,
                    errorMessageTitle: renderConstants.ME4.MISSING_RTL_FOLDER,
                });
            } else if (!hasTopLevelMipsVerilogFile) {
                res.render("home/lab4checkerResultError", {
                    title: renderConstants.ME4.PAGE_TITLE,
                    errorMessageTitle: renderConstants.ME4.MISSING_TOP_LEVEL_MODULE,
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
                            const result = checkerResponse.stdout
                                .split("\n")
                                .filter((instructionResult) => instructionResult.length)
                                .map((instructionResult) => instructionResult.split(" "))
                                .map((instructionResult) => {
                                    const grade = instructionResult[2]
                                        .split("/")
                                        .map((e) => parseInt(e));

                                    return {
                                        inst: instructionResult[0],
                                        passed: instructionResult[1] === "PASSED" ? true : false,
                                        score: grade[0],
                                        test_length: grade[1],
                                    };
                                });

                            res.render("home/lab4checkerResultSuccess", {
                                title: renderConstants.ME4.PAGE_TITLE,
                                results: result,
                            });
                        })
                        .catch((error) => {
                            let errorMessage = null;
                            let errorMessageTitle = null;

                            if (
                                error.code ===
                                me4PythonCheckerConstants.STATUS
                                    .IVERILOG_PROCESS_COMPILATION_ERROR
                            ) {
                                errorMessage = error.stderr.split("\n").filter((x) => x.length);
                                errorMessageTitle = renderConstants.ME4.COMPILE_ERROR;
                            } else if (
                                error.code ===
                                me4PythonCheckerConstants.STATUS.VVP_PROCESS_TIMEOUT
                            ) {
                                errorMessage = error.stderr;
                                errorMessageTitle = renderConstants.ME4.SIMULATION_TIMEOUT;
                            }

                            res.render("home/lab4checkerResultError", {
                                title: renderConstants.ME4_TITLE,
                                errorMessageTitle,
                                errorMessage,
                            });
                        })
                        .finally(() => {
                            const removeSimulationDirectory = util.promisify(fs.rmdir);
                            const simulationPathDirectory = newUploadDirPath;
                            const options = { recursive: true };
                            removeSimulationDirectory(
                                simulationPathDirectory,
                                options
                            ).catch((error) => console.log(error));
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
        title: renderConstants.ME5.PAGE_TITLE,
        results: null,
    });
};

exports.lab5checker = async (req, res, next) => {
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

        const topLevelMipsVerilogFile = path.join("rtl", "pipelined_mips.v");
        const RTLDirInZipFile = "rtl/";
        let hasRTLDirInZipFile = false;
        let hasTopLevelMipsVerilogFile = false;

        zip.on("ready", () => {
            // console.log(`Entries read: ${zip.entriesCount}`);

            if (zip.entriesCount === 1) 
            {
                const entry = Object.values(zip.entries())[0].name.split("/")
                hasRTLDirInZipFile = entry.name.includes("rtl/");
                hasTopLevelMipsVerilogFile = entry.name.includes(topLevelMipsVerilogFile);
            }
            else
            {
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

                    // const desc = entry.isDirectory ? "directory" : `${entry.size} bytes`;
                    // console.log(`Entry ${entry.name}: ${desc}`);
                }
            }

            if (!hasRTLDirInZipFile || !hasTopLevelMipsVerilogFile) {
                deleteNewUploadDir(newUploadDirPath);
            }

            if (!hasRTLDirInZipFile) {
                res.render("home/lab5checkerResultError", {
                    title: renderConstants.ME5.PAGE_TITLE,
                    errorMessageTitle: renderConstants.ME5.MISSING_RTL_FOLDER,
                });
            } else if (!hasTopLevelMipsVerilogFile) {
                res.render("home/lab5checkerResultError", {
                    title: renderConstants.ME5.PAGE_TITLE,
                    errorMessageTitle: renderConstants.ME5.MISSING_TOP_LEVEL_MODULE,
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
                        await copyLab5CheckerToNewRTLDir(rtlDir);
                    } catch (err) {
                        console.log(err);
                    }

                    runLab5Checker(rtlDir)
                        .then((checkerResponse) => {
                            const result = checkerResponse.stdout
                                .split("\n")
                                .filter((instructionResult) => instructionResult.length)
                                .map((instructionResult) => instructionResult.split(" "))
                                .map((instructionResult) => {
                                    const grade = instructionResult[2]
                                        .split("/")
                                        .map((e) => parseInt(e));

                                    return {
                                        inst: instructionResult[0],
                                        passed: instructionResult[1] === "PASSED" ? true : false,
                                        score: grade[0],
                                        test_length: grade[1],
                                    };
                                });

                            res.render("home/lab5checkerResultSuccess", {
                                title: renderConstants.ME5.PAGE_TITLE,
                                results: result,
                            });
                        })
                        .catch((error) => {
                            let errorMessage = null;
                            let errorMessageTitle = null;

                            if (
                                error.code ===
                                me5PythonCheckerConstants.STATUS
                                    .IVERILOG_PROCESS_COMPILATION_ERROR
                            ) {
                                errorMessage = error.stderr.split("\n").filter((x) => x.length);
                                errorMessageTitle = renderConstants.ME5.COMPILE_ERROR;
                            } else if (
                                error.code ===
                                me5PythonCheckerConstants.STATUS.VVP_PROCESS_TIMEOUT
                            ) {
                                errorMessage = error.stderr;
                                errorMessageTitle = renderConstants.ME5.SIMULATION_TIMEOUT;
                            }

                            res.render("home/lab5checkerResultError", {
                                title: renderConstants.ME5_TITLE,
                                errorMessageTitle,
                                errorMessage,
                            });
                        })
                        .finally(() => {
                            const removeSimulationDirectory = util.promisify(fs.rmdir);
                            const simulationPathDirectory = newUploadDirPath;
                            const options = { recursive: true };
                            removeSimulationDirectory(
                                simulationPathDirectory,
                                options
                            ).catch((error) => console.log(error));
                        });
                });
            }
        });
    } catch (err) {
        console.log(err);
    }
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
    const copyFileFunc = util.promisify(fs.copyFile);

    const copyFileOperations = me4PythonCheckerConstants.FILES_USED_FOR_CHECKING.map(
        (file) => {
            copyFileFunc(path.join(checkerPath, file), path.join(dirPath, file));
        }
    );

    try {
        await Promise.all(copyFileOperations);
    } catch (err) {
        console.log(err);
    }
}

async function runLab4Checker(dirPath) {
    const cwd = path.join(dirPath);
    const options = { cwd: cwd };

    const runPythonChecker = util.promisify(child_process.execFile);
    return runPythonChecker("python3", ["run.py"], options);
}

async function copyLab5CheckerToNewRTLDir(dirPath) {
    const checkerPath = path.join(__dirname, "..", "checkers", "me5");
    const copyFileFunc = util.promisify(fs.copyFile);

    const copyFileOperations = me5PythonCheckerConstants.FILES_USED_FOR_CHECKING.map(
        (file) => {
            copyFileFunc(path.join(checkerPath, file), path.join(dirPath, file));
        }
    );

    try {
        await Promise.all(copyFileOperations);
    } catch (err) {
        console.log(err);
    }
}

async function runLab5Checker(dirPath) {
    const cwd = path.join(dirPath);
    const options = { cwd: cwd };

    const runPythonChecker = util.promisify(child_process.execFile);
    return runPythonChecker("python3", ["run.py"], options);
}