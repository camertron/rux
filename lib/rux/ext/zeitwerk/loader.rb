require 'zeitwerk'

module Zeitwerk
  class Loader
    private

    alias_method :orig_ruby?, :ruby?
    alias_method :orig_autoload_file, :autoload_file

    def ruby?(path)
      orig_ruby?(path) || path.end_with?('.rux')
    end

    def autoload_file(parent, cname, file)
      if file.end_with?('.rux')
        # Zeitwerk very naïvely tries to remove only the last 3 characters in
        # an attempt to strip off the .rb file extension, which it assumes all
        # autoloadable files will contain. This is necessary to remove the
        # trailing period.
        cname = cname.to_s.chomp('.').to_sym
      end

      orig_autoload_file(parent, cname, file)
    end
  end
end
