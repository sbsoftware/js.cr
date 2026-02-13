module JS
  abstract class Code
    OPERATOR_CALL_NAMES           = %w[+ - * / ** ^ // & | && || > >= < <= == !=]
    STRICT_MODE_HELPER_CALL_NAMES = %w[await async to_js_call to_js_ref]

    JS_ALIASES = {} of String => String

    macro js_alias(name, aliased_name)
      {% JS_ALIASES[name.id.stringify] = aliased_name.id.stringify %}
    end

    macro def_to_js(strict = false, &blk)
      def self.to_js(io : IO)
        JS::Code._eval_js_block(
          io,
          {{@type.resolve}},
          {inline: false, nested_scope: true, strict: {{strict}}, locals: [] of String}
        ) {{blk}}
      end

      def self.to_js
        String.build do |str|
          to_js(str)
        end
      end
    end

    macro _strict_validate_node(namespace, node, locals)
      {% if node.is_a?(Nop) %}
      {% elsif node.is_a?(Expressions) %}
        {% for node_exp in node.expressions %}
          JS::Code._strict_validate_expression({{namespace}}, {{node_exp}}, {{locals.empty? ? "[] of String".id : locals}})
        {% end %}
      {% else %}
        JS::Code._strict_validate_expression({{namespace}}, {{node}}, {{locals.empty? ? "[] of String".id : locals}})
      {% end %}
    end

    macro _strict_validate_expression(namespace, exp, locals)
      {% if exp.is_a?(Call) %}
        {% call_name = exp.name.stringify.gsub(/\A"|"\z/, "") %}

        {% if !exp.receiver && call_name == "_literal_js" %}
          {% exp.raise "Strict mode forbids `_literal_js(...)`. Use typed browser context calls (for example `console.log(...)`) or `js_alias` declarations instead." %}
        {% end %}

        {% if exp.receiver %}
          JS::Code._strict_validate_node({{namespace}}, {{exp.receiver}}, {{locals.empty? ? "[] of String".id : locals}})
          {% if exp.receiver.is_a?(Call) && !exp.receiver.receiver %}
            {% receiver_name = exp.receiver.name.id.stringify.gsub(/\A"|"\z/, "") %}
            {% if receiver_name == "console" %}
              {% console_type = parse_type("JS::Browser::Console").resolve? %}
              {% if console_type.is_a?(TypeNode) && !console_type.has_method?(exp.name) %}
                {% exp.raise "Strict mode: `console` has no typed `#{call_name}` method. Supported methods are `log`, `info`, `warn`, and `error`." %}
              {% end %}
            {% end %}
          {% end %}
        {% elsif !STRICT_MODE_HELPER_CALL_NAMES.includes?(call_name) && call_name != "new" && call_name != "_call" && call_name != "[]" && call_name != "[]=" && !OPERATOR_CALL_NAMES.includes?(call_name) %}
          {% namespace_declares_call = false %}
          {% if (namespace_type = parse_type(namespace.stringify).resolve?) && namespace_type.is_a?(TypeNode) && namespace_type.class.has_method?(exp.name) %}
            {% namespace_declares_call = true %}
          {% end %}
          {% browser_context_declares_call = false %}
          {% if (browser_context_type = parse_type("JS::Browser::Context").resolve?) && browser_context_type.is_a?(TypeNode) && browser_context_type.has_method?(exp.name) && exp.args.empty? && exp.named_args.is_a?(Nop) && !exp.block %}
            {% browser_context_declares_call = true %}
          {% end %}

          {% unless locals.includes?(call_name) || JS_ALIASES.has_key?(call_name) || namespace_declares_call || browser_context_declares_call %}
            {% exp.raise "Strict mode: undeclared JS identifier `#{call_name}`. Declare externs with `js_alias \"#{call_name}\", \"...\"` or use a typed wrapper." %}
          {% end %}
        {% end %}

        {% for arg in exp.args %}
          JS::Code._strict_validate_expression({{namespace}}, {{arg}}, {{locals.empty? ? "[] of String".id : locals}})
        {% end %}

        {% unless exp.named_args.is_a?(Nop) %}
          {% for named_arg in exp.named_args %}
            JS::Code._strict_validate_expression({{namespace}}, {{named_arg.value}}, {{locals.empty? ? "[] of String".id : locals}})
          {% end %}
        {% end %}

        {% if exp.block %}
          {% block_exps = exp.block.body.is_a?(Expressions) ? exp.block.body.expressions : [exp.block.body] %}
          {% block_assigned_locals = block_exps.select { |e| e.is_a?(Assign) }.map { |a| a.target.stringify } %}
          {% block_locals = (locals + exp.block.args.map(&.id.stringify) + block_assigned_locals).uniq %}
          {% for block_exp in block_exps %}
            JS::Code._strict_validate_expression({{namespace}}, {{block_exp}}, {{block_locals.empty? ? "[] of String".id : block_locals}})
          {% end %}
        {% end %}
      {% elsif exp.is_a?(Path) %}
        {% parent_namespace = namespace.stringify.split("::")[0..-2].join("::").id %}
        {% relative_path = exp.global? ? exp.stringify.gsub(/\A::/, "") : exp %}
        {% path_name = exp.stringify.gsub(/\A"|"\z/, "") %}
        {% path_declared = false %}

        {% if (type = exp.resolve?) && type.is_a?(TypeNode) && type.class.has_method?("to_js_ref") %}
          {% path_declared = true %}
        {% elsif (type = parse_type("#{namespace}::#{relative_path.id}").resolve?) && type.is_a?(TypeNode) && type.class.has_method?("to_js_ref") %}
          {% path_declared = true %}
        {% elsif (type = parse_type("#{parent_namespace}::#{relative_path.id}").resolve?) && type.is_a?(TypeNode) && type.class.has_method?("to_js_ref") %}
          {% path_declared = true %}
        {% end %}

        {% unless path_declared || locals.includes?(path_name) || JS_ALIASES.has_key?(path_name) %}
          {% exp.raise "Strict mode: undeclared JS identifier `#{path_name}`. Declare externs with `js_alias` or use a typed wrapper exposing `to_js_ref`." %}
        {% end %}
      {% elsif exp.is_a?(Var) %}
        {% var_name = exp.stringify %}
        {% unless var_name == "self" || locals.includes?(var_name) || JS_ALIASES.has_key?(var_name) %}
          {% exp.raise "Strict mode: undeclared JS identifier `#{var_name}`. Declare externs with `js_alias` or assign/bind it before use." %}
        {% end %}
      {% elsif exp.is_a?(Assign) %}
        JS::Code._strict_validate_expression({{namespace}}, {{exp.value}}, {{locals.empty? ? "[] of String".id : locals}})
      {% elsif exp.is_a?(If) %}
        JS::Code._strict_validate_expression({{namespace}}, {{exp.cond}}, {{locals.empty? ? "[] of String".id : locals}})
        JS::Code._strict_validate_node({{namespace}}, {{exp.then}}, {{locals.empty? ? "[] of String".id : locals}})
        JS::Code._strict_validate_node({{namespace}}, {{exp.else}}, {{locals.empty? ? "[] of String".id : locals}})
      {% elsif exp.is_a?(ArrayLiteral) %}
        {% for element in exp %}
          JS::Code._strict_validate_expression({{namespace}}, {{element}}, {{locals.empty? ? "[] of String".id : locals}})
        {% end %}
      {% elsif exp.is_a?(HashLiteral) || exp.is_a?(NamedTupleLiteral) %}
        {% for key in exp.keys %}
          JS::Code._strict_validate_expression({{namespace}}, {{exp[key]}}, {{locals.empty? ? "[] of String".id : locals}})
        {% end %}
      {% elsif exp.is_a?(Return) %}
        JS::Code._strict_validate_node({{namespace}}, {{exp.exp}}, {{locals.empty? ? "[] of String".id : locals}})
      {% elsif exp.is_a?(ProcLiteral) %}
        {% proc_body_exps = exp.body.is_a?(Expressions) ? exp.body.expressions : [exp.body] %}
        {% proc_assigned_locals = proc_body_exps.select { |e| e.is_a?(Assign) }.map { |a| a.target.stringify } %}
        {% proc_locals = (locals + exp.args.map(&.name.stringify) + proc_assigned_locals).uniq %}
        {% for proc_exp in proc_body_exps %}
          JS::Code._strict_validate_expression({{namespace}}, {{proc_exp}}, {{proc_locals.empty? ? "[] of String".id : proc_locals}})
        {% end %}
      {% elsif exp.is_a?(MacroIf) %}
        \{% if {{exp.cond}} %}
          JS::Code._strict_validate_node({{namespace}}, {{exp.then}}, {{locals.empty? ? "[] of String".id : locals}})
        \{% else %}
          JS::Code._strict_validate_node({{namespace}}, {{exp.else}}, {{locals.empty? ? "[] of String".id : locals}})
        \{% end %}
      {% elsif exp.is_a?(MacroFor) %}
        \{% for {{exp.vars.splat}} in {{exp.exp}} %}
          JS::Code._strict_validate_node({{namespace}}, {{exp.body}}, {{locals.empty? ? "[] of String".id : locals}})
        \{% end %}
      {% elsif exp.is_a?(MacroExpression) || exp.is_a?(MacroLiteral) || exp.is_a?(NilLiteral) || exp.is_a?(NumberLiteral) || exp.is_a?(StringLiteral) || exp.is_a?(BoolLiteral) || exp.is_a?(SymbolLiteral) || exp.is_a?(RegexLiteral) || exp.is_a?(RangeLiteral) || exp.is_a?(TupleLiteral) || exp.is_a?(TypeNode) || exp.is_a?(Nop) %}
      {% else %}
      {% end %}
    end

    macro _eval_js_block(io, namespace, opts, &blk)
      {% exps = blk.body.is_a?(Expressions) ? blk.body.expressions : [blk.body] %}
      {% block_args = blk.args.map(&.id.stringify) %}
      {% block_assigned_locals = exps.select { |e| e.is_a?(Assign) }.map { |a| a.target.stringify } %}
      {% current_locals = (opts[:locals] + block_args + block_assigned_locals).uniq %}

      {% if opts[:strict] %}
        {% for exp in exps %}
          JS::Code._strict_validate_expression({{namespace}}, {{exp}}, {{current_locals.empty? ? "[] of String".id : current_locals}})
        {% end %}
      {% end %}

      {% if opts[:nested_scope] %}
        {% for var in exps.select { |e| e.is_a?(Assign) }.map { |a| a.target.stringify }.uniq %}
          {{io}} << "var "
          {{io}} << {{var}}
          {{io}} << ";"
        {% end %}
      {% end %}

      {% for exp in exps %}
          {% if exp.is_a?(Call) && exp.name.stringify == "_literal_js" %}
            {{io}} << {{exp.args.first}}
          {% elsif exp.is_a?(Call) && exp.name.stringify == "to_js_call" %}
            {{io}} << {{exp}}
            {% if !opts[:inline] %}
              {{io}} << ";"
            {% end %}
          {% elsif exp.is_a?(Call) && exp.name.stringify == "to_js_ref" %}
            {{io}} << {{exp}}
          {% elsif exp.is_a?(Call) && !exp.receiver && exp.name.stringify == "await" %}
            {{io}} << "await "
            {% if exp.args.size > 0 %}
              JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, locals: {{current_locals.empty? ? "[] of String".id : current_locals}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
                {{exp.args.first}}
              end
            {% end %}
            {% if !opts[:inline] %}
              {{io}} << ";"
            {% end %}
          {% elsif exp.is_a?(Call) && !exp.receiver && exp.name.stringify == "async" && exp.block %}
            {{io}} << "async function("
            {{io}} << {{exp.block.args.splat.stringify}}
            {{io}} << ") {"
            JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: false, nested_scope: true, strict: {{opts[:strict]}}, locals: {{current_locals.empty? ? "[] of String".id : current_locals}}}) {{exp.block}}
            {{io}} << "}"
            {% if !opts[:inline] %}
              {{io}} << ";"
            {% end %}
          {% elsif exp.is_a?(Call) && exp.name.stringify == "new" %}
            {{io}} << "new "
            JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, locals: {{current_locals.empty? ? "[] of String".id : current_locals}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
              {{exp.receiver}}
            end
            {{io}} << "("
            {% for arg, index in exp.args %}
              JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, locals: {{current_locals.empty? ? "[] of String".id : current_locals}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
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
            JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, locals: {{current_locals.empty? ? "[] of String".id : current_locals}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
              {{exp.args.first}}
            end
            {{io}} << "]"
            {% if !opts[:inline] %}
              {{io}} << ";"
            {% end %}
          {% elsif exp.is_a?(Call) && exp.name.stringify == "[]=" %}
            {{io}} << {{exp.receiver.stringify}}
            {{io}} << "["
            JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, locals: {{current_locals.empty? ? "[] of String".id : current_locals}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
              {{exp.args.first}}
            end
            {{io}} << "] = "
            JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, locals: {{current_locals.empty? ? "[] of String".id : current_locals}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
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
            JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, locals: {{current_locals.empty? ? "[] of String".id : current_locals}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
              {{exp.args.first}}
            end
            {% if !opts[:inline] %}
              {{io}} << ";"
            {% end %}
          {% elsif exp.is_a?(Call) %}
            {% if exp.receiver && exp.args.size == 1 && OPERATOR_CALL_NAMES.includes?(exp.name.stringify) %}
              JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, locals: {{current_locals.empty? ? "[] of String".id : current_locals}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
                {{exp.receiver}}
              end
              {{io}} << " "
              {{io}} << {{exp.name.stringify}}
              {{io}} << " "
              JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, locals: {{current_locals.empty? ? "[] of String".id : current_locals}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
                {{exp.args.first}}
              end
            {% else %}
              {% emitted_from_browser_context = false %}
              {% if exp.receiver %}
                # TODO: Replace this whole `if` by a recursive call to this macro?
                {% if exp.receiver.is_a?(Call) %}
                  JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, locals: {{current_locals.empty? ? "[] of String".id : current_locals}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
                    {{exp.receiver}}
                  end
                {% elsif exp.receiver.is_a?(Expressions) %}
                  {% for rec_exp in exp.receiver.expressions %}
                    JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, locals: {{current_locals.empty? ? "[] of String".id : current_locals}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
                      {{rec_exp}}
                    end
                  {% end %}
                {% elsif (exp.receiver.is_a?(Path) || exp.receiver.is_a?(TypeNode)) && exp.receiver.resolve? %}
                  {% if exp.receiver.resolve.is_a?(TypeNode) && exp.receiver.resolve.class.has_method?(:to_js_ref) %}
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
              {% elsif opts[:strict] && exp.args.empty? && exp.named_args.is_a?(Nop) && !exp.block %}
                {% if (browser_context_type = parse_type("JS::Browser::Context").resolve?) && browser_context_type.is_a?(TypeNode) && browser_context_type.has_method?(exp.name) %}
                  {{io}} << JS::Browser.default_context.{{exp.name}}.to_js_ref
                  {% emitted_from_browser_context = true %}
                {% end %}
              {% end %}
              {% if exp.name.stringify != "_call" && !emitted_from_browser_context %}
                {{io}} << {{JS_ALIASES[exp.name.stringify] || exp.name.stringify}}
              {% end %}
              {% has_named_args = !exp.named_args.is_a?(Nop) %}
              {% if exp.args.size > 0 || exp.block || exp.name.stringify == "_call" || has_named_args %}
                {{io}} << "("
              {% end %}
              {% for arg, index in exp.args %}
                JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, locals: {{current_locals.empty? ? "[] of String".id : current_locals}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
                  {{arg}}
                end
                {% if index < exp.args.size - 1 || exp.block || has_named_args %}
                  {{io}} << ", "
                {% end %}
              {% end %}
              {% if has_named_args %}
                {{io}} << "{"
                {% for named_arg, index in exp.named_args %}
                  {{io}} << {{named_arg.name.stringify}}
                  {{io}} << ": "
                  JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, locals: {{current_locals.empty? ? "[] of String".id : current_locals}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
                    {{named_arg.value}}
                  end
                  {% if index < exp.named_args.size - 1 %}
                    {{io}} << ", "
                  {% end %}
                {% end %}
                {{io}} << "}"
                {% if exp.block %}
                  {{io}} << ", "
                {% end %}
              {% end %}
              {% if exp.block %}
                {{io}} << "function("
                {{io}} << {{exp.block.args.splat.stringify}}
                {{io}} << ") {"
                JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: false, nested_scope: true, strict: {{opts[:strict]}}, locals: {{current_locals.empty? ? "[] of String".id : current_locals}}}) {{exp.block}}
                {{io}} << "}"
              {% end %}
              {% if exp.args.size > 0 || exp.block || exp.name.stringify == "_call" || has_named_args %}
                {{io}} << ")"
              {% end %}
            {% end %}
            {% if !opts[:inline] %}
              {{io}} << ";"
            {% end %}
          {% elsif exp.is_a?(Path) %}
            {% parent_namespace = namespace.stringify.split("::")[0..-2].join("::").id %}
            {% relative_path = exp.global? ? exp.stringify.gsub(/\A::/, "") : exp %}
            {% if (type = exp.resolve?) && type.is_a?(TypeNode) && type.class.has_method?("to_js_ref") %}
              {{io}} << {{exp}}.to_js_ref
            {% elsif (type = parse_type("#{namespace}::#{relative_path.id}").resolve?) && type.is_a?(TypeNode) && type.class.has_method?("to_js_ref") %}
              {{io}} << {{type}}.to_js_ref
            {% elsif (type = parse_type("#{parent_namespace}::#{relative_path.id}").resolve?) && type.is_a?(TypeNode) && type.class.has_method?("to_js_ref") %}
              {{io}} << {{type}}.to_js_ref
            {% else %}
              {{io}} << {{exp.stringify}}
            {% end %}
          {% elsif exp.is_a?(ArrayLiteral) %}
            {{io}} << "["
            {% for element, index in exp %}
              JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, locals: {{current_locals.empty? ? "[] of String".id : current_locals}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
                {{element}}
              end
              {% if index < exp.size - 1 %}
                {{io}} << ", "
              {% end %}
            {% end %}
            {{io}} << "]"
            {% if !opts[:inline] %}
              {{io}} << ";"
            {% end %}
          {% elsif exp.is_a?(HashLiteral) || exp.is_a?(NamedTupleLiteral) %}
            {{io}} << "{"
            {% for key, i in exp.keys %}
              {{io}} << {{key.id.stringify}}
              {{io}} << ": "
              JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, locals: {{current_locals.empty? ? "[] of String".id : current_locals}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
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
            JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, locals: {{current_locals.empty? ? "[] of String".id : current_locals}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
              {{exp.cond}}
            end
            {{io}} << ") {"
            JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: false, nested_scope: false, strict: {{opts[:strict]}}, locals: {{current_locals.empty? ? "[] of String".id : current_locals}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
              {{exp.then}}
            end
            {{io}} << "}"
            {% if !exp.else.is_a?(Nop) %}
              {{io}} << " else {"
              JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: false, nested_scope: false, strict: {{opts[:strict]}}, locals: {{current_locals.empty? ? "[] of String".id : current_locals}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
                {{exp.else}}
              end
              {{io}} << "}"
            {% end %}
          {% elsif exp.is_a?(Assign) %}
            {{exp.target}} = nil
            {{io}} << {{exp.target.stringify}}
            {{io}} << " = "
            JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, locals: {{current_locals.empty? ? "[] of String".id : current_locals}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
              {{exp.value}}
            end
            {% if !opts[:inline] %}
              {{io}} << ";"
            {% end %}
          {% elsif exp.is_a?(Return) %}
            {{io}} << "return "
            JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, locals: {{current_locals.empty? ? "[] of String".id : current_locals}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
              {{exp.exp}}
            end
            {% if !opts[:inline] %}
              {{io}} << ";"
            {% end %}
          {% elsif exp.is_a?(ProcLiteral) %}
            {{io}} << "({{exp.args.map(&.name).splat}}) => {"
            JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: false, nested_scope: false, strict: {{opts[:strict]}}, locals: {{current_locals.empty? ? "[] of String".id : current_locals}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
              {{exp.body}}
            end
            {{io}} << "}"
          {% elsif exp.is_a?(MacroIf) %}
            \{% if {{exp.cond}} %}
              JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: false, nested_scope: false, strict: {{opts[:strict]}}, locals: {{current_locals.empty? ? "[] of String".id : current_locals}}}) do
                {{exp.then}}
              end
            \{% else %}
              JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: false, nested_scope: false, strict: {{opts[:strict]}}, locals: {{current_locals.empty? ? "[] of String".id : current_locals}}}) do
                {{exp.else}}
              end
            \{% end %}
          {% elsif exp.is_a?(MacroFor) %}
            \{% for {{exp.vars.splat}} in {{exp.exp}} %}
              JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: false, nested_scope: false, strict: {{opts[:strict]}}, locals: {{current_locals.empty? ? "[] of String".id : current_locals}}}) do
                {{exp.body}}
              end
            \{% end %}
          {% elsif exp.is_a?(MacroExpression) || exp.is_a?(MacroLiteral) %}
            {{exp}}
          {% elsif exp.is_a?(NilLiteral) %}
            {{io}} << "undefined"
            {% if !opts[:inline] %}
              {{io}} << ";"
            {% end %}
          {% else %}
            {{io}} << {{exp.stringify}}
          {% end %}
      {% end %}
    end
  end
end
