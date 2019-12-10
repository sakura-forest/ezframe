module Ezframe
  #  class BaseStrategy < Warden::Strategies::Base
  #  end

  class Auth
    class << self
      attr_accessor :model, :user

      def init_warden
        Warden::Manager.serialize_into_session do |auth|
          mylog "serialize_into: #{auth.inspect}"
          auth.user[:id]
        end
        Warden::Manager.serialize_from_session do |account|
          mylog "serialize_from: account = #{account}"
          inst = Auth.get(account)
          mylog "inst = #{inst.inspect}"
          inst
        end
        Warden::Strategies.add(:mystrategy) do
          def valid?
            mylog "valid?"
            params["account"] || params["password"]
          end

          def authenticate!
            mylog "authenticate!"
            if Auth.authenticate(params["account"], params["password"])
              success!(Auth.get(params["account"]))
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
        mylog "Auth: authenticate: user=#{@user.inspect}"
        password = @user[:password]
        return nil if !pass || !password
        !!(password == pass)
      end
    end

    attr_accessor :account, :password, :model, :user, :id

    def initialize(account)
      self.account = account
      @user = Auth.model.db.dataset(:user).where(Sequel.or(account: account, id: account)).first
      self.password = @user[:password]
    end
  end
end
