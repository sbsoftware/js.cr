module JS
  abstract class Code
    OPERATOR_CALL_NAMES = %w[+ - * / ** ^ // & | && ||]

    JS_ALIASES = {} of String => String

    macro js_alias(name, aliased_name)
      {% JS_ALIASES[name.id.stringify] = aliased_name.id.stringify %}
    end

    macro def_to_js(&blk)
      def self.to_js(io : IO)
        JS::Code._eval_js_block(io) {{blk}}
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
          JS::Code._eval_js({{io}}) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
            {{exp}}
          end
        {% end %}
      {% else %}
        JS::Code._eval_js({{io}}) {{blk}}
      {% end %}
    end

    macro _eval_js(io, nested = false, &blk)
      {% if blk.body.is_a?(Call) && blk.body.name.stringify == "_literal_js" %}
        {{io}} << {{blk.body.args.first}}
      {% elsif blk.body.is_a?(Call) && blk.body.name.stringify == "to_js_call" %}
        {{io}} << {{blk.body}}
        {% if !nested %}
          {{io}} << ";"
        {% end %}
      {% elsif blk.body.is_a?(Call) && blk.body.name.stringify == "to_js_ref" %}
        {{io}} << {{blk.body}}
      {% elsif blk.body.is_a?(Call) && blk.body.name.stringify == "_call" && blk.body.receiver %}
        JS::Code._eval_js_call({{io}}, true) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
          {{blk.body.receiver}}
        end
        {% if !nested %}
          {{io}} << ";"
        {% end %}
      {% elsif blk.body.is_a?(Call) && blk.body.name.stringify == "new" %}
        {{io}} << "new "
        {{io}} << {{blk.body.receiver.stringify}}
        {{io}} << "("
        {% for arg, index in blk.body.args %}
          JS::Code._eval_js_arg({{io}}) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
            {{arg}}
          end
          {% if index < blk.body.args.size - 1 %}
            {{io}} << ", "
          {% end %}
        {% end %}
        {{io}} << ")"
      {% elsif blk.body.is_a?(Call) && blk.body.name.stringify.ends_with?("=") %}
        {{io}} << {{blk.body.receiver.stringify}}
        {{io}} << "."
        {{io}} << {{blk.body.name.stringify[0..-2]}}
        {{io}} << " = "
        JS::Code._eval_js({{io}}, true) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
          {{blk.body.args.first}}
        end
        {% if !nested %}
          {{io}} << ";"
        {% end %}
      {% elsif blk.body.is_a?(Call) %}
        JS::Code._eval_js_call({{io}}) {{blk}}
        {% if !nested %}
          {{io}} << ";"
        {% end %}
      {% elsif blk.body.is_a?(Assign) %}
        {{io}} << "var "
        {{io}} << {{blk.body.target.stringify}}
        {{io}} << " = "
        JS::Code._eval_js({{io}}, true) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
          {{blk.body.value}}
        end
        {% if !nested %}
          {{io}} << ";"
        {% end %}
      {% elsif blk.body.is_a?(MacroIf) %}
        \{% if {{blk.body.cond}} %}
          JS::Code._eval_js_block({{io}}) do
            {{blk.body.then}}
          end
        \{% else %}
          JS::Code._eval_js_block({{io}}) do
            {{blk.body.else}}
          end
        \{% end %}
      {% elsif blk.body.is_a?(MacroFor) %}
        \{% for {{blk.body.vars.splat}} in {{blk.body.exp}} %}
          JS::Code._eval_js_block({{io}}) do
            {{blk.body.body}}
          end
        \{% end %}
      {% elsif blk.body.is_a?(MacroExpression) || blk.body.is_a?(MacroLiteral) %}
        {{blk.body}}
      {% else %}
        {{io}} << {{blk.body.stringify}}
      {% end %}
    end

    macro _eval_js_call(io, force_empty_parens = false, &blk)
      {% if blk.body.receiver && blk.body.args.size == 1 && OPERATOR_CALL_NAMES.includes?(blk.body.name.stringify) %}
        JS::Code._eval_js({{io}}, true) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
          {{blk.body.receiver}}
        end
        {{io}} << " "
        {{io}} << {{blk.body.name.stringify}}
        {{io}} << " "
        JS::Code._eval_js({{io}}, true) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
          {{blk.body.args.first}}
        end
      {% else %}
        {% if blk.body.receiver %}
          {% if blk.body.receiver.is_a?(Call) %}
            JS::Code._eval_js_call({{io}}) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
              {{blk.body.receiver}}
            end
          {% elsif blk.body.receiver.is_a?(Expressions) %}
            {% for exp in blk.body.receiver.expressions %}
              JS::Code._eval_js_call({{io}}) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
                {{exp}}
              end
            {% end %}
          {% else %}
            {{io}} << {{blk.body.receiver.stringify}}
          {% end %}
          {{io}} << "."
        {% end %}
        {{io}} << {{JS_ALIASES[blk.body.name.stringify] || blk.body.name.stringify}}
        {% if blk.body.args.size > 0 || blk.body.block || force_empty_parens %}
          {{io}} << "("
        {% end %}
        {% for arg, index in blk.body.args %}
          JS::Code._eval_js_arg({{io}}) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
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
          JS::Code._eval_js_block({{io}}) {{blk.body.block}}
          {{io}} << "}"
        {% end %}
        {% if blk.body.args.size > 0 || blk.body.block || force_empty_parens %}
          {{io}} << ")"
        {% end %}
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
end
