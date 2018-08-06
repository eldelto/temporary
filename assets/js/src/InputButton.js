import React from 'react';

class InputButton extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      isButton: true,
      buttonText: props.buttonText,
      messageText: null,
      buttonModifier: "",
      enabled: props.enabled,
      inputValue: ""
    };

    this.success = this.success.bind(this);
    this.error = this.error.bind(this);
    this.normal = this.normal.bind(this);
    this.enable = this.enable.bind(this);
    this.disable = this.disable.bind(this);
    this.onChangeHandler = this.onChangeHandler.bind(this);
  }

  success(text) {
    this.disable();
    let oldIsButton = this.state.isButton;
    let oldInputValue = this.state.inputValue;
    this.setState({ 
      messageText: text ? text : "Success!",
      buttonModifier: "success",
      isButton: true,
      inputValue: ""
    });

    return delay(1500).then(function () { 
      this.normal();
      this.enable();
      this.setState({ 
        isButton: oldIsButton,
        inputValue: oldInputValue
       });
    }.bind(this));
  }

  error(text) {
    this.disable();
    let oldIsButton = this.state.isButton;
    let oldInputValue = this.state.inputValue;
    this.setState({ 
      messageText: text ? text : "Error.",
      buttonModifier: "error",
      isButton: true,
      inputValue: ""
    });

    return delay(1500).then(function () { 
      this.normal();
      this.enable();
      this.setState({ 
        isButton: oldIsButton,
        inputValue: oldInputValue
       });
    }.bind(this));
  }

  normal(text) {
    this.setState({
      buttonText: text ? text : this.state.buttonText,
      messageText: null,
      buttonModifier: ""
    });
  }

  enable() {
    this.setState({ enabled: true });
  }

  disable(text) {
    this.setState({ 
      enabled: false,
      isButton: true,
      inputValue: "",
      messageText: text ? text : this.state.buttonText
     });
  }

  onChangeHandler(event) {
    this.props.onChange(event);
    this.setState({inputValue: event.target.value});
  }

  render() {
    return (
      <input
        ref="input"
        className={this.props.className  + " " + this.state.buttonModifier + " " + (this.state.isButton ? "button" : "input")}
        type="text"
        placeholder={this.state.messageText ? this.state.messageText : 
          (this.state.isButton ? this.state.buttonText : this.props.inputText)}
        readOnly={this.state.isButton}
        onClick={() => {
          this.setState({ isButton: false });
          this.refs.input.focus();
        }}
        onBlur={() => this.setState({ isButton: true, inputValue: "" })}
        onKeyPress={this.props.onKeyPress}
        value={this.state.inputValue} 
        onChange={this.onChangeHandler}
        disabled={!this.state.enabled}
      />
    );
  }
}

function delay(time, v) {
  return new Promise(function(resolve) { 
      setTimeout(resolve.bind(null, v), time)
  });
}

export default InputButton;