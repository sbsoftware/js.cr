require "./file"

module JS
  abstract class Module < JS::File
    @@js_imports = [] of String

    macro js_import(*names, from)
      @@js_imports << ("import { {{names.map(&.id).splat}} } from \"" + {{from}} + "\";")
    end

    macro def_to_js(strict = false, &blk)
      JS::File.def_to_js({{@type}}, strict: {{strict}}) {{blk}}

      def self.to_js(io : IO)
        @@js_imports.join(io, "\n")
        previous_def
      end
    end
  end
end
