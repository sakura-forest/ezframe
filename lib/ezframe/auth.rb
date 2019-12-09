module Ezframe
  #  class BaseStrategy < Warden::Strategies::Base
  #  end

  class Auth
    class << self
      attr_accessor :model, :user

      def init_warden
        Warden::Manager.serialize_into_session do |auth|
          auth.user[:id]
        end
        Warden::Manager.serialize_from_session do |account|
          Auth.get(account)
        end
        Warden::Strategies.add(:base) do
          def valid?
            params["account"] || params["password"]
          end

          def authenticate!
            if Auth.authenticate(params["account"], params["password"])
              success!(Auth.get(params["acccount"]))
            else
              fail!("failll")
            end
          end
        end
      end

      def get(account)
        new(account)
      end

      def authenticate(account, pass)
        raise "model is not initialized" unless @model
        @user = @model.db.dataset(:user).where(account: account).first
        mylog "authenticate: user=#{@user.inspect}"
        password = @user[:password]
        return nil if !pass || !password
        !!(password == pass)
      end
    end

    attr_accessor :account, :password, :model, :user

    def initialize(account)
      self.account = account
      @user = Auth.model.db.dataset(:user).where(account: account)
      self.password = @user[:password]
    end
  end
end
