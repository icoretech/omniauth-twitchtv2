# OmniAuth Twitchtv2 Strategy

[![Test](https://github.com/icoretech/omniauth-twitchtv2/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/icoretech/omniauth-twitchtv2/actions/workflows/test.yml?query=branch%3Amain)
[![Gem Version](https://badge.fury.io/rb/omniauth-twitchtv2.svg)](https://badge.fury.io/rb/omniauth-twitchtv2)

`omniauth-twitchtv2` provides a Twitch OAuth2 strategy for OmniAuth.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'omniauth-twitchtv2'
```

Then run:

```bash
bundle install
```

## Usage

Configure OmniAuth in your Rack/Rails app:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitchtv,
           ENV.fetch('TWITCH_CLIENT_ID'),
           ENV.fetch('TWITCH_CLIENT_SECRET'),
           scope: 'user:read:email'
end
```

## Provider App Setup

- Twitch developer console: <https://dev.twitch.tv/console/apps>
- OAuth docs: <https://dev.twitch.tv/docs/authentication/getting-tokens-oauth/>
- Register callback URL (example): `https://your-app.example.com/auth/twitchtv/callback`

## Options

- `scope` (for example `user:read:email`)
- `force_verify`

## Auth Hash

Example payload from `request.env['omniauth.auth']` (realistic shape, anonymized):

```json
{
  "uid": "12345678",
  "info": {
    "name": "sample_user",
    "nickname": "sample_user",
    "email": "sample@example.test",
    "image": "https://static-cdn.jtvnw.net/jtv_user_pictures/example-profile_image-300x300.png",
    "description": "Streaming something cool",
    "urls": {
      "twitchtv": "https://www.twitch.tv/sample_user"
    }
  },
  "credentials": {
    "token": "sample-access-token",
    "refresh_token": "sample-refresh-token",
    "expires_at": 1710000000,
    "expires": true,
    "scope": "user:read:email"
  },
  "extra": {
    "raw_info": {
      "id": "12345678",
      "login": "sample_user",
      "display_name": "sample_user",
      "type": "",
      "broadcaster_type": "",
      "description": "Streaming something cool",
      "profile_image_url": "https://static-cdn.jtvnw.net/jtv_user_pictures/example-profile_image-300x300.png",
      "offline_image_url": "",
      "view_count": 42,
      "email": "sample@example.test",
      "created_at": "2020-01-01T00:00:00Z"
    }
  }
}
```

`info.email` is returned only when your app requests a scope that exposes email (for example `user:read:email`).

## Development

```bash
bundle install
bundle exec rake
```

Run Rails integration tests with an explicit Rails version:

```bash
RAILS_VERSION='~> 8.1.0' bundle install
RAILS_VERSION='~> 8.1.0' bundle exec rake test_rails_integration
```

## Test Structure

- `test/omniauth_twitchtv_test.rb`: strategy/unit behavior
- `test/rails_integration_test.rb`: full Rack/Rails request+callback flow
- `test/test_helper.rb`: shared test bootstrap

## Compatibility

- Ruby: `>= 3.2` (tested on `3.2`, `3.3`, `3.4`, `4.0`)
- `omniauth-oauth2`: `>= 1.8`, `< 2.0`
- Rails integration lanes: `~> 7.1.0`, `~> 7.2.0`, `~> 8.0.0`, `~> 8.1.0`

## Release

Tag releases as `vX.Y.Z`; GitHub Actions publishes the gem to RubyGems.

## License

MIT
