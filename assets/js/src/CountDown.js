import React from 'react';

class CountDown extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      intervalId: null,
      time: parseInt(props.endTime, 10) - Date.now()
    }

    this.decrement = this.decrement.bind(this)
  }

  decrement() {
    if (this.state.time <= 0) {
      clearInterval(this.state.intervalId);
    }
    this.setState({ time: this.state.time - 1000 });
  }

  componentDidMount() {
    this.setState({
      intervalId: setInterval(() => this.decrement(), 1000)
    });
  }

  componentWillUnmount() {
    clearInterval(this.state.intervalId);
    this.setState({
      intervalId: null
    });
  }

  render() {
    return (
      <div className={"countdown-container " + (this.props.className ? this.props.className : "")}> 
        <div className="countdown">{parseCountDownStringFromTimestamp(this.state.time)}</div>
        <div className="countdown-text">{this.props.text}</div>
      </div>
    );
  }
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

export default CountDown;