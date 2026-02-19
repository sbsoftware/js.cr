module JS
  abstract class Code
    OPERATOR_CALL_NAMES             = %w[+ - * / ** ^ // & | && || > >= < <= == !=]
    VARIABLE_DECLARATION_CALL_NAMES = %w[let const]

    JS_ALIASES = {} of String => String

    macro js_alias(name, aliased_name)
      {% JS_ALIASES[name.id.stringify] = aliased_name.id.stringify %}
    end

    macro def_to_js(strict = false, &blk)
      def self.to_js(io : IO)
        JS::Code._eval_js_block(
          io,
          {{@type.resolve}},
          {inline: false, nested_scope: true, strict: {{strict}}, declared_vars: [] of String}
        ) {{blk}}
      end

      def self.to_js
        String.build do |str|
          to_js(str)
        end
      end
    end

    macro _eval_js_block(io, namespace, opts, &blk)
      {% exps = blk.body.is_a?(Expressions) ? blk.body.expressions : [blk.body] %}
      {% scope_declared_vars = [] of String %}
      {% for declared_var in opts[:declared_vars] %}
        {% scope_declared_vars << declared_var %}
      {% end %}

      # Collect declared names in this scope up front to avoid emitting duplicate
      # `var` declarations for variables that are explicitly introduced via `let`/`const`.
      {% var_declaration_exclusions = [] of String %}
      {% for declared_var in scope_declared_vars %}
        {% var_declaration_exclusions << declared_var %}
      {% end %}
      {% for exp in exps %}
        {% if exp.is_a?(Call) && !exp.receiver && VARIABLE_DECLARATION_CALL_NAMES.includes?(exp.name.stringify) && exp.args.size > 0 %}
          {% first_arg = exp.args.first %}
          {% if first_arg.is_a?(Assign) && first_arg.target.is_a?(Var) %}
            {% var_declaration_exclusions << first_arg.target.stringify %}
          {% elsif first_arg.is_a?(Var) %}
            {% var_declaration_exclusions << first_arg.stringify %}
          {% elsif first_arg.is_a?(Call) && !first_arg.receiver && first_arg.args.empty? && first_arg.named_args.is_a?(Nop) && first_arg.block.is_a?(Nop) %}
            {% var_declaration_exclusions << first_arg.name.stringify %}
          {% end %}
        {% end %}
      {% end %}

      {% if opts[:nested_scope] %}
        {% for var in exps.select { |e| e.is_a?(Assign) }.map { |a| a.target.stringify }.uniq.reject { |name| var_declaration_exclusions.includes?(name) } %}
          {{io}} << "var "
          {{io}} << {{var}}
          {{io}} << ";"
        {% end %}
      {% end %}

      {% for exp in exps %}
          {% if exp.is_a?(Call) && !exp.receiver && VARIABLE_DECLARATION_CALL_NAMES.includes?(exp.name.stringify) %}
            {% declaration_kind = exp.name.stringify %}
            {% if exp.args.empty? %}
              {% if declaration_kind == "let" %}
                {{exp.raise "`let` requires one argument. Use `let my_var` or `let my_var = value`."}}
              {% else %}
                {{exp.raise "`const` requires one argument. Use `const my_var = value`."}}
              {% end %}
            {% elsif exp.args.size > 1 %}
              {% if declaration_kind == "let" %}
                {{exp.raise "`let` accepts exactly one argument. Use `let my_var` or `let my_var = value`."}}
              {% else %}
                {{exp.raise "`const` accepts exactly one argument. Use `const my_var = value`."}}
              {% end %}
            {% end %}

            {% declared_name = nil %}

            {% if exp.args.first.is_a?(Assign) %}
              {% assignment = exp.args.first %}
              {% unless assignment.target.is_a?(Var) %}
                {{assignment.raise "`#{declaration_kind}` declarations require a plain variable name on the left-hand side."}}
              {% end %}
              {% declared_name = assignment.target.stringify %}
              {{assignment.target}} = nil
              {% scope_declared_vars << assignment.target.stringify %}
              {{io}} << {{declaration_kind}}
              {{io}} << " "
              {{io}} << {{assignment.target.stringify}}
              {{io}} << " = "
              JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, declared_vars: {{scope_declared_vars.empty? ? "[] of String".id : scope_declared_vars}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
                {{assignment.value}}
              end
            {% else %}
              {% name_arg = exp.args.first %}
              {% if name_arg.is_a?(Var) %}
                {% declared_name = name_arg.stringify %}
                {{name_arg}} = nil
              {% elsif name_arg.is_a?(Call) && !name_arg.receiver && name_arg.args.empty? && name_arg.named_args.is_a?(Nop) && name_arg.block.is_a?(Nop) %}
                {% declared_name = name_arg.name.stringify %}
                {{name_arg.name.id}} = nil
              {% else %}
                {{name_arg.raise "`#{declaration_kind}` requires a plain variable name as its first argument."}}
              {% end %}

              {% scope_declared_vars << declared_name %}
              {{io}} << {{declaration_kind}}
              {{io}} << " "
              {{io}} << {{declared_name}}

              {% if declaration_kind == "const" %}
                {{exp.raise "`const` requires an initializer. Use `const my_var = value`."}}
              {% end %}
            {% end %}

            {% if !opts[:inline] %}
              {{io}} << ";"
            {% end %}
          {% elsif exp.is_a?(Call) && exp.name.stringify == "_literal_js" && !opts[:strict] %}
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
              JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, declared_vars: {{scope_declared_vars.empty? ? "[] of String".id : scope_declared_vars}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
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
            JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: false, nested_scope: true, strict: {{opts[:strict]}}, declared_vars: {{scope_declared_vars.empty? ? "[] of String".id : scope_declared_vars}}}) {{exp.block}}
            {{io}} << "}"
            {% if !opts[:inline] %}
              {{io}} << ";"
            {% end %}
          {% elsif exp.is_a?(Call) && exp.name.stringify == "new" %}
            {{io}} << "new "
            JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, declared_vars: {{scope_declared_vars.empty? ? "[] of String".id : scope_declared_vars}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
              {{exp.receiver}}
            end
            {{io}} << "("
            {% for arg, index in exp.args %}
              JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, declared_vars: {{scope_declared_vars.empty? ? "[] of String".id : scope_declared_vars}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
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
            JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, declared_vars: {{scope_declared_vars.empty? ? "[] of String".id : scope_declared_vars}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
              {{exp.args.first}}
            end
            {{io}} << "]"
            {% if !opts[:inline] %}
              {{io}} << ";"
            {% end %}
          {% elsif exp.is_a?(Call) && exp.name.stringify == "[]=" %}
            {{io}} << {{exp.receiver.stringify}}
            {{io}} << "["
            JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, declared_vars: {{scope_declared_vars.empty? ? "[] of String".id : scope_declared_vars}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
              {{exp.args.first}}
            end
            {{io}} << "] = "
            JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, declared_vars: {{scope_declared_vars.empty? ? "[] of String".id : scope_declared_vars}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
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
            JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, declared_vars: {{scope_declared_vars.empty? ? "[] of String".id : scope_declared_vars}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
              {{exp.args.first}}
            end
            {% if !opts[:inline] %}
              {{io}} << ";"
            {% end %}
          {% elsif exp.is_a?(Call) %}
            {% if exp.receiver && exp.args.size == 1 && OPERATOR_CALL_NAMES.includes?(exp.name.stringify) %}
              JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, declared_vars: {{scope_declared_vars.empty? ? "[] of String".id : scope_declared_vars}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
                {{exp.receiver}}
              end
              {{io}} << " "
              {{io}} << {{exp.name.stringify}}
              {{io}} << " "
              JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, declared_vars: {{scope_declared_vars.empty? ? "[] of String".id : scope_declared_vars}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
                {{exp.args.first}}
              end
            {% else %}
              {% if opts[:strict] && !exp.receiver && !JS_ALIASES.has_key?(exp.name.stringify) && !scope_declared_vars.includes?(exp.name.stringify) %}
                JS::Context.default.{{exp.name}}
              {% end %}
              {% emitted_from_strict_context = false %}
              {% if exp.receiver %}
                # TODO: Replace this whole `if` by a recursive call to this macro?
                {% if exp.receiver.is_a?(Call) %}
                  JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, declared_vars: {{scope_declared_vars.empty? ? "[] of String".id : scope_declared_vars}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
                    {{exp.receiver}}
                  end
                {% elsif exp.receiver.is_a?(Expressions) %}
                  {% for rec_exp in exp.receiver.expressions %}
                    JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, declared_vars: {{scope_declared_vars.empty? ? "[] of String".id : scope_declared_vars}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
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
              {% elsif opts[:strict] && exp.args.empty? && exp.named_args.is_a?(Nop) && !exp.block && !JS_ALIASES.has_key?(exp.name.stringify) && !scope_declared_vars.includes?(exp.name.stringify) %}
                  {{io}} << JS::Context.default.{{exp.name}}.to_js_ref
                  {% emitted_from_strict_context = true %}
              {% end %}
              {% if exp.name.stringify != "_call" && !emitted_from_strict_context %}
                {{io}} << {{JS_ALIASES[exp.name.stringify] || exp.name.stringify}}
              {% end %}
              {% has_named_args = !exp.named_args.is_a?(Nop) %}
              {% if exp.args.size > 0 || exp.block || exp.name.stringify == "_call" || has_named_args %}
                {{io}} << "("
              {% end %}
              {% for arg, index in exp.args %}
                JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, declared_vars: {{scope_declared_vars.empty? ? "[] of String".id : scope_declared_vars}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
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
                  JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, declared_vars: {{scope_declared_vars.empty? ? "[] of String".id : scope_declared_vars}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
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
                JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: false, nested_scope: true, strict: {{opts[:strict]}}, declared_vars: {{scope_declared_vars.empty? ? "[] of String".id : scope_declared_vars}}}) {{exp.block}}
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
              JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, declared_vars: {{scope_declared_vars.empty? ? "[] of String".id : scope_declared_vars}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
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
              JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, declared_vars: {{scope_declared_vars.empty? ? "[] of String".id : scope_declared_vars}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
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
            JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, declared_vars: {{scope_declared_vars.empty? ? "[] of String".id : scope_declared_vars}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
              {{exp.cond}}
            end
            {{io}} << ") {"
            JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: false, nested_scope: false, strict: {{opts[:strict]}}, declared_vars: {{scope_declared_vars.empty? ? "[] of String".id : scope_declared_vars}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
              {{exp.then}}
            end
            {{io}} << "}"
            {% if !exp.else.is_a?(Nop) %}
              {{io}} << " else {"
              JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: false, nested_scope: false, strict: {{opts[:strict]}}, declared_vars: {{scope_declared_vars.empty? ? "[] of String".id : scope_declared_vars}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
                {{exp.else}}
              end
              {{io}} << "}"
            {% end %}
          {% elsif exp.is_a?(Assign) %}
            {{exp.target}} = nil
            {{io}} << {{exp.target.stringify}}
            {{io}} << " = "
            JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, declared_vars: {{scope_declared_vars.empty? ? "[] of String".id : scope_declared_vars}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
              {{exp.value}}
            end
            {% if !opts[:inline] %}
              {{io}} << ";"
            {% end %}
          {% elsif exp.is_a?(Return) %}
            {{io}} << "return "
            JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: true, nested_scope: false, strict: {{opts[:strict]}}, declared_vars: {{scope_declared_vars.empty? ? "[] of String".id : scope_declared_vars}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
              {{exp.exp}}
            end
            {% if !opts[:inline] %}
              {{io}} << ";"
            {% end %}
          {% elsif exp.is_a?(ProcLiteral) %}
            {{io}} << "({{exp.args.map(&.name).splat}}) => {"
            JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: false, nested_scope: false, strict: {{opts[:strict]}}, declared_vars: {{scope_declared_vars.empty? ? "[] of String".id : scope_declared_vars}}}) do {{blk.args.empty? ? "".id : "|#{blk.args.splat}|".id}}
              {{exp.body}}
            end
            {{io}} << "}"
          {% elsif exp.is_a?(MacroIf) %}
            \{% if {{exp.cond}} %}
              JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: false, nested_scope: false, strict: {{opts[:strict]}}, declared_vars: {{scope_declared_vars.empty? ? "[] of String".id : scope_declared_vars}}}) do
                {{exp.then}}
              end
            \{% else %}
              JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: false, nested_scope: false, strict: {{opts[:strict]}}, declared_vars: {{scope_declared_vars.empty? ? "[] of String".id : scope_declared_vars}}}) do
                {{exp.else}}
              end
            \{% end %}
          {% elsif exp.is_a?(MacroFor) %}
            \{% for {{exp.vars.splat}} in {{exp.exp}} %}
              JS::Code._eval_js_block({{io}}, {{namespace}}, {inline: false, nested_scope: false, strict: {{opts[:strict]}}, declared_vars: {{scope_declared_vars.empty? ? "[] of String".id : scope_declared_vars}}}) do
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
