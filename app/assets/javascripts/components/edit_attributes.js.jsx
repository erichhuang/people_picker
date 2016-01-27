var EditAttributes = React.createClass({

  getInitialState: function() {
    return {
     uid: this.props.user.uid,
     first_name: this.props.user.first_name,
     last_name: this.props.user.last_name,
     email: this.props.user.email
    }
  },

  handleUidChange: function(e) {
    e.preventDefault();
    this.setState({uid: e.target.value});
    this.props.user.uid = e.target.value;
  },

  handleFirstNameChange: function(e) {
    e.preventDefault();
    this.setState({first_name: e.target.value});
    this.props.user.first_name = e.target.value;
  },

  handleLastNameChange: function(e) {
    e.preventDefault();
    this.setState({last_name: e.target.value});
    this.props.user.last_name = e.target.value;
  },

  handleEmailChange: function(e) {
    e.preventDefault();
    this.setState({email: e.target.value});
    this.props.user.email = e.target.value;
  },

  render: function() {
      return (
      <ul className="list-inline">
        <li>
          <ReactBootstrap.Input
            type="text"
            placeholder="text"
            value={this.state.uid}
            onChange={this.handleUidChange}
            hasFeedback
            ref="input"
          />
        </li>
        <li>
          <ReactBootstrap.Input
            type="text"
            placeholder="text"
            value={this.state.first_name}
            onChange={this.handleFirstNameChange}
            hasFeedback
            ref="input"
          />
        </li>
        <li>
          <ReactBootstrap.Input
            type="text"
            placeholder="text"
            value={this.state.last_name}
            onChange={this.handleLastNameChange}
            hasFeedback
            ref="input"
          />
        </li>
        <li>
          <ReactBootstrap.Input
            type="text"
            placeholder="text"
            value={this.state.email}
            onChange={this.handleEmailChange}
            hasFeedback
            ref="input"
          />
        </li>
      </ul>
      )
  }
});
