abstract class JsCode
  macro def_to_js(&blk)
    def self.to_js(io : IO)
      {% if blk.body.is_a?(Expressions) %}
        {% for exp in blk.body.expressions %}
          JsCode._eval_js(io) do
            {{exp}}
          end
        {% end %}
      {% else %}
        JsCode._eval_js(io) {{blk}}
      {% end %}
    end

    def self.to_js
      String.build do |str|
        to_js(str)
      end
    end
  end

  macro _eval_js(io, &blk)
    {% if blk.body.is_a?(Call) && blk.body.name.stringify == "_literal_js" %}
      {{io}} << {{blk.body.args.first}}
    {% elsif blk.body.is_a?(Call) %}
      {{io}} << {{blk.body.stringify}}
      {{io}} << ";"
    {% end %}
  end
end
