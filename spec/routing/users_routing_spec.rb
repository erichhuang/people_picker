require "rails_helper"

RSpec.describe UsersController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/users").to route_to("users#index")
    end

    it "routes to #use" do
      expect(:get => "/users/1/use").to route_to(controller: "users", action: "use", id: "1")
    end

    it "routes to #fetch_existing" do
      expect(:get => "/users/fetch_existing").to route_to("users#fetch_existing")
    end

    it "routes to #fetch_ldap" do
      expect(:get => "/users/fetch_ldap").to route_to("users#fetch_ldap")
    end

    it "routes to #feeling_lucky" do
      expect(:get => "/users/feeling_lucky").to route_to("users#feeling_lucky")
    end

    it "routes to #stats" do
      expect(:get => "/users/stats").to route_to("users#stats")
    end

    it "routes to #create" do
      expect(:post => "/users").to route_to("users#create")
    end

    it "routes to #create_multi" do
      expect(:post => "/users/multi").to route_to("users#create_multi")
    end

  end
end
