import CryptoJS from 'crypto-js';
import crypto from 'crypto';

import { API_ROOT } from './api-config';

export let Temporary = {
  uploadFile: function (files, progressCallback) {
    if (files.length > 1) {
      console.error("Multi-file-upload is not supported yet.");
    } else {
      let file = files[0];
      let uuid = crypto.randomBytes(16).toString("hex");
      let pwd = crypto.randomBytes(8).toString("hex");
      let encryptedName = encryptFile(file.name, pwd);

      return newChunkedFile(uuid, encryptedName.toString())
        .then(function () {
          return forEachSlice(file, progressCallback, function (slice) {
            return blobToBase64(slice)
              .then(function (data) {
                data = encryptFile(data, pwd);
                return appendChunk(uuid, data.toString());
              });
          })
        })
        .then(function (e) {
          return commitChunkedfile(uuid);
        })
        .then(checkJSONStatus)
        .then(function () {
          return { uuid: uuid, pwd: pwd };
        });
    }
  },

  downloadFile: function (uuid, password, progressCallback) {
    return getName(uuid)
      .then(function (result) {
        name = result
        return Promise.resolve();
      })
      .then(function () {
        return getChunkCount(uuid)
          .then(function (count) {
            return combineChunks(uuid, count, progressCallback);
          })
      })
      .then(function (data) {
        return decryptFile(data, password);
      })
      .then(function (data) {
        return chunkedFileToBlob(data);
      })
      .then(function (blob) {        
        return downloadFile(blob, decryptData(name, password));
      });
  },

  normal: function (button, text) {
    this.enable(button);
    button.className = "";

    if (text) {
      button.textContent = text;
    }
  },

  normalDisabled: function (button, text) {
    this.disable(button);
    button.className = "";

    if (text) {
      button.textContent = text;
    }
  },

  success: function (button, text) {
    let oldText = button.textContent;

    this.disable(button);
    button.className = "success";
    button.textContent = text ? text : "Success";

    return delay(1500).then(function () {
      this.normal(button, oldText);
    }.bind(this));
  },

  error: function (button, text) {
    let oldText = button.textContent;

    this.disable(button);
    button.className = "error";
    button.textContent = text ? text : "Error";

    return delay(1500).then(function () {
      this.normal(button, oldText);
    }.bind(this));
  },

  enable: function (button) {
    button.disabled = false;
  },

  disable: function (button) {
    button.disabled = true;
  },

  showErrorToast: function (text) {
    let toast = document.getElementById("toast");
    toast.textContent = text;
    toast.classList.remove("out-of-screen");
  },

  hideErrorToast: function () {
    let toast = document.getElementById("toast");
    toast.classList.add("out-of-screen");
    delay(500).then(function () {
      toast.textContent = "";
    });
  },

  showUploadView: function () {
    document.getElementById("upload-view").classList.remove("out-of-screen-top");
    document.getElementById("copy-link-view").classList.add("out-of-screen");
    clearDownloadLink();
  },

  showCopyLinkView: function (uuid, pwd) {
    let link = generateDownloadLink(uuid, pwd);
    setDownloadLink(link);

    let countDown = document.getElementById("countdown");
    this.startCountDown(countDown, getTimeStampThreeDaysAhead());

    document.getElementById("upload-view").classList.add("out-of-screen-top");
    document.getElementById("copy-link-view").classList.remove("out-of-screen");
  },

  copyToClipboard: function (element) {
    element.focus();
    element.select();

    let noError = document.execCommand('copy');
    if (noError) {
      return true;
    } else {
      return false;
    }
  },

  startCountDown: startCountDown,

  decryptData: function (data, password) {
    return CryptoJS.AES.decrypt(data, password).toString(CryptoJS.enc.Latin1);
  }
}

// Helper functions //
function encryptFile(data, pwd) {
  return CryptoJS.AES.encrypt(data, pwd);
}

function newChunkedFile(uuid, name) {
  let data = { name: name };
  return fetch(API_ROOT + "/api/chunker/new/" + uuid, {
    headers: { "content-type": "application/json" },
    body: JSON.stringify(data),
    method: "POST"
  })
    .then(checkJSONStatus);
}

function appendChunk(uuid, base64Data) {
  let data = { base64Data: base64Data };
  return fetch(API_ROOT + "/api/chunker/append/" + uuid, {
    headers: { "content-type": "application/json" },
    body: JSON.stringify(data),
    method: "POST"
  });
}

function commitChunkedfile(uuid) {
  return fetch(API_ROOT + "/api/chunker/commit/" + uuid, {
    headers: { "content-type": "application/json" },
    method: "POST"
  });
}

function blobToBase64(blob) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.readAsDataURL(blob);
    reader.onload = () => {
      let result = "data:application/octet-stream;base64," + reader.result.split(",")[1];
      return resolve(result);
    }
    reader.onerror = error => reject(error);
  });
}

function forEachSlice(file, progressCallback, callback) {
  const sliceSize = (1024 * 1024) / 4; // 0.25 MB
  const maxSize = file.size;
  const maxChunks = Math.ceil(maxSize / sliceSize);

  let recurse = function (promise, start, end) {
    if (start >= maxSize) {
      return promise;
    }

    if (end > maxSize) {
      end = maxSize;
    }

    let next = promise.then(function () {
      let chunkNumber = Math.ceil(end / sliceSize);
      progressCallback(chunkNumber, maxChunks);
      console.log("Uploading " + chunkNumber + "/" + maxChunks);
      return callback(file.slice(start, end));
    });

    return recurse(next, start + sliceSize, start + 2 * sliceSize);
  };

  let finalPromise = recurse(Promise.resolve(), 0, sliceSize);
  return finalPromise;
}

function delay(time, v) {
  return new Promise(function (resolve) {
    setTimeout(resolve.bind(null, v), time)
  });
}

function checkJSONStatus(response) {
  return response.json()
    .then(function (json) {
      if (json.status === "OK") {
        return json;
      } else {
        return Promise.reject(new Error(json.message));
      }
    });
}

function generateDownloadLink(uuid, pwd) {
  return API_ROOT + "/download?uuid=" + uuid + "&pwd=" + pwd;
}

let downloadLink = document.getElementById("download-link");
function setDownloadLink(link) {
  downloadLink.textContent = link;
}

function clearDownloadLink() {
  downloadLink.textContent = "";
}

function parseCountDownStringFromTimestamp(timestamp) {
  const secondConstant = 1000;
  const minuteConstant = secondConstant * 60;
  const hourConstant = minuteConstant * 60;
  const dayConstant = hourConstant * 24;

  let days = Math.floor(timestamp / dayConstant);
  let remainder = timestamp - days * dayConstant;

  let hours = Math.floor(remainder / hourConstant);
  remainder -= hours * hourConstant;

  let minutes = Math.floor(remainder / minuteConstant);
  remainder -= minutes * minuteConstant;

  let seconds = Math.floor(remainder / secondConstant);

  return days + "d " + hours + "h " + minutes + "min " + seconds + "s";
}

let countDownInterval;
let countDownTime = 0;
function startCountDown(element, time) {
  countDownTime = time - Date.now();
  countDownInterval = setInterval(() => decrementCountDown(element), 1000);

  element.textContent = parseCountDownStringFromTimestamp(countDownTime);
}

function decrementCountDown(element) {
  if (countDownTime <= 0) {
    clearInterval(countDownInterval);
  }

  element.textContent = parseCountDownStringFromTimestamp(countDownTime);
  countDownTime = countDownTime - 1000;
}

function getTimeStampThreeDaysAhead() {
  return Date.now() + 3 * 24 * 60 * 60 * 1000;
}

function combineChunks(uuid, count, progressCallback) {
  let chunks = [];
  let recurse = function (promise, index) {  
    progressCallback(index, count);
    console.log("Downloading " + index + "/" + count);
    
    if (index >= count) {
      return Promise.resolve(chunks);
    }
    
    let next = promise.then(function() {
      return getChunk(uuid, index);
    });
      
    return next.then(function(data) {
      chunks.push(data);
      return recurse(next, index + 1);
    });
  }

  let finalPromise = recurse(Promise.resolve(), 0, []);
  return finalPromise;
}

function decryptData(data, password) {
  return CryptoJS.AES.decrypt(data, password).toString(CryptoJS.enc.Latin1);
}

function decryptFile(data, password) {
  return new Promise(function(resolve, reject) {
    data = data.map(function(d) {      
      return decryptData(d, password);      
    });
    return resolve(data);
  });
}

function downloadFile(blobData, name) {
  return new Promise(function(resolve, reject) {
    let link = document.createElement("a");
    link.download = name;
    link.href = URL.createObjectURL(blobData);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    return resolve([]);
  });  
}

function dataURIToBlob(dataURI) {
  var binStr = atob(dataURI.split(',')[1]),
    len = binStr.length,
    arr = new Uint8Array(len),
    mimeString = dataURI.split(',')[0].split(':')[1].split(';')[0]

  for (var i = 0; i < len; i++) {
    arr[i] = binStr.charCodeAt(i);
  }

  return new Blob([arr], {
    type: mimeString
  });
}

function getName(uuid) {
  return fetch(API_ROOT + "/api/chunker/name/" + uuid, {
    headers: {"content-type": "application/json"},
    method: "GET"
  })
  .then(function(response) { return response.json() })
  .then(function(json) { return Promise.resolve(json.payload.name)});
}

function getChunkCount(uuid) {
  return fetch(API_ROOT + "/api/chunker/length/" + uuid, {
    headers: {"content-type": "application/json"},
    method: "GET"
  })
  .then(function(response) { return response.json() })
  .then(function(json) { return Promise.resolve(json.payload.length)});
}

function getChunk(uuid, index) {
  return fetch(API_ROOT + "/api/chunker/chunk/" + index + "/" + uuid, {
    headers: {"content-type": "application/json"},
    method: "GET"
  })
  .then(function(response) { return response.json() })
  .then(function(json) { return Promise.resolve(json.payload.data)});
}

function chunkedFileToBlob(chunks) {
  return new Promise(function(resolve, reject) {
    chunks = chunks.filter(function(chunk) {
      return chunk !== ""
    })
    .map(function(chunk) {
      return dataURIToBlob(chunk);
    });
    
    return resolve(new Blob(chunks));
  });  
}