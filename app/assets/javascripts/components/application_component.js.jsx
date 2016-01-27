var ApplicationComponent = React.createClass({

  getInitialState: function() {
    return {
      users: [
      ]
    };
  },

  fetchByName: function(firstName, lastName) {
    this.fetch({first_name_begins: firstName, last_name_begins: lastName});
  },

  fetchMadeUp: function(e) {
    if (e) {
      e.preventDefault();
    }
    this.fetch({number: 1});
  },

  fetch: function(params) {
    $.ajax({
          type: 'GET',
          url: '/users/fetch',
          data: params,
          contentType: 'application/json',
          dataType: 'json'
        }).then(
          this.loadUser,
          this.handleAjaxError
        );
  },

  handleAjaxError: function(jqXHR, status, err) {
    console.log("Unexpected error: "+jqXHR.responseText);
  },

  loadUser: function(data) {
    if (this.isMounted()) {
      if ('users' in data){
        this.setState(data);
      }
      else {
        this.setState({users: [data]})
      }
    }
  },

  unloadUser: function(e) {
    if (e) {
      e.preventDefault();
    }
    if (this.isMounted()) {
      this.setState(this.getInitialState());
    }
  },

  saveUser: function(user) {
    $.ajax({
      type: 'POST',
      url: '/users',
      data: JSON.stringify({user: user}),
      contentType: 'application/json',
      dataType: 'json'
    }).then(
      this.loadUser,
      this.handleAjaxError
    );
  },

  render: function() {
    return (
      <div className="container-fluid">
        <Chooser fetchByName={this.fetchByName} fetchMadeUp={this.fetchMadeUp} />
        <div id="alerts" />
        <UserList users={this.state.users} saveUser={this.saveUser} unloadUser={this.unloadUser} destroyUser={this.destroyUser} />
      </div>
    )
  }
});
