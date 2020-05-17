"use strict";

document.addEventListener("DOMContentLoaded", init);

function init() {
  document
    .querySelector(".custom-file-input")
    .addEventListener("change", () => {
      const inputField = document.getElementById("customFile");
      const filename = inputField.value.split("\\");
      const zipfilename = filename[filename.length - 1];
      document.querySelector(".custom-file-label").innerHTML = zipfilename;
    });

  document.getElementById("rtlSubmit").addEventListener("click", (e) => {
    const inputField = document.getElementById("customFile");
    const filename = inputField.value.split("\\");
    const zipfilename = filename[filename.length - 1];

    if (zipfilename !== "rtl.zip") {
      console.log("wrong filename");
      e.preventDefault();
    }
  });
}
