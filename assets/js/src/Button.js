import React from 'react';

class Button extends React.Component {
  constructor(props) {
    super(props);

    this.success = this.success.bind(this);
    this.error = this.error.bind(this);
    this.normal = this.normal.bind(this);
    this.enable = this.enable.bind(this);
    this.disable = this.disable.bind(this);

    this.state = {
      buttonText: props.text,
      messageText: null,
      buttonModifier: "",
      enabled: props.enabled
    }
  }

  componentWillReceiveProps(props) {
    this.setState({
      buttonText: props.text,
      enabled: props.enabled,
      clickHandler: props.onClick
    });
  }

  success(text) {
    this.disable();
    this.setState({ 
      messageText: text ? text : "Success!",
      buttonModifier: "success"
    });

    return delay(1500).then(function () { 
      this.normal();
      this.enable();
    }.bind(this));
  }

  error(text) {
    this.disable();
    this.setState({ 
      messageText: text ? text : "Error.",
      buttonModifier: "error"
    });

    return delay(1500).then(function () { 
      this.normal();
      this.enable();
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

  disable() {
    this.setState({ enabled: false });
  }

  render() {
    return (
      <button 
        className={this.state.buttonModifier + " " + (this.props.className ? this.props.className : "")}
        disabled={!this.state.enabled}
        onClick={
          (typeof this.props.onClick) !== "undefined" ? this.props.onClick.bind(this) : function() {}
        }
      >
        {this.state.messageText ? this.state.messageText : this.state.buttonText}
      </button>
    );
  }
}

function delay(time, v) {
  return new Promise(function(resolve) { 
      setTimeout(resolve.bind(null, v), time)
  });
}

export default Button;