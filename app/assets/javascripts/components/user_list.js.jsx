var UserList = React.createClass({
  render: function() {
    var userSummaries = this.props.users.map(function(user, i) {
      return (
        <UserSummary
          {...this.props}
          key={i}
          user_index={i}
          user={user} />
      )
    }.bind(this));
    return (
      <ul className="list-unstyled">
        <li>{userSummaries}</li>
      </ul>
    )
  }
});
