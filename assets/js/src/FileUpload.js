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
        readFile(file, (data) => {
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
        });
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

  export default FileUpload;