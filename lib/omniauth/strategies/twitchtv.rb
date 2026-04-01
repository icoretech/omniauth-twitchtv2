# frozen_string_literal: true

require "omniauth-oauth2"

module OmniAuth
  module Strategies
    # OmniAuth strategy for Twitch OAuth2.
    class Twitchtv < OmniAuth::Strategies::OAuth2
      option :name, "twitchtv"

      option :client_options,
        site: "https://api.twitch.tv",
        authorize_url: "https://id.twitch.tv/oauth2/authorize",
        token_url: "https://id.twitch.tv/oauth2/token",
        auth_scheme: :request_body,
        connection_opts: {
          headers: {
            user_agent: "icoretech-omniauth-twitchtv2 gem",
            accept: "application/json",
            content_type: "application/json"
          }
        }

      option :authorize_options, %i[scope force_verify]

      uid { raw_info["id"].to_s }

      info do
        {
          name: raw_info["display_name"] || raw_info["login"],
          nickname: raw_info["login"],
          email: raw_info["email"],
          image: raw_info["profile_image_url"],
          description: blank_to_nil(raw_info["description"]),
          urls: profile_url ? {twitchtv: profile_url} : nil
        }.compact
      end

      credentials do
        {
          "token" => access_token.token,
          "refresh_token" => access_token.refresh_token,
          "expires_at" => access_token.expires_at,
          "expires" => access_token.expires?,
          "scope" => token_scope
        }.compact
      end

      extra do
        {
          "raw_info" => raw_info
        }
      end

      def raw_info
        @raw_info ||= begin
          response = access_token.get("helix/users", headers: {"Client-Id" => options.client_id})
          users = response.parsed.fetch("data", [])
          users.first || {}
        end
      end

      def profile_url
        login = raw_info["login"]
        return nil if login.to_s.empty?

        "https://www.twitch.tv/#{login}"
      end

      # Ensure token exchange uses a stable callback URI that matches provider config.
      def callback_url
        options[:callback_url] || super
      end

      # Prevent authorization response params from being appended to redirect_uri.
      def query_string
        return "" if request.params["code"]

        super
      end

      private

      def token_scope
        token_params = access_token.respond_to?(:params) ? access_token.params : {}
        token_params["scope"] || (access_token["scope"] if access_token.respond_to?(:[]))
      end

      def blank_to_nil(value)
        return nil if value.respond_to?(:empty?) && value.empty?

        value
      end
    end

    Twitchtv2 = Twitchtv
  end
end

OmniAuth.config.add_camelization "twitchtv", "Twitchtv"
