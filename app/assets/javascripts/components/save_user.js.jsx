var SaveUser = React.createClass({
  saveCurrentUser: function(e) {
    e.preventDefault();
    this.props.saveUser(this.props.user);
  },

  render: function() {
      return (
        <a onClick={this.saveCurrentUser} data-toggle="tooltip" title="save"><i className="fa fa-save" /></a>
      )
  }
});
