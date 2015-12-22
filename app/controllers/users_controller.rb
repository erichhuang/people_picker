class UsersController < ApplicationController
  require 'net/ldap'
  require 'factory_girl_rails'
  require 'faker'

  def index
    [:client_id, :state].each do |required_param|
      unless params.has_key?(required_param)
        render plain: 'invalid_request', status: 401, layout: false
        return
      end
    end
    @consumer = Consumer.where(uuid: params[:client_id]).first
    if @consumer
      session[:client_id] = params[:client_id]
      session[:state] = params[:state]
      if session[:scope]
        session[:scope] = params[:scope]
      end
      session[:respose_type] = 'token'
      respond_to do |format|
        format.html # index.html.erb
      end
    else
      render plain: 'invalid_request', status: 401, layout: false
      return
    end
  end

  def fetch_existing
    unless session_valid
      render plain: 'invalid_request', status: 401, layout: false
      return
    end
    unless params.has_key?(:first_name_begins) || params.has_key?(:last_name_begins)
      render plain: 'invalid_request', status: 401, layout: false
      return
    end
    @scope = User.unscoped
    @scope = @scope.first_name_begins(params[:first_name_begins]) if params[:first_name_begins]
    @scope = @scope.last_name_begins(params[:last_name_begins]) if params[:last_name_begins]
    render json: @scope.all
  end

  def fetch_ldap
    unless session_valid
      render plain: 'invalid_request', status: 401, layout: false
      return
    end
    uid = ldap_params
    ldap = Net::LDAP.new(
      host: Rails.application.secrets.ldap_host,
      port: Rails.application.secrets.ldap_port,
      base: Rails.application.secrets.ldap_base
    )
    user = {}
    ldap.search(
      filter: Net::LDAP::Filter.eq("uid", uid),
      attributes: %w(uid sn givenName mail)
    ) { |entry|
      user = {
        uid: entry.uid.first,
        first_name: entry.givenName.first,
        last_name: entry.sn.first,
        email: entry.mail.first
      }
    }
    render json: user
  end

  def use
    unless session_valid
      render plain: 'invalid_request', status: 401, layout: false
      return
    end
    @user = User.find(params[:id])
    redirect_to_consumer
  end

  def stats
    unless session_valid
      render plain: 'invalid_request', status: 401, layout: false
      return
    end
    render json: {user_count: User.count}
  end

  def feeling_lucky
    unless session_valid
      render plain: 'invalid_request', status: 401, layout: false
      return
    end
    render json: FactoryGirl.attributes_for(:user)
  end

  def create
    unless session_valid
      render plain: 'invalid_request', status: 401, layout: false
      return
    end
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        format.html { render json: @user }
      else
        validation_errors = {}
        @user.errors.messages.each do |field, errors|
          errors.each do |message|
            validation_errors[field] = message
          end
        end
        format.html { render json: validation_errors }
      end
    end
  end

  def create_multi
    unless session_valid
      render plain: 'invalid_request', status: 401, layout: false
      return
    end
    number = multi_params.to_i
    if number > 5
      render plain: 'invalid_request', status: 401, layout: false
    else
      users = FactoryGirl.create_list(:user, number)
      render json: users
    end
  end

  private
    def session_valid
      [:client_id, :state].each do |required_state|
        unless session.has_key?(required_state)
          return false
        end
      end
      return true
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:uid, :first_name, :last_name, :email)
    end

    def ldap_params
      params.require(:uid)
    end

    def multi_params
      params.require(:number)
    end

    def redirect_to_consumer
      consumer = Consumer.where(uuid: session[:client_id]).first
      if @user
        @token = @user.token(
          client_id: consumer.uuid,
          scope: session[:scope] || Rails.application.config.default_scope
        )
        token_ttl = $redis.ttl(@token)
        params = {
          access_token: @token,
          token_type: 'Bearer',
          state: session[:state],
          expires_in: token_ttl,
          scope: session[:scope] || Rails.application.config.default_scope
        }
      else
        params = {
          error: 'access_denied',
          state: session[:state]
        }
      end
      redirect_to(consumer.redirect_uri+'#'+params.to_query)
    end
end
