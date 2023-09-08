require "./js_code"
require "./js_function"

abstract class JsMethod < JsFunction
  macro def_to_js(name, &blk)
    def self.function_name
      {% if name.is_a?(StringLiteral) || name.is_a?(Symbol) %}
        {{name.id.stringify}}
      {% else %}
        {{name}}
      {% end %}
    end

    JsCode.def_to_js do {% !blk.args.empty? ? "|#{blk.args.splat}|".id : "".id %}
      _literal_js("#{function_name}({{blk.args.splat}}) {")
      {{blk.body}}
      _literal_js("}")
    end
  end
end
