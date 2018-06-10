import React from 'react';

import FileUpload from './FileUpload'
import FileDownload from './FileDownload'
import Button from './Button'
import CountDown from './CountDown'

//import './App.css';

class App extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      uploadModifier: "",
      downloadModifier: "",
      headingModifier: "",
      backModifier: "hidden",
      countDownModifier: "hidden",
      countDownEndTime: 0
    }

    this.reset = this.reset.bind(this);
  }

  reset() {
    this.setState({
      uploadModifier: "",
      downloadModifier: "",
      headingModifier: "",
      backModifier: "hidden",
      countDownModifier: "hidden",
      countDownEndTime: 0
    });

    this.refs.fileUpload.reset();
  }

  render() {
    return (
      <div className="wrapper">
        <div className={"heading " + this.state.headingModifier}>
          <h1>Temporary</h1>
          <p>Your temporary file storage.</p>
        </div>
        {
          this.state.countDownModifier !== "hidden" ?
            <CountDown 
              endTime={this.state.countDownEndTime}
              text="until your file will be deleted."
              className={this.state.countDownModifier}
            /> : null
        }
        <div className="content">
          <FileUpload 
            ref="fileUpload"
            text="Store file"
            className={this.state.uploadModifier}
            onSuccess={() => this.setState({
              downloadModifier: "hidden",
              headingModifier: "hidden",
              backModifier: "",
              countDownModifier: "",
              countDownEndTime: getTimeStampThreeDaysAhead()
            })}
            onError={() => this.reset()}
          />
          <FileDownload 
            buttonText="Download file" 
            inputText="Enter to confirm."
            className={this.state.downloadModifier} 
            onError={() => this.reset()}
          />
          <Button
            className={this.state.backModifier}
            text="Back"
            enabled={true}
            onClick={() => this.reset()}
          />
        </div>
      </div>
    );
  }
}

function getTimeStampThreeDaysAhead() {
  return new Date().getTime() + 3 * 24 * 60 * 60 * 1000;
}

export default App;
