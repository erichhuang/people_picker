require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  let(:users) { FactoryGirl.create_list(:user, 3) }
  let(:consumer) { FactoryGirl.create(:consumer) }
  let(:response_type) { 'token' }
  let(:state) { Faker::Lorem.characters(20) }
  let(:non_existent_client_id) { SecureRandom.uuid }
  let(:first_name_begins) { users.last.first_name[0,3] }
  let(:last_name_begins) { users.last.last_name[0,3] }
  let(:ldap_first_name_begins) { 'Rich' }
  let(:ldap_last_name_begins) { 'Brod' }

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

  describe 'GET #fetch' do
    subject { get :fetch, request_params }

    context 'with valid session' do
      include_context 'with authenticated session'

      context 'name query' do
        context 'existing user' do
          context 'first_name_begins query parameter' do
            let(:request_params) {{ first_name_begins: first_name_begins }}

            it_behaves_like 'a successful request' do
              it 'should return an Array of persisted unreal Users whose first name begins with the request_param' do
                returned_users = JSON.parse(@response.body)
                expect(returned_users).to have_key "users"
                expect(returned_users["users"].count).to eq(User.first_name_begins(first_name_begins).count)
                returned_users["users"].each do |user|
                  expect(user['first_name']).to start_with(first_name_begins)
                  expect(user['is_persisted']).to be true
                  expect(user['is_real']).not_to be true
                end
              end
            end
          end

          context 'last_name_begins query parameter' do
            let(:request_params) { { last_name_begins: last_name_begins } }

            it_behaves_like 'a successful request' do
              it 'should return an Array of persisted unreal Users whose last name begins with the request_param' do
                returned_users = JSON.parse(@response.body)
                expect(returned_users).to have_key "users"
                expect(returned_users["users"].count).to eq(User.last_name_begins(last_name_begins).count)
                returned_users["users"].each do |user|
                  expect(user['last_name']).to start_with(last_name_begins)
                  expect(user['is_persisted']).to be true
                  expect(user['is_real']).not_to be true
                end
              end
            end
          end

          context 'last_name_begins and first_name_begins query parameters' do
            let(:request_params) {{
              first_name_begins: first_name_begins,
              last_name_begins: last_name_begins
            }}

            it_behaves_like 'a successful request' do
              it 'should return an Array of persisted unreal Users whose names begin with the request_params' do
                returned_users = JSON.parse(@response.body)
                expect(returned_users).to have_key "users"
                expect(returned_users["users"].count).to eq(User.first_name_begins(first_name_begins).last_name_begins(last_name_begins).count)
                returned_users["users"].each do |user|
                  expect(user['first_name']).to start_with(first_name_begins)
                  expect(user['last_name']).to start_with(last_name_begins)
                  expect(user['is_persisted']).to be true
                  expect(user['is_real']).not_to be true
                end
              end
            end
          end
        end

        context 'ldap user' do
          context 'persisted' do
            let(:existing_ldap_user) { FactoryGirl.create(:user, :brodhead) }
            before do
              expect(existing_ldap_user).to be_persisted
            end

            context 'first_name_begins' do
              let(:request_params) {{
                first_name_begins: ldap_first_name_begins
              }}

              it_behaves_like 'a successful request' do
                it 'should return an Array of real persisted Users whose first name begins with the request_param' do
                  returned_users = JSON.parse(@response.body)
                  expect(returned_users).to have_key "users"
                  expect(returned_users["users"].count).to eq(User.first_name_begins(request_params[:first_name_begins]).count)
                  returned_users["users"].each do |user|
                    expect(user["first_name"]).to start_with(request_params[:first_name_begins])
                    expect(user["is_persisted"]).to be true
                    expect(user["is_real"]).to be true
                  end
                end
              end
            end

            context 'last_name_begins' do
              let(:request_params) {{
                last_name_begins: ldap_last_name_begins
              }}

              it_behaves_like 'a successful request' do
                it 'should return an Array of real persisted Users whose last name begins with the request_param' do
                  returned_users = JSON.parse(@response.body)
                  expect(returned_users).to have_key "users"
                  expect(returned_users["users"].count).to eq(User.last_name_begins(request_params[:last_name_begins]).count)
                  returned_users["users"].each do |user|
                    expect(user["last_name"]).to start_with(request_params[:last_name_begins])
                    expect(user["is_persisted"]).to be true
                    expect(user["is_real"]).to be true
                  end
                end
              end
            end

            context 'first_name_begins and last_name_begins' do
              let(:request_params) {{
                first_name_begins: ldap_first_name_begins,
                last_name_begins: ldap_last_name_begins
              }}
              it_behaves_like 'a successful request' do
                it 'should return an Array of real persisted Users whose names begin with the request_params' do
                  returned_users = JSON.parse(@response.body)
                  expect(returned_users).to have_key "users"
                  expect(returned_users["users"].count).to eq(User.first_name_begins(request_params[:first_name_begins]).last_name_begins(request_params[:last_name_begins]).count)
                  returned_users["users"].each do |user|
                    expect(user["first_name"]).to start_with(request_params[:first_name_begins])
                    expect(user["last_name"]).to start_with(request_params[:last_name_begins])
                    expect(user["is_persisted"]).to be true
                    expect(user["is_real"]).to be true
                  end
                end
              end
            end
          end

          context 'not persisted' do
            context 'first_name_begins' do
              let(:request_params) {{
                first_name_begins: ldap_first_name_begins
              }}
              before do
                expect(User.first_name_begins(request_params[:first_name_begins]).count).to eq(0)
              end

              it_behaves_like 'a successful request' do
                it 'should return an Array of real unpersisted Users whose first name begins with the request_param' do
                  returned_users = JSON.parse(@response.body)
                  expect(returned_users).to have_key "users"
                  returned_users["users"].each do |user|
                    expect(user["first_name"]).to start_with(request_params[:first_name_begins])
                    expect(user["is_persisted"]).not_to be true
                    expect(user["is_real"]).to be true
                  end
                end
              end
            end

            context 'last_name_begins' do
              let(:request_params) {{
                last_name_begins: ldap_last_name_begins
              }}
              before do
                expect(User.last_name_begins(request_params[:last_name_begins]).count).to eq(0)
              end

              it_behaves_like 'a successful request' do
                it 'should return an Array of real unpersisted Users whose last name begins with the request_param' do
                  returned_users = JSON.parse(@response.body)
                  expect(returned_users).to have_key "users"
                  returned_users["users"].each do |user|
                    expect(user["last_name"]).to start_with(request_params[:last_name_begins])
                    expect(user["is_persisted"]).not_to be true
                    expect(user["is_real"]).to be true
                  end
                end
              end
            end

            context 'first_name_begins and last_name_begins' do
              let(:request_params) {{
                first_name_begins: ldap_first_name_begins,
                last_name_begins: ldap_last_name_begins
              }}

              before do
                expect(User.first_name_begins(request_params[:first_name_begins]).last_name_begins(request_params[:last_name_begins]).count).to eq(0)
              end

              it_behaves_like 'a successful request' do
                it 'should return an Array of real unpersisted Users whose names begin with the request_params' do
                  returned_users = JSON.parse(@response.body)
                  expect(returned_users).to have_key "users"
                  returned_users["users"].each do |user|
                    expect(user["first_name"]).to start_with(request_params[:first_name_begins])
                    expect(user["last_name"]).to start_with(request_params[:last_name_begins])
                    expect(user["is_persisted"]).not_to be true
                    expect(user["is_real"]).to be true
                  end
                end
              end
            end
          end
        end

        context 'non-existent user' do
          context 'first_name_begins' do
            let(:request_params) {{
              first_name_begins: 'not3xists',
            }}

            it_behaves_like 'a successful request' do
              it 'should return an empty Array' do
                returned_users = JSON.parse(@response.body)
                expect(returned_users).to have_key "users"
                expect(returned_users["users"].count).to eq(0)
              end
            end
          end

          context 'last_name_begins' do
            let(:request_params) {{
              last_name_begins: 'not3xistsus'
            }}

            it_behaves_like 'a successful request' do
              it 'should return an empty Array' do
                returned_users = JSON.parse(@response.body)
                expect(returned_users).to have_key "users"
                expect(returned_users["users"].count).to eq(0)
              end
            end
          end

          context 'first_name_begins and last_name_begins' do
            let(:request_params) {{
              first_name_begins: 'not3xists',
              last_name_begins: 'not3xistsus'
            }}

            it_behaves_like 'a successful request' do
              it 'should return an empty Array' do
                returned_users = JSON.parse(@response.body)
                expect(returned_users).to have_key "users"
                expect(returned_users["users"].count).to eq(0)
              end
            end
          end
        end

        context 'without parameters' do
          let(:request_params) { {} }
          it_behaves_like 'an unexpected request'
        end
      end

      context 'number=y' do
        let(:request_params) { {number: requested_count} }
        context 'y <=5' do
          let(:requested_count) { 3 }
          before do
            users.map {|u| expect(u).to be_persisted}
          end

          it_behaves_like 'a successful request' do
            it 'should return a JSON array of fake unpersisted Users' do
              users = JSON.parse(@response.body)
              expect(users).to have_key "users"
              expect(users["users"].count).to eq(requested_count)
              users["users"].each do |user|
                expect(user['is_persisted']).to be false
                expect(user['is_real']).to be false
              end
            end
          end
        end

        context 'y > 5' do
          let(:requested_count) { 6 }
          it_behaves_like 'an unexpected request'
        end
      end
    end

    context 'without session' do
      context 'name query' do
        let(:request_params) {{
          first_name_begins: first_name_begins,
          last_name_begins: last_name_begins
        }}
        it_behaves_like 'an unexpected request'
      end

      context 'number=y' do
        let(:request_params) { {number: 5} }
        it_behaves_like 'an unexpected request'
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
