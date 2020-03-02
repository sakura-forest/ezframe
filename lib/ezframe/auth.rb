module Ezframe
  class Auth
    class << self
      attr_accessor :user

      def init
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
            # mylog "valid?"
            params["account"] || params["password"]
          end

          def authenticate!
            mylog "authenticate!: #{params}"
            if Auth.authenticate(env, params["account"], params["password"])
              success!(Auth.get(params["account"]))
            else
              fail!('ユーザーが登録されていないか、パスワードが違っています。')
            end
          end
        end 
      end

      def get(account)
        new(account)
      end

      def authenticate(env, account, pass)
        @user = Model.current.db.dataset(Config[:login_table]).where(Config[:login_account].to_sym => account ).first
        if @user
          mylog "Auth: authenticate: user=#{@user.inspect}"
        else
          mylog "authenticate: this user does not exist: #{account}"
          return nil
        end
        # mylog "env=#{env.inspect}"
        env['rack.session'][:user] = @user[:id]
        password = @user[:password]
        @user.delete(:password)

        return nil if !pass || !password
        !!(password == pass)
      end
    end

    attr_accessor :account, :password, :user, :id

    def initialize(account)
      self.account = account
      dataset = Model.current.db.dataset(Config[:login_table])
      if account.is_a?(Integer)
        @user = dataset.where(id: account).first
      else
        @user = dataset.where(Config[:login_account].to_sym => account).first
      end
      unless @user
        mylog "Auth.initialize: This user does not exist: #{account}"
      end
      self.password = @user[:password]
      @user.delete(:password)
    end
  end
end
