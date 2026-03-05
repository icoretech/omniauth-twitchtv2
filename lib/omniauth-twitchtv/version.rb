# frozen_string_literal: true

require 'omniauth-twitchtv2/version'

module Omniauth
  module Twitchtv
    VERSION = OmniAuth::Twitchtv2::VERSION unless const_defined?(:VERSION)
  end
end
