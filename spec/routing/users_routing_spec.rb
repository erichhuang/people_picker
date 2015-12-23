require "rails_helper"

RSpec.describe UsersController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/users").to route_to("users#index")
    end

    it "routes to #use" do
      expect(:get => "/users/1/use").to route_to(controller: "users", action: "use", id: "1")
    end

    it "routes to #fetch" do
      expect(:get => "/users/fetch").to route_to("users#fetch")
    end

    it "routes to #stats" do
      expect(:get => "/users/stats").to route_to("users#stats")
    end

    it "routes to #create" do
      expect(:post => "/users").to route_to("users#create")
    end

  end
end
