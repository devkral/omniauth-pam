module OmniAuth
  module Strategies
    class PAM
      include OmniAuth::Strategy

      option :name, 'pam'
      option :fields, [:username]
      option :uid_field, :username

      # this map is used to return gecos in info
      option :gecos_map, [:name, :location, :phone, :home_phone, :description]
      # option :email_domain - if defined, info.email is build using uid@email_domain if not found from gecos
      # option :service - pam service name passed to rpam (/etc/pam.d/service_name), if not given rpam uses 'rpam'

      def request_phase
        OmniAuth::Form.build(
          :title => (options[:title] || "Authenticate"), 
          :url => callback_path
        ) do |field|
          field.text_field 'Username', 'username'
          field.password_field 'Password', 'password'
        end.to_response
      end

      def callback_phase
        rpam_opts = Hash.new
        rpam_opts[:service] = options[:service] unless options[:service].nil?

        unless Rpam.auth(request['username'], request['password'], rpam_opts)
          return fail!(:invalid_credentials)
        end

        super
      end

      uid do
        request['username']
      end

      info do
        info = { :nickname => uid, :name => uid }
        info[:email] = "#{uid}@#{options[:email_domain]}" if options.has_key?(:email_domain)
        info.merge!(parse_gecos || {})
      end

      private

      def parse_gecos
        if options[:gecos_map].kind_of?(Array)
          begin
            gecos = Etc.getpwnam(uid).gecos.split(',')
            Hash[options[:gecos_map].zip(gecos)].delete_if { |k, v| v.nil? || v.empty? }
          rescue
          end
        end
      end
    end
  end
end

OmniAuth.config.add_camelization 'pam', 'PAM'
