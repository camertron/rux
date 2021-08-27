# The files in this directory are meant to monkeypatch unparser v0.6.0
# to include a callback that will be invoked every time a token is
# written to the output buffer. The callback yields the buffer, old
# location of the token, and the new location of the token. Eventually
# I'd like to get this upstreamed, but the author of unparser is really
# busy and hasn't been able to dedicate time to it. For now, we have to
# do this very ugly business 🤢

require 'unparser/adamantium'
require 'unparser/equalizer'
require 'unparser/concord'
require 'ext/unparser/concord'
require 'unparser'
require 'ext/unparser/emitter'
require 'ext/unparser/emitter/class'
require 'ext/unparser/emitter/argument'
require 'ext/unparser/emitter/def'
require 'ext/unparser/emitter/primitive'
require 'ext/unparser/emitter/module'
require 'ext/unparser/emitter/root'
require 'ext/unparser/emitter/variable'
require 'ext/unparser/buffer'
require 'ext/unparser/generation'
require 'ext/unparser/writer'
require 'ext/unparser/writer/send'

module Rux
  module UnparserPatch
    def unparse(node, comment_array = [], &callback)
      return '' if node.nil?

      Unparser::Buffer.new.tap do |buffer|
        Unparser::Emitter::Root.new(
          buffer,
          node,
          Unparser::Comments.new(comment_array),
          callback
        ).write_to_buffer
      end.content
    end
  end
end


module Unparser
  class << self
    prepend Rux::UnparserPatch
  end
end
