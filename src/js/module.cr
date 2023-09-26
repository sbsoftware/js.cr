require "./code"
require "./function"
require "./class"

module JS
  abstract class Module
    @@js_imports = [] of String
    @@js_classes = [] of JS::Class.class
    @@js_functions = [] of JS::Function.class

    macro js_import(*names, from)
      @@js_imports << ("import { {{names.map(&.id).splat}} } from \"" + {{from}} + "\";")
    end

    macro js_class(name, &blk)
      {% if blk %}
        class {{name.id}} < JS::Class
          {{blk.body}}
        end
      {% end %}

      @@js_classes << {{name.id}}
    end

    macro js_function(name, &blk)
      class {{name.id.stringify.camelcase.id}} < JS::Function
        def_to_js {{blk}}
      end

      @@js_functions << {{name.id.stringify.camelcase.id}}

      def self.{{name.id}}
        {{name.id.stringify.camelcase.id}}
      end
    end

    macro def_to_js(&blk)
      def self.to_js(io : IO)
        @@js_imports.join(io, "\n")
        @@js_classes.each do |js_class|
          js_class.to_js(io)
        end
        @@js_functions.each do |func|
          func.to_js(io)
        end
        JS::Code._eval_js_block(io) {{blk}}
      end

      def self.to_js
        String.build do |str|
          to_js(str)
        end
      end
    end
  end
end
