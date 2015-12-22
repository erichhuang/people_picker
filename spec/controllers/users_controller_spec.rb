require 'rails_helper'

RSpec.describe UsersController, type: :controller do

  let(:users) { FactoryGirl.create_list(:user, 5) }
  let(:consumer) { FactoryGirl.create(:consumer) }
  let(:response_type) { 'token' }
  let(:state) { Faker::Lorem.characters(20) }
  let(:non_existent_client_id) { SecureRandom.uuid }

  describe "GET #index" do
    subject { get :index, request_params }

    context 'with valid initiation parameters' do
      let(:request_params) { {
          client_id: consumer.uuid,
          response_type: response_type,
          scope: Rails.application.config.default_scope,
          state: state
      } }

      it_behaves_like 'a successful request' do
        it { expect(session[:client_id]).to eq(consumer.uuid) }
        it { expect(session[:state]).to eq(state) }
      end
    end

    context 'without parameters' do
      let(:request_params) {{}}
      it_behaves_like 'an unexpected request'
    end

    context 'with non-existent consumer' do
      let(:request_params) { {
        client_id: non_existent_client_id,
        response_type: response_type,
        scope: Rails.application.config.default_scope,
        state: state
      } }
      it { expect(non_existent_client_id).not_to eq(consumer.uuid) }
      it { expect(Consumer.where(uuid: non_existent_client_id)).not_to exist }
      it_behaves_like 'an unexpected request'
    end

    context 'without state parameter' do
      let(:request_params) { {
        client_id: consumer.uuid,
        response_type: response_type,
        scope: Rails.application.config.default_scope
      } }
      it_behaves_like 'an unexpected request'
    end
  end

  describe 'GET #fetch_existing' do
    subject { get :fetch_existing, request_params }

    context 'with first_name_begins query parameter' do
      let(:first_name_begins) { users.last.first_name[0,3] }
      let(:request_params) {{ first_name_begins: first_name_begins }}

      context 'with valid session' do
        include_context 'with authenticated session'
        it_behaves_like 'a successful request' do
          it 'should return an Array of Users whose first name begins with the request_param' do
            returned_users = JSON.parse(@response.body)
            expect(returned_users).to have_key "users"
            expect(returned_users["users"].count).to eq(User.first_name_begins(first_name_begins).count)
            returned_users["users"].each do |user|
              expect(user['first_name']).to start_with(first_name_begins)
            end
          end
        end
      end

      context 'without session' do
        let(:request_params) {{}}
        it_behaves_like 'an unexpected request'
      end
    end

    context 'with last_name_begins query parameter' do
      let(:last_name_begins) { users.last.last_name[0,3] }
      let(:request_params) { { last_name_begins: last_name_begins } }

      context 'with valid session' do
        include_context 'with authenticated session'
        it_behaves_like 'a successful request' do
          it 'should return an Array of Users whose last name begins with the request_param' do
            returned_users = JSON.parse(@response.body)
            expect(returned_users).to have_key "users"
            expect(returned_users["users"].count).to eq(User.last_name_begins(last_name_begins).count)
            returned_users["users"].each do |user|
              expect(user['last_name']).to start_with(last_name_begins)
            end
          end
        end
      end

      context 'without session' do
        it_behaves_like 'an unexpected request'
      end
    end

    context 'with last_name_begins and first_name_begins query parameters together' do
      let(:first_name_begins) { users.last.first_name[0,3] }
      let(:last_name_begins) { users.last.last_name[0,3] }
      let(:request_params) {{
        first_name_begins: first_name_begins,
        last_name_begins: last_name_begins
      }}

      context 'with valid session' do
        include_context 'with authenticated session'
        it_behaves_like 'a successful request' do
          it 'should return an Array of Users whose last name begins with the request_param' do
            returned_users = JSON.parse(@response.body)
            expect(returned_users).to have_key "users"
            expect(returned_users["users"].count).to eq(User.first_name_begins(first_name_begins).last_name_begins(last_name_begins).count)
            returned_users["users"].each do |user|
              expect(user['first_name']).to start_with(first_name_begins)
              expect(user['last_name']).to start_with(last_name_begins)
            end
          end
        end
      end

      context 'without parameters' do
        let(:request_params) { {} }
        context 'with valid session' do
          include_context 'with authenticated session'
          it_behaves_like 'an unexpected request'
        end
        context 'without session' do
          it_behaves_like 'an unexpected request'
        end
      end
    end
  end

  describe "GET #use" do
    subject { get :use, request_params }
    let(:request_params) {{ id: users[0].id }}

    context 'with valid session' do
      include_context 'with authenticated session'

      it_behaves_like 'a successful redirect' do
        include_context 'with consumer redirect url'
        let(:token_params) { {
          access_token: token,
          token_type: 'Bearer',
          state: session[:state],
          expires_in: token_ttl,
          scope: Rails.application.config.default_scope
        } }

        it "assigns the requested user as @user" do
          expect(assigns(:user)).to be
          expect(assigns(:user).uid).to eq(users[0].uid)
        end
      end
    end

    context 'without session' do
      it 'responds with 401 and invalid_request' do
        is_expected.to be
        expect(response.status).to eq(401)
        expect(response.body).to eq('invalid_request')
      end
    end
  end

  describe 'GET stats' do
    subject { get :stats }

    context 'with valid session' do
      include_context 'with authenticated session'
      it_behaves_like 'a successful request' do
        it 'should return JSON stats' do
          stats = JSON.parse(@response.body)
          expect(stats).to have_key('user_count')
          expect(stats['user_count']).to equal(User.count)
        end
      end
    end

    context 'without session' do
      it_behaves_like 'an unexpected request'
    end
  end

  describe 'GET fetch_ldap' do
    subject { get :fetch_ldap, request_params }
    context 'with valid session' do
      include_context 'with authenticated session'

      context 'with valid uid' do
        let(:request_params) { {uid: 'brodhead'} }
        let(:expected_response) {
          {
            "uid" => 'brodhead',
            "first_name" => 'Richard',
            "last_name" => 'Brodhead',
            "email" => 'president@duke.edu'
          }
        }
        it_behaves_like 'a successful request' do
          it 'should return JSON User' do
            user = JSON.parse(@response.body)
            expected_response.keys.each do |ekey|
              expect(user).to have_key ekey
              expect(user[ekey]).to eq(expected_response[ekey])
            end
          end
        end
      end

      context 'with non existent uid' do
        let(:request_params) { {uid: 'notexist'} }
        it_behaves_like 'a successful request' do
          it 'should return empty JSON User' do
            user = JSON.parse(@response.body)
            expect(user).to be_empty
          end
        end
      end
    end

    context 'without session' do
      let(:request_params) { {} }
      it_behaves_like 'an unexpected request'
    end
  end

  describe 'GET feeling_lucky' do
    subject { get :feeling_lucky}

    context 'with valid session' do
      include_context 'with authenticated session'
      let(:expected_response_keys) {
        %w(uid first_name last_name email)
      }
      it_behaves_like 'a successful request' do
        it 'should return a JSON User with random attribute values' do
          user = JSON.parse(@response.body)
          expected_response_keys.each do |ekey|
            expect(user).to have_key ekey
            expect(user[ekey]).to be
          end
        end
      end
    end

    context 'without session' do
      it_behaves_like 'an unexpected request'
    end
  end

  describe 'POST #create_multi' do
    subject { post :create_multi, request_params }

    context 'with valid session' do
      include_context 'with authenticated session'
      let(:expected_response_keys) {
        %w(uid first_name last_name email)
      }

      context 'with number <= 5' do
        let(:requested_count) { 4 }
        let(:request_params) { {number: requested_count} }
        it 'should create and return an array of random JSON Users' do
          expect { subject }.to change{User.count}.by(requested_count)
          users = JSON.parse(@response.body)
          expect(users).to have_key "users"
          expect(users["users"].count).to eq(requested_count)
          users["users"].each do |user|
            expected_response_keys.each do |ekey|
              expect(user).to have_key ekey
              expect(user[ekey]).to be
            end
          end
        end
      end

      context 'with number > 5' do
        let(:requested_count) { 6 }
        let(:request_params) { {number: requested_count} }
        it_behaves_like 'an unexpected request'
      end
    end

    context 'without session' do
      let(:requested_count) { 4 }
      let(:request_params) { {number: requested_count} }
      it_behaves_like 'an unexpected request'
    end
  end

  describe "POST #create" do
    let(:user_to_create) { FactoryGirl.attributes_for(:user) }
    subject { post :create, request_params }
    let(:request_params) { {user: user_to_create } }

    context 'with session' do
      include_context 'with authenticated session'

      it 'should create the user' do
        expect { subject }.to change{User.count}.by(1)
        expect(assigns(:user)).to be
        expect(assigns(:user)).to be_persisted
        expect(assigns(:user).first_name).to eq(user_to_create[:first_name])
        expect(assigns(:user).last_name).to eq(user_to_create[:last_name])
        expect(assigns(:user).email).to eq(user_to_create[:email])
      end
    end
    context 'without session' do
      it_behaves_like 'an unexpected request'
    end
  end
end
