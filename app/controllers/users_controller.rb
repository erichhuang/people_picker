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

  def fetch
    unless session_valid
      render plain: 'invalid_request', status: 401, layout: false
      return
    end
    unless params.has_key?(:number) || params.has_key?(:first_name_begins) || params.has_key?(:last_name_begins)
      render plain: 'invalid_request', status: 401, layout: false
      return
    end

    if params[:number]
      fetch_multi
    else
      @scope = User.unscoped
      if params[:first_name_begins]
        @scope = @scope.first_name_begins(params[:first_name_begins])
      end
      if params[:last_name_begins]
        @scope = @scope.last_name_begins(params[:last_name_begins])
      end

      if @scope.count > 0
        render json: @scope.all, layout: false
      else
        fetch_ldap
      end
    end
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

  def create
    unless session_valid
      render plain: 'invalid_request', status: 401, layout: false
      return
    end
    @user = User.new(user_params)
    @user.is_real = false
    respond_to do |format|
      if @user.save
        format.html { render json: @user, layout: false }
      else
        validation_errors = {}
        @user.errors.messages.each do |field, errors|
          errors.each do |message|
            validation_errors[field] = message
          end
        end
        format.html { render json: validation_errors, layout: false }
      end
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

    def user_params
      params.require(:user).permit(:uid, :first_name, :last_name, :email, :is_real)
    end

    def multi_params
      params.require(:number)
    end

    def fetch_multi
      number = multi_params.to_i
      if number > 5
        render plain: 'invalid_request', status: 401, layout: false
      else
        users = FactoryGirl.build_list(:user, number)
        render json: users, layout: false
      end
    end

    def fetch_ldap
      if params[:first_name_begins] && params[:first_name_begins].length < 3
        render json: [], layout: false
        return
      end

      if params[:last_name_begins] && params[:last_name_begins].length < 3
        render json: [], layout: false
        return
      end

      ldap = Net::LDAP.new(
        host: Rails.application.secrets.ldap_host,
        port: Rails.application.secrets.ldap_port,
        base: Rails.application.secrets.ldap_base
      )
      users = []
      filter = false
      if params[:first_name_begins] && params[:last_name_begins]
        filter = Net::LDAP::Filter.join(
          Net::LDAP::Filter.construct("givenName=#{params[:first_name_begins]}*"),
          Net::LDAP::Filter.construct("sn=#{params[:last_name_begins]}*")
        )
      elsif params[:first_name_begins]
        filter = Net::LDAP::Filter.construct("givenName=#{params[:first_name_begins]}*")
      else
        filter = Net::LDAP::Filter.construct("sn=#{params[:last_name_begins]}*")
      end
      ldap.search(
        filter: filter,
        attributes: %w(uid sn givenName mail eduPersonPrincipalName)
      ) { |entry|
        if entry.attribute_names.include?(:uid) || entry.attribute_names.include?(:eduPersonPrincipalName)
          users << User.new(
            uid: entry.attribute_names.include?(:uid) ? entry.uid.first : entry.eduPersonPrincipalName.first.gsub(/\@.*/,""),
            first_name: entry.givenName.first,
            last_name: entry.sn.first,
            email: entry.attribute_names.include?(:mail) ? entry.mail.first : entry.eduPersonPrincipalName.first,
            is_real: true
          )
        end
      }
      render json: users, layout: false
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
