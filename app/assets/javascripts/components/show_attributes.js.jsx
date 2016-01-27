var ShowAttributes = React.createClass({
  render: function() {
      if (this.props.user.is_real) {
        var icon = <i className="fa fa-user" data-toggle="tooltip" title="real user" />
      }
      else {
        var icon = <i className="fa fa-magic" data-toggle="tooltip" title="fake user" />
      }
      return (
        <ul className="list-inline">
          <li>{icon}</li>
          <li>{this.props.user.uid}</li>
          <li>{this.props.user.first_name}</li>
          <li>{this.props.user.last_name}</li>
          <li>{this.props.user.email}</li>
        </ul>
      )
  }
});
