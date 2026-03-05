# frozen_string_literal: true

require_relative 'test_helper'

require 'uri'

class OmniauthTwitchtvTest < Minitest::Test
  def build_strategy
    OmniAuth::Strategies::Twitchtv.new(nil, 'client-id', 'client-secret')
  end

  def test_uses_current_twitch_endpoints
    client_options = build_strategy.options.client_options

    assert_equal 'https://api.twitch.tv', client_options.site
    assert_equal 'https://id.twitch.tv/oauth2/authorize', client_options.authorize_url
    assert_equal 'https://id.twitch.tv/oauth2/token', client_options.token_url
    assert_equal :request_body, client_options.auth_scheme
  end

  def test_uid_info_and_extra_are_derived_from_raw_info
    strategy = build_strategy
    payload = {
      'id' => '12345678',
      'login' => 'sample_user',
      'display_name' => 'Sample User',
      'email' => 'sample@example.test',
      'profile_image_url' => 'https://example.test/avatar.png',
      'description' => 'Streaming something cool'
    }

    strategy.instance_variable_set(:@raw_info, payload)

    assert_equal '12345678', strategy.uid
    assert_equal(
      {
        name: 'Sample User',
        nickname: 'sample_user',
        email: 'sample@example.test',
        image: 'https://example.test/avatar.png',
        description: 'Streaming something cool',
        urls: { twitchtv: 'https://www.twitch.tv/sample_user' }
      },
      strategy.info
    )
    assert_equal({ 'raw_info' => payload }, strategy.extra)
  end

  def test_info_handles_sparse_payload_without_optional_fields
    strategy = build_strategy
    payload = {
      'id' => '12345678',
      'login' => 'sample_user',
      'display_name' => 'sample_user',
      'description' => ''
    }

    strategy.instance_variable_set(:@raw_info, payload)

    assert_equal(
      {
        name: 'sample_user',
        nickname: 'sample_user',
        urls: { twitchtv: 'https://www.twitch.tv/sample_user' }
      },
      strategy.info
    )
  end

  def test_raw_info_calls_helix_users_endpoint_and_memoizes
    strategy = build_strategy
    token = FakeAccessToken.new(
      {
        'data' => [
          {
            'id' => '12345678',
            'login' => 'sample_user'
          }
        ]
      }
    )

    strategy.define_singleton_method(:access_token) { token }

    first_call = strategy.raw_info
    second_call = strategy.raw_info

    assert_equal({ 'id' => '12345678', 'login' => 'sample_user' }, first_call)
    assert_same first_call, second_call
    assert_equal 1, token.calls.length
    assert_equal 'helix/users', token.calls.first[:path]
    assert_equal({ headers: { 'Client-Id' => 'client-id' } }, token.calls.first[:options])
  end

  def test_credentials_include_refresh_token_even_when_token_does_not_expire
    strategy = build_strategy
    token = FakeCredentialAccessToken.new(
      token: 'access-token',
      refresh_token: 'refresh-token',
      expires_at: nil,
      expires: false,
      params: { 'scope' => 'user:read:email' }
    )

    strategy.define_singleton_method(:access_token) { token }

    assert_equal(
      {
        'token' => 'access-token',
        'refresh_token' => 'refresh-token',
        'expires' => false,
        'scope' => 'user:read:email'
      },
      strategy.credentials
    )
  end

  def test_callback_url_prefers_configured_value
    strategy = build_strategy
    callback = 'https://example.test/auth/twitchtv/callback'
    strategy.options[:callback_url] = callback

    assert_equal callback, strategy.callback_url
  end

  def test_request_phase_redirects_to_twitch_with_expected_params
    previous_request_validation_phase = OmniAuth.config.request_validation_phase
    OmniAuth.config.request_validation_phase = nil

    app = ->(_env) { [404, { 'Content-Type' => 'text/plain' }, ['not found']] }
    strategy = OmniAuth::Strategies::Twitchtv.new(app, 'client-id', 'client-secret')
    env = Rack::MockRequest.env_for('/auth/twitchtv', method: 'POST')
    env['rack.session'] = {}

    status, headers, = strategy.call(env)

    assert_equal 302, status
    location = URI.parse(headers['Location'])
    params = URI.decode_www_form(location.query).to_h

    assert_equal 'id.twitch.tv', location.host
    assert_equal 'client-id', params.fetch('client_id')
  ensure
    OmniAuth.config.request_validation_phase = previous_request_validation_phase
  end

  def test_query_string_is_ignored_during_callback_request
    strategy = build_strategy
    request = Rack::Request.new(Rack::MockRequest.env_for('/auth/twitchtv/callback?code=abc&state=xyz'))
    strategy.define_singleton_method(:request) { request }

    assert_equal '', strategy.query_string
  end

  def test_query_string_is_kept_for_non_callback_requests
    strategy = build_strategy
    request = Rack::Request.new(Rack::MockRequest.env_for('/auth/twitchtv?force_verify=true'))
    strategy.define_singleton_method(:request) { request }

    assert_equal '?force_verify=true', strategy.query_string
  end

  class FakeAccessToken
    attr_reader :calls

    def initialize(parsed_payload)
      @parsed_payload = parsed_payload
      @calls = []
    end

    def get(path, options = {})
      @calls << { path: path, options: options }
      Struct.new(:parsed).new(@parsed_payload)
    end
  end

  class FakeCredentialAccessToken
    attr_reader :token, :refresh_token, :expires_at, :params

    def initialize(token:, refresh_token:, expires_at:, expires:, params:)
      @token = token
      @refresh_token = refresh_token
      @expires_at = expires_at
      @expires = expires
      @params = params
    end

    def expires?
      @expires
    end

    def [](key)
      { 'scope' => @params['scope'] }[key]
    end
  end
end
