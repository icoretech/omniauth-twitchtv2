# frozen_string_literal: true

require 'omniauth-twitchtv2'

module Omniauth
  module Twitchtv
    class TwitchtvError < OmniAuth::Error; end unless const_defined?(:TwitchtvError)
  end
end
