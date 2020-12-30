require 'zeitwerk'

module Kernel
  alias_method :rux_orig_require, :require
  alias_method :rux_orig_load, :load

  def load(file, *args)
    if File.extname(file) == '.rux'
      ruxc_file = "#{file.chomp('.rux')}.ruxc"
      tmpl = Rux::Template.new(file)
      File.write(ruxc_file, tmpl.to_ruby)

      # I don't understand why, but it's necessary to delete the constant
      # in order to load the .ruxc file. Otherwise you get an error about
      # an uninitialized constant, and it's like... yeah, I _know_ it's
      # uninitialized, that's why I'm loading this file. Whatevs.
      loader = Zeitwerk::Registry.loader_for(file)
      parent, cname = loader.autoloads[file]
      parent.send(:remove_const, cname)

      return rux_orig_load(ruxc_file, *args)
    end

    rux_orig_load(file, *args)
  end

  def require(file)
    # puts "REQUIRE #{file}"
    loader = Zeitwerk::Registry.loader_for(file)

    begin
      # If zeitwerk can't find the original file with an .rb extension, it'll
      # assume the file is actually a directory and skip loading it altogether.
      # To avoid this, call the original require function and bypass zeitwerk's
      # monkeypatched require.
      if file.end_with?('.rb') && loader
        # This is zeitwerk's monkeypatched require
        rux_orig_require(file)
      else
        # This is ruby's standard require
        zeitwerk_original_require(file)
      end
    rescue LoadError => e
      path = nil
      rux_file = file.end_with?('.rux') ? file : "#{file}.rux"

      if File.absolute_path?(rux_file) && File.exist?(rux_file)
        path = rux_file
      elsif rux_file.start_with?(".#{File::SEPARATOR}")
        abs_path = File.expand_path(rux_file)
        path = abs_path if File.exist?(abs_path)
      else
        $LOAD_PATH.each do |lp|
          check_path = File.expand_path(File.join(lp, rux_file))

          if File.exist?(check_path)
            path = check_path
            break
          end
        end
      end

      raise unless path
      return false if $LOADED_FEATURES.include?(path)

      load path
      $LOADED_FEATURES << path

      loader.on_file_autoloaded(path)

      return true
    end
  end
end
