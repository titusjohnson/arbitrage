require 'rails_helper'

RSpec.describe "Authentication", type: :request do
  describe "landing page" do
    context "when not authenticated" do
      it "displays the Log In link" do
        get root_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Log In")
        expect(response.body).not_to include("Log Out")
      end
    end

    context "when authenticated" do
      let(:user) { create(:user) }

      it "displays Welcome and Log Out link" do
        # Log in by posting to session
        post session_path, params: {
          email_address: user.email_address,
          password: "password123"
        }

        # Now visit root
        get root_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Welcome!")
        expect(response.body).to include("Log Out")
        expect(response.body).not_to match(/>\s*Log In\s*</)
      end
    end
  end

  describe "POST /session (login)" do
    let!(:user) { create(:user, email_address: "test@example.com") }

    context "with valid credentials" do
      it "logs in the user and redirects to root" do
        post session_path, params: {
          email_address: "test@example.com",
          password: "password123"
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!

        expect(response.body).to include("Welcome!")
        expect(response.body).to include("Log Out")
      end

      it "creates a new session record" do
        expect {
          post session_path, params: {
            email_address: "test@example.com",
            password: "password123"
          }
        }.to change { Session.count }.by(1)

        session = Session.last
        expect(session.user).to eq(user)
        expect(session.ip_address).to be_present
      end
    end

    context "with invalid credentials" do
      it "redirects back to login with an alert" do
        post session_path, params: {
          email_address: "test@example.com",
          password: "wrongpassword"
        }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to be_present
      end

      it "does not create a session record" do
        expect {
          post session_path, params: {
            email_address: "test@example.com",
            password: "wrongpassword"
          }
        }.not_to change { Session.count }
      end
    end

    context "with non-existent user" do
      it "redirects back to login" do
        post session_path, params: {
          email_address: "nonexistent@example.com",
          password: "password123"
        }

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /session (logout)" do
    let!(:user) { create(:user, email_address: "logout@example.com") }

    it "logs out the user and redirects to root" do
      # First log in
      post session_path, params: {
        email_address: user.email_address,
        password: "password123"
      }

      # Then log out
      delete session_path

      expect(response).to redirect_to(root_path)
      follow_redirect!

      expect(response.body).to include("Log In")
      expect(response.body).not_to include("Log Out")
    end

    it "destroys the session record" do
      # Log in first
      post session_path, params: {
        email_address: user.email_address,
        password: "password123"
      }

      expect {
        delete session_path
      }.to change { Session.count }.by(-1)
    end
  end

  describe "full authentication flow" do
    let!(:user) { create(:user, email_address: "user@example.com") }

    it "allows a user to log in and log out" do
      # Visit root - should see Log In
      get root_path
      expect(response.body).to include("Log In")

      # Log in with valid credentials
      post session_path, params: {
        email_address: "user@example.com",
        password: "password123"
      }
      expect(response).to redirect_to(root_path)

      # Visit root - should see Welcome and Log Out
      follow_redirect!
      expect(response.body).to include("Welcome!")
      expect(response.body).to include("Log Out")

      # Log out
      delete session_path
      expect(response).to redirect_to(root_path)

      # Visit root - should see Log In again
      follow_redirect!
      expect(response.body).to include("Log In")
      expect(response.body).not_to include("Welcome!")
    end
  end
end
