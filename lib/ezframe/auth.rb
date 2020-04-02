module Ezframe
  class Auth
    class << self
      attr_accessor :user

      def init
        Warden::Manager.serialize_into_session do |auth|
          # Logger.info "serialize_into: #{auth.inspect}"
          auth.user[:id]
        end
        Warden::Manager.serialize_from_session do |account|
          # Logger.info "serialize_from: account = #{account}"
          inst = Auth.get(account)
          # Logger.info "inst = #{inst.inspect}"
          inst
        end
        Warden::Strategies.add(:mystrategy) do
          def valid?
            # Logger.info "valid?"
            params["account"] || params["password"]
          end

          def authenticate!
            Logger.info "authenticate!: #{params}"
            if Auth.authenticate(env, params["account"], params["password"])
              success!(Auth.get(params["account"]))
            else
              fail!(Message[:login_failure])
            end
          end
        end 
      end

      def get(account)
        new(account)
      end

      def authenticate(env, account, pass)
        auth_conf = Config[:auth]
        @user = DB.dataset(auth_conf[:table]).where(auth_conf[:user].to_sym => account ).first
        if @user
          Logger.info "Auth: authenticate"
        else
          Logger.info "authenticate: this user does not exist: #{account}"
          return nil
        end
        # Logger.info "env=#{env.inspect}"
        env['rack.session'][:user] = @user[:id]
        password = @user[auth_conf[:password].to_sym]
        bcrypt = BCrypt::Password.new(password)
        @user.delete(:password)

        return nil if !pass || pass.strip.empty? || !password || password.strip.empty?
        # 生パスワード比較
        # !!(password == pass)
        return bcrypt == pass
      end
    end

    attr_accessor :account, :password, :user, :id

    def initialize(account)
      self.account = account
      auth_conf = Config[:auth]
      dataset = DB.dataset(auth_conf[:table])
      if account.is_a?(Integer)
        @user = dataset.where(id: account).first
      else
        @user = dataset.where(auth_conf[:user].to_sym => account).first
      end
      unless @user
        Logger.error "Auth.initialize: This user does not exist: #{account}"
        return
      end
      self.password = @user[auth_conf[:password].to_sym]
      @user.delete(:password)
    end
  end
end
