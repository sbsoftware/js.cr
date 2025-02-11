module JS
  abstract class Code
    OPERATOR_CALL_NAMES = %w[+ - * / ** ^ // & | && || > >= < <= == !=]

    JS_ALIASES = {} of String => String

    macro js_alias(name, aliased_name)
      {% JS_ALIASES[name.id.stringify] = aliased_name.id.stringify %}
    end

    macro def_to_js(&blk)
      def self.to_js(io : IO)
        JS::Code._eval_js_block(io, {{@type.resolve}}, {inline: false, nested_scope: true}) {{blk}}
      end

      def self.to_js
        String.build do |str|
          to_js(str)
        end
      end
    end

    macro _eval_js_block(io, namespace, opts, &blk)
      {% if blk.body.is_a?(Expressions) %}
        {% if opts[:nested_scope] %}
          {% for var in blk.body.expressions.select { |e| e.is_a?(Assign) }.map { |a| a.target.stringify }.uniq %}
            {{io}} << "var "
            {{io}} << {{var}}
            {{io}} << ";"
          {% end %}
        {% end %}

        {% for exp in blk.body.expressions %}
          {% if exp.is_a?(Call) && exp.name.stringify == "_literal_js" %}
            {{io}} << {{exp.args.first}}
          {% elsif exp.is_a?(Call) && exp.name.stringify == "to_js_call" %}
            {{io}} << {{exp}}
            {% if !opts[:inline] %}
              {{io}} << ";"
            {% end %}
          {% elsif exp.is_a?(Call) && exp.name.stringify == "to_js_ref" %}
            {{io}} << {{exp}}
          {% elsif exp.is_a?(Call) && exp.name.stringify == "new" %}
            {{io}} << "new "
            JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false}) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
              {{exp.receiver}}
            end
            {{io}} << "("
            {% for arg, index in exp.args %}
              JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false}) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
                {{arg}}
              end
              {% if index < exp.args.size - 1 %}
                {{io}} << ", "
              {% end %}
            {% end %}
            {{io}} << ")"
          {% elsif exp.is_a?(Call) && exp.name.stringify == "[]" %}
            {{io}} << {{exp.receiver.stringify}}
            {{io}} << "["
            JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false}) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
              {{exp.args.first}}
            end
            {{io}} << "]"
            {% if !opts[:inline] %}
              {{io}} << ";"
            {% end %}
          {% elsif exp.is_a?(Call) && exp.name.stringify == "[]=" %}
            {{io}} << {{exp.receiver.stringify}}
            {{io}} << "["
            JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false}) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
              {{exp.args.first}}
            end
            {{io}} << "] = "
            JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false}) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
              {{exp.args.last}}
            end
            {% if !opts[:inline] %}
              {{io}} << ";"
            {% end %}
          {% elsif exp.is_a?(Call) && exp.name.stringify.ends_with?("=") && !OPERATOR_CALL_NAMES.includes?(exp.name.stringify) %}
            {{io}} << {{exp.receiver.stringify}}
            {{io}} << "."
            {{io}} << {{exp.name.stringify[0..-2]}}
            {{io}} << " = "
            JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false}) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
              {{exp.args.first}}
            end
            {% if !opts[:inline] %}
              {{io}} << ";"
            {% end %}
          {% elsif exp.is_a?(Call) %}
            {% if exp.receiver && exp.args.size == 1 && OPERATOR_CALL_NAMES.includes?(exp.name.stringify) %}
              JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false}) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
                {{exp.receiver}}
              end
              {{io}} << " "
              {{io}} << {{exp.name.stringify}}
              {{io}} << " "
              JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false}) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
                {{exp.args.first}}
              end
            {% else %}
              {% if exp.receiver %}
                # TODO: Replace this whole `if` by a recursive call to this macro?
                {% if exp.receiver.is_a?(Call) %}
                  JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false}) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
                    {{exp.receiver}}
                  end
                {% elsif exp.receiver.is_a?(Expressions) %}
                  {% for rec_exp in exp.receiver.expressions %}
                    JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false}) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
                      {{rec_exp}}
                    end
                  {% end %}
                {% elsif (exp.receiver.is_a?(Path) || exp.receiver.is_a?(TypeNode)) && exp.receiver.resolve? %}
                  {% if exp.receiver.resolve.has_method?(:to_js_ref) %}
                    {{io}} << {{exp.receiver}}.to_js_ref
                  {% else %}
                    {{io}} << {{exp.receiver.stringify}}
                  {% end %}
                {% else %}
                  {{io}} << {{exp.receiver.stringify}}
                {% end %}
                {% if exp.name.stringify != "_call" %}
                  {{io}} << "."
                {% end %}
              {% end %}
              {% if exp.name.stringify != "_call" %}
                {{io}} << {{JS_ALIASES[exp.name.stringify] || exp.name.stringify}}
              {% end %}
              {% if exp.args.size > 0 || exp.block || exp.name.stringify == "_call" %}
                {{io}} << "("
              {% end %}
              {% for arg, index in exp.args %}
                JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false}) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
                  {{arg}}
                end
                {% if index < exp.args.size - 1 || exp.block %}
                  {{io}} << ", "
                {% end %}
              {% end %}
              {% if exp.block %}
                {{io}} << "function("
                {{io}} << {{exp.block.args.splat.stringify}}
                {{io}} << ") {"
                JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: false, nested_scope: true}) {{exp.block}}
                {{io}} << "}"
              {% end %}
              {% if exp.args.size > 0 || exp.block || exp.name.stringify == "_call" %}
                {{io}} << ")"
              {% end %}
            {% end %}
            {% if !opts[:inline] %}
              {{io}} << ";"
            {% end %}
          {% elsif (exp.is_a?(Path) || exp.is_a?(TypeNode)) %}
            {% if parse_type("#{namespace}::#{exp.id}").resolve? %}
              if {{namespace}}::{{exp}}.responds_to?(:to_js_ref)
                {{io}} << {{namespace}}::{{exp}}.to_js_ref
              else
                {{io}} << {{exp.stringify}}
              end
            {% elsif exp.resolve? %}
              if {{exp}}.responds_to?(:to_js_ref)
                {{io}} << {{exp}}.to_js_ref
              else
                {{io}} << {{exp.stringify}}
              end
            {% else %}
              {{io}} << {{exp.stringify}}
            {% end %}
          {% elsif exp.is_a?(ArrayLiteral) %}
            {{io}} << "["
            {{io}} << {{exp.splat.stringify}}
            {{io}} << "]"
            {% if !opts[:inline] %}
              {{io}} << ";"
            {% end %}
          {% elsif exp.is_a?(HashLiteral) || exp.is_a?(NamedTupleLiteral) %}
            {{io}} << "{"
            {% for key, i in exp.keys %}
              {{io}} << {{key.id.stringify}}
              {{io}} << ": "
              JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false}) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
                {{exp[key]}}
              end
              {% if i < exp.size - 1 %}
                {{io}} << ", "
              {% end %}
            {% end %}
            {{io}} << "}"
            {% if !opts[:inline] %}
              {{io}} << ";"
            {% end %}
          {% elsif exp.is_a?(If) %}
            {{io}} << "if ("
            JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false}) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
              {{exp.cond}}
            end
            {{io}} << ") {"
            JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: false, nested_scope: false}) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
              {{exp.then}}
            end
            {{io}} << "}"
            {% if !exp.else.is_a?(Nop) %}
              {{io}} << " else {"
              JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: false, nested_scope: false}) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
                {{exp.else}}
              end
              {{io}} << "}"
            {% end %}
          {% elsif exp.is_a?(Assign) %}
            {{exp.target}} = nil
            {{io}} << {{exp.target.stringify}}
            {{io}} << " = "
            JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false}) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
              {{exp.value}}
            end
            {% if !opts[:inline] %}
              {{io}} << ";"
            {% end %}
          {% elsif exp.is_a?(Return) %}
            {{io}} << "return "
            JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: false, nested_scope: false}) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
              {{exp.exp}}
            end
          {% elsif exp.is_a?(ProcLiteral) %}
            {{io}} << "({{exp.args.map(&.name).splat}}) => {"
            JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: false, nested_scope: false}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
              {{exp.body}}
            end
            {{io}} << "}"
          {% elsif exp.is_a?(MacroIf) %}
            \{% if {{exp.cond}} %}
              JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: false, nested_scope: false}) do
                {{exp.then}}
              end
            \{% else %}
              JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: false, nested_scope: false}) do
                {{exp.else}}
              end
            \{% end %}
          {% elsif exp.is_a?(MacroFor) %}
            \{% for {{exp.vars.splat}} in {{exp.exp}} %}
              JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: false, nested_scope: false}) do
                {{exp.body}}
              end
            \{% end %}
          {% elsif exp.is_a?(MacroExpression) || exp.is_a?(MacroLiteral) %}
            {{exp}}
          {% elsif exp.is_a?(NilLiteral) %}
            # do nothing
          {% else %}
            {{io}} << {{exp.stringify}}
          {% end %}
        {% end %}
      {% else %}
        JS::Code._eval_js_block({{io}}, {{namespace}}, {{opts}}) do {{ blk.args.empty? ? "".id : "|#{blk.args.splat}|".id }}
          nil
          {{blk.body}}
        end
      {% end %}
    end
  end
end
