require "./code"
require "./function"
require "./class"

module JS
  abstract class File
    @@js_classes = [] of JS::Class.class
    @@js_functions = [] of JS::Function.class
    @@js_fragments = [] of Proc(IO, Nil)

    # Base file emission includes class/function declarations plus all
    # registered JS fragments in declaration order.
    def self.to_js(io : IO)
      @@js_classes.each do |js_class|
        js_class.to_js(io)
      end
      @@js_functions.each do |func|
        func.to_js(io)
      end
      @@js_fragments.each do |fragment|
        fragment.call(io)
      end
    end

    def self.to_js
      String.build do |str|
        to_js(str)
      end
    end

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

    macro js_fragment(strict = false, &blk)
      _register_js_fragment({{@type}}, strict: {{strict}}) {{blk}}
    end

    macro def_to_js(strict = false, &blk)
      _register_js_fragment({{@type}}, strict: {{strict}}) {{blk}}
    end

    macro def_to_js(namespace, strict = false, &blk)
      _register_js_fragment({{namespace}}, strict: {{strict}}) {{blk}}
    end

    macro _register_js_fragment(namespace, strict = false, &blk)
      @@js_fragments << ->(io : IO) do
        JS::Code._eval_js_block(
          io,
          {{namespace}},
          {inline: false, nested_scope: true, strict: {{strict}}, declared_vars: [] of String}
        ) {{blk}}
      end
    end
  end
end
