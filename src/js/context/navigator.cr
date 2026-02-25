require "./context_object"
require "./undefined"

module JS
  module Context
    class Navigator < JS::Context::ContextObject
      def initialize
        super("navigator")
      end

      def share(*, text : String, title : String? = nil, url : String? = nil) : JS::Context::Undefined
        # Omit nil keys so we emit a realistic Web Share payload object.
        payload = if title && url
                    {text: text, title: title, url: url}
                  elsif title
                    {text: text, title: title}
                  elsif url
                    {text: text, url: url}
                  else
                    {text: text}
                  end
        JS::Context::Undefined.new(to_js_ref, "share", payload)
      end
    end
  end
end
