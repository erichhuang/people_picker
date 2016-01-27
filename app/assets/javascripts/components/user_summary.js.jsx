var UserSummary = React.createClass({

  destroyCurrentUser: function(e) {
    e.preventDefault();
    this.props.destroyUser(this.props.user);
  },

  render: function() {
    if (this.props.user.is_persisted) {
      var userAction = <UseUser {...this.props} />
      var userAttributes = <ShowAttributes {...this.props} />
    }
    else {
      var userAction = <SaveUser {...this.props} />
      if (this.props.user.is_real) {
        var userAttributes = <ShowAttributes {...this.props} />
      }
      else {
        var userAttributes = <EditAttributes {...this.props} />
      }
    }
    return (
      <ul className="list-inline">
        <li><a onClick={this.props.unloadUser} data-toggle="tooltip" title="discard"><i className="fa fa-times" /></a></li>
        <li>{userAttributes}</li>
        <li>{userAction}</li>
      </ul>
    )
  }
});
