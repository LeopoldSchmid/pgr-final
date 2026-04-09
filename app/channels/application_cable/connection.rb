module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      set_current_user || reject_unauthorized_connection
    end

    private
      def set_current_user
        if session = Session.find_by(id: session_id_from_signed_cookie)
          self.current_user = session.user
        end
      end

      def session_id_from_signed_cookie
        cookies.signed[:session_id]
      rescue ActiveSupport::MessageEncryptor::InvalidMessage, ActiveSupport::MessageVerifier::InvalidSignature
        nil
      end
  end
end
