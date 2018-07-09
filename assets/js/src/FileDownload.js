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
      let name = "unnamed";
      this.refs.downloadButton.disable("Downloading...");
      
      getName(uuid)
      .then(function(result) {
        name = result        
        return Promise.resolve();
      })
      .then(function() {
        return getChunkCount(uuid)
        .then(function(count) { 
          return combineChunks(uuid, count);
        })
      })
      .then(function(data) {
        return chunkedFileToBlob(data);
      })
      .then(function(blob) {        
        this.refs.downloadButton.success();
        return downloadFile(blob, name);
      }.bind(this))
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
  return fetch("/api/chunker/name/" + uuid, {
    headers: {"content-type": "application/json"},
    method: "GET"
  })
  .then(function(response) { return response.json() })
  .then(function(json) { return Promise.resolve(json.payload.name)});
}

function getChunkCount(uuid) {
  return fetch("/api/chunker/length/" + uuid, {
    headers: {"content-type": "application/json"},
    method: "GET"
  })
  .then(function(response) { return response.json() })
  .then(function(json) { return Promise.resolve(json.payload.length)});
}

function getChunk(uuid, index) {
  return fetch("/api/chunker/chunk/" + index + "/" + uuid, {
    headers: {"content-type": "application/json"},
    method: "GET"
  })
  .then(function(response) { return response.json() })
  .then(function(json) { return Promise.resolve(json.payload.data)});
}

function combineChunks(uuid, count) {
  let chunks = [];
  let recurse = function (promise, index) {  
    console.log(index + ":" + count);
    if (index >= count) {
      return Promise.resolve(chunks);
    }
    
    let next = promise.then(function() {
      console.log("callback")
      return getChunk(uuid, index);
    });
  
    console.log(next);
  
    return next.then(function(data) {
      //console.log(data);   
      chunks.push(data);
      return recurse(next, index + 1);
    });
  }

  let finalPromise = recurse(Promise.resolve(), 0, []);
  console.log("finalPromise");
  console.log(finalPromise);
  return finalPromise;
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

export default FileDownload;