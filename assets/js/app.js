// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html"
import { Temporary } from "./src/temporary"

let storeFileButton = document.getElementById("store-file-button");
let storeFileInput = document.getElementById("store-file-input");

let copyLinkButton = document.getElementById("copy-link-button");
let backButton = document.getElementById("back-button");

let downloadLink = document.getElementById("download-link");
let countDown = document.getElementById("countdown");
let filename = document.getElementById("filename");
let downloadButton = document.getElementById("download-button");

let url = new URL(window.location);  
let uuid = url.searchParams.get("uuid");
let password = url.searchParams.get("pwd");

function uploadProgressCallback(currentChunk, maxChunks) {
  let percent = Math.round((currentChunk / maxChunks) * 1000) / 10;
  Temporary.normalDisabled(storeFileButton, percent + "%");
}

function downloadProgressCallback(currentChunk, maxChunks) {
  let percent = Math.round((currentChunk / maxChunks) * 1000) / 10;
  Temporary.normalDisabled(downloadButton, percent + "%");
}

if (storeFileButton) {
  storeFileButton.onclick = function () {
    Temporary.hideErrorToast();
    storeFileInput.click();
  }
}

if (storeFileInput) {
  storeFileInput.onchange = function (e) {
    let oldText = storeFileButton.textContent;
    Temporary.uploadFile(e.target.files, uploadProgressCallback)
      .then(function (result) {
        console.log(result);
        return Temporary.success(storeFileButton)
          .then(function () {
            return result;
          });
      })
      .then(function (result) {
        Temporary.normal(storeFileButton, oldText);
        Temporary.showCopyLinkView(result.uuid, result.pwd);
      })
      .catch(function (error) {
        Temporary.error(storeFileButton);
        Temporary.showErrorToast(error);
      });
  }
}

if (copyLinkButton) {
  copyLinkButton.onclick = function () {
    if (Temporary.copyToClipboard(downloadLink)) {
      Temporary.success(copyLinkButton);
    } else {
      Temporary.error(copyLinkButton);
    }
  }
}

if (backButton) {
  backButton.onclick = function () {
    Temporary.showUploadView();
  }
}

if (countDown) {
  let timestamp = countDown.getAttribute("timestamp-data");
  Temporary.startCountDown(countDown, timestamp);
}

if (filename) {    
  let decryptedFilename = Temporary.decryptData(filename.textContent, password);
  filename.textContent = decryptedFilename;
}

if (downloadButton) {
  downloadButton.onclick = function () {
    let oldText = downloadButton.textContent;
    Temporary.downloadFile(uuid, password, downloadProgressCallback)
    .then(function () {
      return Temporary.success(downloadButton);
    })
    .then(function () {
      Temporary.normal(downloadButton, oldText);
    })
    .catch(function (error) {
      Temporary.error(downloadButton);
      Temporary.showErrorToast(error);
    });
  }
}