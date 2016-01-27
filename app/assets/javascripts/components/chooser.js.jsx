var Chooser = React.createClass({
  getInitialState: function() {
    return {
     firstName: '',
     lastName: ''
    }
  },

  fetchUser: function(e) {
    e.preventDefault();
    this.props.fetchByName(this.state.firstName, this.state.lastName);
  },

  handleFirstNameChange: function(e) {
    this.setState({firstName: e.target.value});
  },

  handleLastNameChange: function(e) {
    this.setState({lastName: e.target.value});
  },

  render: function() {
    return (
      <ReactBootstrap.Navbar default>
        <form className="navbar-form navbar-left" role="search">
          <div className="form-group">
            <ReactBootstrap.Input
              type="text"
              placeholder="Firstname"
              value={this.state.firstName}
              onChange={this.handleFirstNameChange}
              hasFeedback
              ref="input"
            />
          </div>
          <div className="form-group">
            <ReactBootstrap.Input
              type="text"
              placeholder="Lastname"
              value={this.state.lastName}
              onChange={this.handleLastNameChange}
              hasFeedback
              ref="input"
            />
          </div>
          <button type="button" className="btn btn-primary" onClick={this.fetchUser} ><i className="fa fa-user" />Search</button>
        </form>
        <form className="navbar-form navbar-left" role="search">
          <button type="button" className="btn btn-primary" onClick={this.props.fetchMadeUp} ><i className="fa fa-magic" /> Make One Up</button>
        </form>
      </ReactBootstrap.Navbar>
    )
  }
});
