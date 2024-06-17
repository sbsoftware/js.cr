require "./code"
require "./function"

module JS
  abstract class Method < JS::Function
    macro def_to_js(name, &blk)
      def self.function_name
        {% if name.is_a?(StringLiteral) || name.is_a?(Symbol) %}
          {{name.id.stringify}}
        {% else %}
          {{name}}
        {% end %}
      end

      def self.to_js(io : IO)
        io << "#{function_name}({{blk.args.splat}}) {"
        JS::Code._eval_js_block(io, {{@type.resolve}}, {inline: false, nested_scope: true}) {{blk}}
        io << "}"
      end

      def self.to_js
        String.build do |str|
          to_js(str)
        end
      end
    end
  end
end
