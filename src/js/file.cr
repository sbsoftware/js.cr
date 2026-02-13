require "./code"
require "./function"
require "./class"

module JS
  abstract class File
    @@js_classes = [] of JS::Class.class
    @@js_functions = [] of JS::Function.class

    macro js_alias(new_name, old_name)
      JS::Code.js_alias({{new_name}}, {{old_name}})
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
        def_to_js({{name.id.stringify}}) {{blk}}
      end

      @@js_functions << {{name.id.stringify.camelcase.id}}

      def self.{{name.id}}
        {{name.id.stringify.camelcase.id}}
      end
    end

    macro async_js_function(name, &blk)
      class {{name.id.stringify.camelcase.id}} < JS::Function
        def_to_js({{name.id.stringify}}, async: true) {{blk}}
      end

      @@js_functions << {{name.id.stringify.camelcase.id}}

      def self.{{name.id}}
        {{name.id.stringify.camelcase.id}}
      end
    end

    macro def_to_js(strict = false, &blk)
      def_to_js({{@type}}, strict: {{strict}}) {{blk}}
    end

    macro def_to_js(namespace, strict = false, &blk)
      def self.to_js(io : IO)
        @@js_classes.each do |js_class|
          js_class.to_js(io)
        end
        @@js_functions.each do |func|
          func.to_js(io)
        end
        JS::Code._eval_js_block(
          io,
          {{namespace}},
          {inline: false, nested_scope: true, strict: {{strict}}, locals: [] of String}
        ) {{blk}}
      end

      def self.to_js
        String.build do |str|
          to_js(str)
        end
      end
    end
  end
end
