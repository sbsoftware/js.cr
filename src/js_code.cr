abstract class JsCode
  macro def_to_js(&blk)
    def self.to_js(io : IO)
      JsCode._eval_js_block(io) {{blk}}
    end

    def self.to_js
      String.build do |str|
        to_js(str)
      end
    end
  end

  macro _eval_js_block(io, &blk)
    {% if blk.body.is_a?(Expressions) %}
      {% for exp in blk.body.expressions %}
        JsCode._eval_js({{io}}) do
          {{exp}}
        end
      {% end %}
    {% else %}
      JsCode._eval_js({{io}}) {{blk}}
    {% end %}
  end

  macro _eval_js(io, &blk)
    {% if blk.body.is_a?(Call) && blk.body.name.stringify == "_literal_js" %}
      {{io}} << {{blk.body.args.first}}
    {% elsif blk.body.is_a?(Call) && blk.body.name.stringify == "to_js_call" %}
      {{io}} << {{blk.body}}
      {{io}} << ";"
    {% elsif blk.body.is_a?(Call) && blk.body.name.stringify.ends_with?("=") %}
      {{io}} << {{blk.body.receiver.stringify}}
      {{io}} << "."
      {{io}} << {{blk.body.name.stringify[0..-2]}}
      {{io}} << " = "
      JsCode._eval_js({{io}}) do
        {{blk.body.args.first}}
      end
    {% elsif blk.body.is_a?(Call) %}
      {{io}} << {{blk.body.stringify}}
      {% if blk.body.args.empty? %}
        {{io}} << "()"
      {% end %}
      {{io}} << ";"
    {% end %}
  end
end
