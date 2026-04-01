# frozen_string_literal: true

require "omniauth/twitchtv2/version"

# Backward compatibility for historical constant usage.
module Omniauth
  module Twitchtv2
    VERSION = OmniAuth::Twitchtv2::VERSION unless const_defined?(:VERSION)
  end

  module Twitchtv
    VERSION = OmniAuth::Twitchtv2::VERSION unless const_defined?(:VERSION)
  end
end
