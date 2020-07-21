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
    this.combineChunks = this.combineChunks.bind(this);
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
      
      getName(uuid)
      .then(function(result) {
        name = result        
        return Promise.resolve();
      })
      .then(function() {
        return getChunkCount(uuid)
        .then(function(count) { 
          return this.combineChunks(uuid, count);
        }.bind(this))
      }.bind(this))
      .then(function(data) {
        let worker = createWorker();
        worker.postMessage([data, name, password]);
        //return decryptFile(data, password);
      })
      .then(function(data) {        
        //return chunkedFileToBlob(data);
      })
      .then(function(blob) {        
        this.refs.downloadButton.success();
        //return downloadFile(blob, decryptData(name, password));
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

  combineChunks(uuid, count) {
    let chunks = [];
    let recurse = function (promise, index) {  
      this.refs.downloadButton.disable("Downloading " + index + "/" + count);
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
    }.bind(this);
  
    let finalPromise = recurse(Promise.resolve(), 0, []);
    return finalPromise;
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

function createWorker() {
  let worker = function() {
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


    onmessage = function(e) {
      let data = e.data[0];
      let name = e.data[1];
      let password = e.data[2];
      decryptFile(data, password)
      .then(function(data) {        
        return chunkedFileToBlob(data);
      })
      .then(function(blob) {
        return downloadFile(blob, decryptData(name, password));
      });
    }
  }

  let code = worker.toString();
  code = code.substring(code.indexOf("{")+1, code.lastIndexOf("}"));

  let blob = new Blob([code], {type: "application/javascript"});
  return new Worker(URL.createObjectURL(blob));
}

export default FileDownload;