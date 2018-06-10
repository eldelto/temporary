import React from 'react';
import CryptoJS from 'crypto-js';

import InputButton from './InputButton.js';

class FileDownload extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      inputValue: "",
      buttonText: props.buttonText
    };

    this.keyPressHandler = this.keyPressHandler.bind(this);
    this.onChangeHandler = this.onChangeHandler.bind(this);
  }
  
  keyPressHandler(e) {
    if (e.key === 'Enter') {
      let inputValues = this.state.inputValue.split(":");
      if (inputValues.length < 2) {
        this.refs.downloadButton.error("Invalid ID.");
        return;
      }

      let uuid = inputValues[0];
      let password = inputValues[1];

      this.refs.downloadButton.disable("Downloading...");
      fetchFile(uuid)
      .then(json => {
        if (json.status !== "OK") {
          this.refs.downloadButton.error();
          console.log("Call to '/api/file/fetch' returned error: " + json.message);
          return;
        }
  
        let base64Data = json.payload.file.base64Data;
        let fileName = json.payload.file.name;

        this.refs.downloadButton.disable("Decrypting...");
        let decryptedData = decryptFile(base64Data, password);
        let decryptedFilename = decryptFile(fileName, password);

        this.refs.downloadButton.success();
        downloadFile(decryptedData, decryptedFilename);
      })
      .catch(function(error) {
        console.error("Error while fetching file: " + error);
        this.props.onError();
        this.refs.downloadButton.error();
      }.bind(this));
    }
  }

  onChangeHandler(e) {
    this.setState({
      inputValue: e.target.value
    });
  }

  render() {
    return (
      <InputButton
        ref="downloadButton"
        buttonText={this.state.buttonText}
        inputText={this.props.inputText}
        className={this.props.className}   
        onKeyPress={(e) => this.keyPressHandler(e)}
        value={this.state.inputValue}
        onChange={(e) => this.onChangeHandler(e)}
        enabled={true}
      />
    )
  }
}

function fetchFile(uuid) {
  return fetch("/api/file/fetch/" + uuid)
    .then(response => {
      if (response.status !== 200) {
        console.log("Call to '/api/file/fetch' failed with status: " + response.status);
        return;
      }

      return response.json();
    });
} 


function decryptFile(data, password) {
  return CryptoJS.AES.decrypt(data, password).toString(CryptoJS.enc.Latin1);
}

function downloadFile(data, name) {
  let blobData = dataURIToBlob(data);
  let link = document.createElement("a");
  link.download = name;
  link.href = URL.createObjectURL(blobData);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
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

export default FileDownload;