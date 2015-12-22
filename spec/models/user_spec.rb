require 'rails_helper'

RSpec.describe User, type: :model do
  subject { FactoryGirl.create(:user) }
  let(:scope) { Rails.application.config.default_scope }
  let(:min_secs) { 3 * 60 * 60 }
  let(:full_expire) { 4 * 60 * 60 }
  let(:consumer) { FactoryGirl.create(:consumer) }
  let(:expected_credentials) { {
      client_id: consumer.uuid,
      scope: scope,
      uid: subject.uid,
      first_name: subject.first_name,
      last_name: subject.last_name,
      display_name: subject.display_name,
      email: subject.email
    }
  }

  it 'should require a unique uid' do
    should validate_presence_of(:uid)
    should validate_uniqueness_of(:uid)
  end

  describe 'user.display_name' do
    it 'should be supported' do
      expect(subject).to respond_to 'display_name'
    end
  end

  describe 'user.token' do
    it 'should require a client_id and scope' do
      expect(subject).to respond_to 'token'
      expect{
        subject.token()
      }.to raise_error(ArgumentError)
      expect{
        subject.token(client_id: consumer.uuid)
      }.to raise_error(ArgumentError)
      expect{
        subject.token(client_id: consumer.uuid,
                      scope: scope)
      }.not_to raise_error
    end

    it 'should create a hex string token, set the value to JSON serialized hash of the user credentials with an expire of 4 hours, and return the generated token' do
      token = subject.token(
            client_id: consumer.uuid,
            scope: scope)
      expect(token).to be
      stored_user_info_json = $redis.get(token)
      expect(stored_user_info_json).to be
      stored_user_info = JSON.parse(stored_user_info_json)
      expected_ttl = $redis.ttl(token)
      expect(expected_ttl).not_to eq(-1)
      expect(expected_ttl).to be > min_secs
      expect(expected_ttl).to be <= full_expire
      expect(stored_user_info.symbolize_keys!).to eq(expected_credentials)
    end

    describe 'required user attributes' do
      let(:invalid_user) { FactoryGirl.build(:user, first_name: nil, last_name: nil, email: nil) }
      let(:token_call) { invalid_user.token(client_id: consumer.uuid, scope: scope) }

      it 'should require user to have a first_name, last_name, display_name, and email' do
        expect{
          token_call
        }.to raise_error(ArgumentError)
        invalid_user.first_name = subject.first_name
        expect{
          token_call
        }.to raise_error(ArgumentError)
        invalid_user.last_name = subject.last_name
        expect{
          token_call
        }.to raise_error(ArgumentError)
        invalid_user.email = subject.email
        expect{
          token_call
        }.not_to raise_error
      end
    end
  end

  describe 'User.credentials(token)' do
    let(:token) {
      subject.token(
        client_id: consumer.uuid,
        scope: scope
      )
    }

    it 'should require a token' do
      expect(User).to respond_to 'credentials'
      expect{
        User.credentials()
      }.to raise_error(ArgumentError)
      expect{
        User.credentials(token)
      }.not_to raise_error
    end

    it 'should return a hash with key info equal to the credentials stored for the user, and expires_in equal to the expiration, if the token exists' do
      expect($redis.exists(token)).to be
      credentials = User.credentials(token)
      expected_ttl = $redis.ttl(token)
      expect(credentials).to have_key(:info)
      expect(JSON.parse(credentials[:info]).symbolize_keys!).to eq(expected_credentials)
      expect(credentials).to have_key(:expires_in)
      expect(credentials[:expires_in]).to eq(expected_ttl)
    end

    it 'should return nil if the token does not exist' do
      $redis.del(token)
      expect($redis.exists(token)).not_to be
      expect(User.credentials(token)).to be_nil
    end
  end

  describe 'User.first_name_begins' do
    let(:users) { FactoryGirl.create_list(:user, 5)}
    let(:first_name_begins) { users.first.first_name[0,3] }
    subject { User.first_name_begins(first_name_begins) }

    it 'should take a string and return only users with first name beginning with the string' do
      expect(subject.count).to eq(User.where('first_name like ?', "#{first_name_begins}%").count)
      subject.each do |ruser|
        expect(ruser.first_name).to start_with first_name_begins
      end
    end
  end

  describe 'User.last_name_begins' do
    let(:users) { FactoryGirl.create_list(:user, 5)}
    let(:last_name_begins) { users.first.first_name[0,3] }
    subject { User.last_name_begins(last_name_begins) }

    it 'should take a string and return only users with last name beginning with the string' do
      expect(subject.count).to eq(User.where('last_name like ?', "#{last_name_begins}%").count)
      subject.each do |ruser|
        expect(ruser.last_name).to start_with last_name_begins
      end
    end
  end
end
