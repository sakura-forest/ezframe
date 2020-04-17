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
            Logger.info "mystrategy.authenticate!: user=#{user}, params=#{params}"
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
        return nil if !pass || pass.strip.empty?
        Logger.debug("Auth.self.authenticate: account=#{account}, pass=#{pass}")
        auth_conf = Config[:auth]
        user_data = DB.dataset(auth_conf[:table]).where(auth_conf[:user].to_sym => account ).first
        if user_data
          Logger.info "Auth: self.authenticate: has user: #{@user}"
        else
          Logger.info "Auth.self.authenticate: this user does not exist: #{account}"
          return nil
        end
        db_pass = user_data[auth_conf[:password].to_sym]
        user_data.delete(:password)
        return nil if !db_pass || db_pass.strip.length < 8
        bcrypt = BCrypt::Password.new(db_pass)
        if bcrypt == pass
          env['rack.session'][:user] = user_data[:id]
          @user = user_data
          Logger.debug("Auth.self.authenticate: success: password match!")
        else
          Logger.debug("Auth.self.authenticate: failure: password mismatch")
        end
        return nil
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

    def inspect
      "account=#{@account}, user=#{@user}, id=#{@id}"
    end
  end
end
