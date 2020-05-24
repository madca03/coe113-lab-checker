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
      e.preventDefault();
      const errorMessageTextNode = document.createTextNode("Wrong zip filename. Filename should be rtl.zip");
      const divAlert = document.createElement("div");
      divAlert.classList.add("alert");
      divAlert.classList.add("alert-danger");
      divAlert.setAttribute("role", "alert");
      divAlert.appendChild(errorMessageTextNode);
      
      const parentElem = document.querySelector("ul.list-group").parentElement
      parentElem.insertBefore(divAlert, parentElem.firstChild)
    }
  });
}
