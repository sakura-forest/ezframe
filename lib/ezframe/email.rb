require "mail"

module Ezframe
  class Email
    class << self
      def receive

      end

      # options =
      #      :address              => "smtp.server.host",
      #      :port                 => 1025,
      #      :user_name            => login user,
      #      :password             => login password,
      #      :authentication       => 'plain',
      #      :ssl => true,
      def setup_smtp(options)
        Mail.defaults do
          delivery_method :smtp, options
        end
      end

      def send(data)
        mail = Mail.new do
          from     data[:mail_from]
          to       data[:mail_to]
          subject  data[:subject]
          body     data[:body]
        end
        mail.deliver! 
      end
    end
  end
