module JS
  abstract class Function
    # Dummy to make crystal interpreter work with README examples
    def self.to_js(io : IO)
      raise "Not implemented"
    end

    def self.to_js_call(*args)
      String.build do |str|
        str << function_name
        str << "("
        args.join(str, ", ") do |arg|
          if arg.is_a?(String)
            str << "\"#{arg}\""
          else
            str << arg
          end
        end
        str << ")"
      end
    end

    macro def_to_js(name, &blk)
      def self.function_name
        {% if name.is_a?(StringLiteral) || name.is_a?(Symbol) %}
          {{name.id.stringify}}
        {% else %}
          {{name}}
        {% end %}
      end

      JS::Code.def_to_js do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
        _literal_js("function #{function_name}({{blk.args.splat}}) {")
        {{blk.body}}
        _literal_js("}")
      end
    end

    macro def_to_js(&blk)
      def_to_js(self.name.split("::")[-1].underscore) {{blk}}
    end
  end
end
