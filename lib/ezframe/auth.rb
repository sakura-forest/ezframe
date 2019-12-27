module Ezframe
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
          inst = Auth.get(env['model'], account)
          mylog "inst = #{inst.inspect}"
          inst
        end
        Warden::Strategies.add(:mystrategy) do
          def valid?
            # mylog "valid?"
            params["account"] || params["password"]
          end

          def authenticate!
            mylog "authenticate!: #{params}"
            if Auth.authenticate(env, params["account"], params["password"])
              success!(Auth.get(env['model'], params["account"]))
            else
              env['x-rack.flash'].error = 'ユーザーが登録されていないか、パスワードが違っています。'
              fail!("authenticate failure")
            end
          end
        end 
      end

      def get(model, account)
        new(model, account)
      end

      def authenticate(env, account, pass)
        model = env["model"]
        raise "model is not initialized" unless model
        @user = model.db.dataset(:user).where(account: account).first
        if @user
          mylog "Auth: authenticate: user=#{@user.inspect}"
        else
          mylog "authenticate: this user does not exist: #{account}"
          return nil
        end
        mylog "env=#{env.inspect}"
        env['rack.session'][:user] = @user[:id]
        password = @user[:password]
        @user.delete(:password)

        return nil if !pass || !password
        !!(password == pass)
      end
    end

    attr_accessor :account, :password, :model, :user, :id

    def initialize(model, account)
      self.account = account
      @user = model.db.dataset(:user).where(Sequel.or(account: account, id: account)).first
      unless @user
        mylog "Auth.initialize: This user does not exist: #{account}"
      end
      self.password = @user[:password]
      @user.delete(:password)
    end
  end
end
