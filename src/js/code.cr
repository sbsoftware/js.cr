module JS
  abstract class Code
    OPERATOR_CALL_NAMES = %w[+ - * / ** ^ // & | && || > >= < <= == !=]

    JS_ALIASES = {} of String => String

    macro js_alias(name, aliased_name)
      {% JS_ALIASES[name.id.stringify] = aliased_name.id.stringify %}
    end

    macro def_to_js(&blk)
      def self.to_js(io : IO)
        JS::Code._eval_js_block(io, {{@type.resolve}}) {{blk}}
      end

      def self.to_js
        String.build do |str|
          to_js(str)
        end
      end
    end

    macro _eval_js_block(io, namespace, nested = false, &blk)
      {% if blk.body.is_a?(Expressions) %}
        {% for exp in blk.body.expressions %}
          JS::Code._eval_js({{io}}, {{namespace}}, {{nested}}) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
            {{exp}}
          end
        {% end %}
      {% else %}
        JS::Code._eval_js({{io}}, {{namespace}}, {{nested}}) {{blk}}
      {% end %}
    end

    macro _eval_js(io, namespace, nested = false, &blk)
      {% if blk.body.is_a?(Call) && blk.body.name.stringify == "_literal_js" %}
        {{io}} << {{blk.body.args.first}}
      {% elsif blk.body.is_a?(Call) && blk.body.name.stringify == "to_js_call" %}
        {{io}} << {{blk.body}}
        {% if !nested %}
          {{io}} << ";"
        {% end %}
      {% elsif blk.body.is_a?(Call) && blk.body.name.stringify == "to_js_ref" %}
        {{io}} << {{blk.body}}
      {% elsif blk.body.is_a?(Call) && blk.body.name.stringify == "new" %}
        {{io}} << "new "
        JS::Code._eval_js_block({{io}}, {{namespace}}, true) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
          {{blk.body.receiver}}
        end
        {{io}} << "("
        {% for arg, index in blk.body.args %}
          JS::Code._eval_js_block({{io}}, {{namespace}}, true) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
            {{arg}}
          end
          {% if index < blk.body.args.size - 1 %}
            {{io}} << ", "
          {% end %}
        {% end %}
        {{io}} << ")"
      {% elsif blk.body.is_a?(Call) && blk.body.name.stringify == "[]" %}
        {{io}} << {{blk.body.receiver.stringify}}
        {{io}} << "["
        JS::Code._eval_js_block({{io}}, true) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
          {{blk.body.args.first}}
        end
        {{io}} << "]"
        {% if !nested %}
          {{io}} << ";"
        {% end %}
      {% elsif blk.body.is_a?(Call) && blk.body.name.stringify == "[]=" %}
        {{io}} << {{blk.body.receiver.stringify}}
        {{io}} << "["
        JS::Code._eval_js_block({{io}}, {{namespace}}, true) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
          {{blk.body.args.first}}
        end
        {{io}} << "] = "
        JS::Code._eval_js_block({{io}}, {{namespace}}, true) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
          {{blk.body.args.last}}
        end
        {% if !nested %}
          {{io}} << ";"
        {% end %}
      {% elsif blk.body.is_a?(Call) && blk.body.name.stringify.ends_with?("=") && !OPERATOR_CALL_NAMES.includes?(blk.body.name.stringify) %}
        {{io}} << {{blk.body.receiver.stringify}}
        {{io}} << "."
        {{io}} << {{blk.body.name.stringify[0..-2]}}
        {{io}} << " = "
        JS::Code._eval_js_block({{io}}, {{namespace}}, true) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
          {{blk.body.args.first}}
        end
        {% if !nested %}
          {{io}} << ";"
        {% end %}
      {% elsif blk.body.is_a?(Call) %}
        {% if blk.body.receiver && blk.body.args.size == 1 && OPERATOR_CALL_NAMES.includes?(blk.body.name.stringify) %}
          JS::Code._eval_js_block({{io}}, {{namespace}}, true) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
            {{blk.body.receiver}}
          end
          {{io}} << " "
          {{io}} << {{blk.body.name.stringify}}
          {{io}} << " "
          JS::Code._eval_js_block({{io}}, {{namespace}}, true) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
            {{blk.body.args.first}}
          end
        {% else %}
          {% if blk.body.receiver %}
            # TODO: Replace this whole `if` by a recursive call to this macro?
            {% if blk.body.receiver.is_a?(Call) %}
              JS::Code._eval_js_block({{io}}, {{namespace}}, true) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
                {{blk.body.receiver}}
              end
            {% elsif blk.body.receiver.is_a?(Expressions) %}
              {% for exp in blk.body.receiver.expressions %}
                JS::Code._eval_js_block({{io}}, {{namespace}}, true) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
                  {{exp}}
                end
              {% end %}
            {% elsif (blk.body.receiver.is_a?(Path) || blk.body.receiver.is_a?(TypeNode)) && blk.body.receiver.resolve? %}
              if {{blk.body.receiver}}.responds_to?(:to_js_ref)
                {{io}} << {{blk.body.receiver}}.to_js_ref
              else
                {{io}} << {{blk.body.receiver.stringify}}
              end
            {% else %}
              {{io}} << {{blk.body.receiver.stringify}}
            {% end %}
            {% if blk.body.name.stringify != "_call" %}
              {{io}} << "."
            {% end %}
          {% end %}
          {% if blk.body.name.stringify != "_call" %}
            {{io}} << {{JS_ALIASES[blk.body.name.stringify] || blk.body.name.stringify}}
          {% end %}
          {% if blk.body.args.size > 0 || blk.body.block || blk.body.name.stringify == "_call" %}
            {{io}} << "("
          {% end %}
          {% for arg, index in blk.body.args %}
            JS::Code._eval_js_block({{io}}, {{namespace}}, true) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
              {{arg}}
            end
            {% if index < blk.body.args.size - 1 || blk.body.block %}
              {{io}} << ", "
            {% end %}
          {% end %}
          {% if blk.body.block %}
            {{io}} << "function("
            {{io}} << {{blk.body.block.args.splat.stringify}}
            {{io}} << ") {"
            JS::Code._eval_js_block({{io}}, {{namespace}}) {{blk.body.block}}
            {{io}} << "}"
          {% end %}
          {% if blk.body.args.size > 0 || blk.body.block || blk.body.name.stringify == "_call" %}
            {{io}} << ")"
          {% end %}
        {% end %}
        {% if !nested %}
          {{io}} << ";"
        {% end %}
      {% elsif (blk.body.is_a?(Path) || blk.body.is_a?(TypeNode)) %}
        {% if parse_type("#{namespace}::#{blk.body.id}").resolve? %}
          if {{namespace}}::{{blk.body}}.responds_to?(:to_js_ref)
            {{io}} << {{namespace}}::{{blk.body}}.to_js_ref
          else
            {{io}} << {{blk.body.stringify}}
          end
        {% elsif blk.body.resolve? %}
          if {{blk.body}}.responds_to?(:to_js_ref)
            {{io}} << {{blk.body}}.to_js_ref
          else
            {{io}} << {{blk.body.stringify}}
          end
        {% else %}
          {{io}} << {{blk.body.stringify}}
        {% end %}
      {% elsif blk.body.is_a?(HashLiteral) %}
        {{io}} << "{"
        {% for key, i in blk.body.keys %}
          {{io}} << {{key.id.stringify}}
          {{io}} << ": "
          JS::Code._eval_js_block({{io}}, {{namespace}}, true) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
            {{blk.body[key]}}
          end
          {% if i < blk.body.size - 1 %}
            {{io}} << ", "
          {% end %}
        {% end %}
        {{io}} << "}"
        {% if !nested %}
          {{io}} << ";"
        {% end %}
      {% elsif blk.body.is_a?(If) %}
        {{io}} << "if ("
        JS::Code._eval_js_block({{io}}, {{namespace}}, true) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
          {{blk.body.cond}}
        end
        {{io}} << ") {"
        JS::Code._eval_js_block({{io}}, {{namespace}}) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
          {{blk.body.then}}
        end
        {{io}} << "}"
        {% if blk.body.else %}
          {{io}} << " else {"
          JS::Code._eval_js_block({{io}}, {{namespace}}) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
            {{blk.body.else}}
          end
          {{io}} << "}"
        {% end %}
      {% elsif blk.body.is_a?(Assign) %}
        {{io}} << "var "
        {{io}} << {{blk.body.target.stringify}}
        {{io}} << " = "
        JS::Code._eval_js_block({{io}}, {{namespace}}, true) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
          {{blk.body.value}}
        end
        {% if !nested %}
          {{io}} << ";"
        {% end %}
      {% elsif blk.body.is_a?(Return) %}
        {{io}} << "return "
        JS::Code._eval_js_block({{io}}, {{namespace}}) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
          {{blk.body.exp}}
        end
      {% elsif blk.body.is_a?(MacroIf) %}
        \{% if {{blk.body.cond}} %}
          JS::Code._eval_js_block({{io}}, {{namespace}}) do
            {{blk.body.then}}
          end
        \{% else %}
          JS::Code._eval_js_block({{io}}, {{namespace}}) do
            {{blk.body.else}}
          end
        \{% end %}
      {% elsif blk.body.is_a?(MacroFor) %}
        \{% for {{blk.body.vars.splat}} in {{blk.body.exp}} %}
          JS::Code._eval_js_block({{io}}, {{namespace}}) do
            {{blk.body.body}}
          end
        \{% end %}
      {% elsif blk.body.is_a?(MacroExpression) || blk.body.is_a?(MacroLiteral) %}
        {{blk.body}}
      {% else %}
        {{io}} << {{blk.body.stringify}}
      {% end %}
    end
  end
end
