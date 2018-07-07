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
    this.reset = this.reset.bind(this);

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
      newChunkedFile(uuid, name)
      .then(function() {
        return forEachSlice(file, function(slice) {
          return blobToBase64(slice)
          .then(function(data) { return appendChunk(uuid, data) });
        })
      })
      .then(function(e) {
        console.log("pre-commit");
        console.log(e);
        return commitChunkedfile(uuid);
      })
      .then(function(e){ console.log("DONE") });
      


      /*readFile(file, (data) => {
        let password = crypto.randomBytes(8).toString("hex");
        this.setState({
          password: password,
          buttonText: "Encrypting..."
        });

        let encryptedData = encryptFile(data, password);
        let encryptedFileName = encryptFile(file.name, password);

        this.setState({ buttonText: "Uploading..."});
        let uuid = crypto.randomBytes(16).toString("hex");

        sendToServer(uuid, encryptedFileName, encryptedData)
        .then(response => response.json())
        .then(json => {
          if (json.status === "OK") {
            this.refs.uploadButton.success()
            .then(function() {
              this.props.onSuccess();
              this.setState({
                buttonText: "Copy ID",
                enabled: true,
                clickHandler: () => this.copyToClipboard(uuid + ":" + password)
              })
            }.bind(this));
          } else {
            this.props.onError();
            this.refs.uploadButton.error();
            return Promise.reject(new Error("Request returned with JSON status: " + json.status));
          }
        })
        .catch(function(error) {
          console.error(error);
          this.props.onError();
          this.refs.uploadButton.error();
        }.bind(this));
      });*/
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

  reset() {
    this.setState({
      file: "",
      password: "",
      buttonText: this.props.text,
      enabled: true,
      clickHandler: this.initUploadFile
    });
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


function readFile(file, callback) {
  let reader = new FileReader();

  reader.onload = function(e) {
      let data = e.target.result;
      callback(data);
  }

  reader.readAsDataURL(file);
}

function encryptFile(data, password) {
  return CryptoJS.AES.encrypt(data, password);
}

function sendToServer(uuid, fileName, binary) {
  let data = {
    name: fileName.toString(),
    base64Data: binary.toString()
  };

  return fetch("/api/file/store/" + uuid, {
    headers: {"content-type": "application/json"},
    body: JSON.stringify(data),
    method: "POST"
  });
}

function forEachSlice(file, callback) {
  const sliceSize = 1024 * 1024; // 1 MB
  const maxSize = file.size;
  let start = 0;
  let end = 0;

  console.log("Max size: " + maxSize);

  let recurse = function (promise, start, end) {  
    console.log(start + ":" + maxSize);
    if (start >= maxSize) {
      return promise;
    }
    
    let next = promise.then(function() {
      console.log("callback")
      return callback(file.slice(start, end));
    });
  
    console.log(next);
    start += sliceSize;
    end = start + sliceSize;
  
    return recurse(next, start, end);
  }

  let finalPromise = recurse(Promise.resolve(), 0, sliceSize);
  console.log("finalPromise");
  console.log(finalPromise);
  return finalPromise;
}

function accumulator(promise, start, end, sliceSize, file, callback) {  
  console.log(start + ":" + file.size);
  if (start >= file.size) {
    return promise;
  }
  
  let next = promise.then(() => {
    callback(file.slice(start, end))
  });

  console.log(next);
  start += sliceSize;
  end = start + sliceSize;

  return accumulator(next, start, end, sliceSize, file, callback);  
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
  console.log("append");
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
  console.log("encode");
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.readAsDataURL(blob);
    reader.onload = () => {
      let result = reader.result;
      result = result.replace("data:application/octet-stream;base64,", "")
      resolve(result);
    }
    reader.onerror = error => reject(error);
  });
}

export default FileUpload;