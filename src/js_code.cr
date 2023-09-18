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
        JsCode._eval_js({{io}}) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
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
    {% elsif blk.body.is_a?(Call) && blk.body.name.stringify == "to_js_ref" %}
      {{io}} << {{blk.body}}
    {% elsif blk.body.is_a?(Call) && blk.body.name.stringify.ends_with?("=") %}
      {{io}} << {{blk.body.receiver.stringify}}
      {{io}} << "."
      {{io}} << {{blk.body.name.stringify[0..-2]}}
      {{io}} << " = "
      JsCode._eval_js({{io}}) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
        {{blk.body.args.first}}
      end
    {% elsif blk.body.is_a?(Call) %}
      {{io}} << {{blk.body.receiver.stringify}}
      {{io}} << "."
      {{io}} << {{blk.body.name.stringify}}
      {{io}} << "("
      {% for arg, index in blk.body.args %}
        JsCode._eval_js_arg({{io}}) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
          {{arg}}
        end
        {% if index < blk.body.args.size - 1 %}
          {{io}} << ", "
        {% end %}
      {% end %}
      {% if blk.body.block %}
        {{io}} << "function("
        {{io}} << {{blk.body.block.args.splat.stringify}}
        {{io}} << ") {"
        JsCode._eval_js_block({{io}}) {{blk.body.block}}
        {{io}} << "}"
      {% end %}
      {{io}} << ")"
      {{io}} << ";"
    {% elsif blk.body.is_a?(Assign) %}
      {{io}} << "var "
      {{io}} << {{blk.body.target.stringify}}
      {{io}} << " = "
      {{io}} << {{blk.body.value.stringify}}
      {{io}} << ";"
    {% else %}
      {{io}} << {{blk.body.stringify}}
    {% end %}
  end

  macro _eval_js_arg(io, &blk)
    {% if blk.body.is_a?(Call) && (blk.body.name.stringify == "to_js_ref" || blk.body.name.stringify == "to_js_call") %}
      {{io}} << {{blk.body}}
    {% else %}
      {{io}} << {{blk.body.stringify}}
    {% end %}
  end
end
