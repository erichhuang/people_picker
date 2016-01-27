var UseUser = React.createClass({
  render: function() {
      return (
        <a href={"/users/"+this.props.user.id+"/use"} data-toggle="tooltip" title="assume this identity"><i className="fa fa-check-circle-o" /></a>
      )
  }
});
