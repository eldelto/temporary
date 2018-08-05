import React from 'react';
import CryptoJS from 'crypto-js';
import crypto from 'crypto';

import Button from './Button.js';

class FileUpload extends React.Component {
  constructor(props) {
    super(props);

    this.initUploadFile = this.initUploadFile.bind(this);
    this.uploadFile = this.uploadFile.bind(this);
    this.copyToClipboard = this.copyToClipboard.bind(this);
    this.copyToClipboardIOS = this.copyToClipboardIOS.bind(this);
    this.reset = this.reset.bind(this);
    this.forEachSlice = this.forEachSlice.bind(this);

    this.state = {
      file: "",
      password: "",
      buttonText: props.text,
      enabled: true,
      clickHandler: this.initUploadFile
    }
  }

  initUploadFile() {
    this.refs.fileInput.click();
  }

  uploadFile(files) {
    if(files.length > 1) {
      alert("Multi-file-upload is not supported yet.");
    } else {
      let file = files[0];      
      let uuid = crypto.randomBytes(16).toString("hex");
      let password = crypto.randomBytes(8).toString("hex");
      let encryptedName = encryptFile(file.name, password);

      newChunkedFile(uuid, encryptedName.toString())
      .then(function() {
        return this.forEachSlice(file, function(slice) {
          return blobToBase64(slice)
          .then(function(data) { 
            data = encryptFile(data, password);
            return appendChunk(uuid, data.toString()) 
          });
        })
      }.bind(this))
      .then(function(e) {
        return commitChunkedfile(uuid);
      })
      .then(function(response){ return response.json() })
      .then(function(json) {
        if (json.status === "OK") {
          return this.refs.uploadButton.success();          
        } else {
          this.props.onError();
          this.refs.uploadButton.error();
          return Promise.reject(new Error("Request returned with JSON status: " + json.status));
        }      
      }.bind(this))
      .then(function() {
        this.props.onSuccess();
        this.setState({
          buttonText: "Copy ID",
          enabled: true,
          clickHandler: () => {
            this.copyToClipboard(uuid + ":" + password);
            this.copyToClipboardIOS(uuid + ":" + password);
          }
        })
      }.bind(this))
      .catch(function(error) {
        console.error(error);
        this.props.onError();
        this.refs.uploadButton.error();
      }.bind(this));      
    }
  }

  copyToClipboard(text) {
    var textArea = document.createElement("textarea");
    textArea.className = "hidden";
    textArea.value = text;
    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();

    let noError = document.execCommand('copy');
    textArea.remove();
    if (noError) {
      return this.refs.uploadButton.success();
    } else {
      this.props.onError();
      return this.refs.uploadButton.error();
    }
  }

  copyToClipboardIOS(text) {
    let textArea = document.createElement("textarea");
    textArea.className = "hidden";
    textArea.value = text;
    textArea.contentEditable = true;
    textArea.readOnly = false;    
    document.body.appendChild(textArea);

    let range = document.createRange();
    range.selectNodeContents(textArea);

    let s = window.getSelection();
    s.removeAllRanges();
    s.addRange(range);
    textArea.setSelectionRange(0, 999999);

    let noError = document.execCommand('copy');
    textArea.remove();
    if (noError) {
      return this.refs.uploadButton.success();
    } else {
      this.props.onError();
      return this.refs.uploadButton.error();
    }
  }

  reset() {
    this.setState({
      file: "",
      password: "",
      buttonText: this.props.text,
      enabled: true,
      clickHandler: this.initUploadFile
    });
  }

  forEachSlice(file, callback) {
    const sliceSize = 1024 * 1024; // 1 MB
    const maxSize = file.size;
    const maxChunks = Math.ceil(maxSize / sliceSize);
  
    let recurse = function (promise, start, end) {  
      if (start >= maxSize) {
        return promise;
      }
  
      if (end > maxSize) {
        end = maxSize;
      }
      
      let next = promise.then(function() {
        let chunkNumber = Math.ceil(end / sliceSize);
        this.refs.uploadButton.normal("Uploading " + chunkNumber + "/" + maxChunks);
        return callback(file.slice(start, end));
      }.bind(this));
        
      return recurse(next, start + sliceSize, start + 2 * sliceSize);
    }.bind(this);
  
    let finalPromise = recurse(Promise.resolve(), 0, sliceSize);
    return finalPromise;
  }

  render() {
    return (
      <div className={"file-upload-container " + this.props.className}>
        <Button
          ref="uploadButton"
          text={this.state.buttonText}
          enabled={this.state.enabled}
          onClick={this.state.clickHandler}
        />

        <input type="file" ref="fileInput" onChange={
            (e) => {
              this.setState({
                buttonText: "Reading...",
                enabled: false
              });
              this.uploadFile(e.target.files);
              e.target.value = null;
            }
          } style={{display: "none"}}/>
      </div>
    );
  }
}


function encryptFile(data, password) {
  return CryptoJS.AES.encrypt(data, password);
}

function newChunkedFile(uuid, name) {
  let data = { name: name };
  return fetch("/api/chunker/new/" + uuid, {
    headers: {"content-type": "application/json"},
    body: JSON.stringify(data),
    method: "POST"
  });
}

function appendChunk(uuid, base64Data) {
  let data = { base64Data: base64Data };
  return fetch("/api/chunker/append/" + uuid, {
    headers: {"content-type": "application/json"},
    body: JSON.stringify(data),
    method: "POST"
  });
}

function commitChunkedfile(uuid) {
  return fetch("/api/chunker/commit/" + uuid, {
    headers: {"content-type": "application/json"},
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

export default FileUpload;