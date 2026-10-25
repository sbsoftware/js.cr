require "./context_object"
require "./service_worker"
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

      def serviceWorker : JS::Context::ServiceWorkerContainer?
        # Service workers are unavailable in some browser contexts, so retain feature-detection semantics.
        JS::Context::ServiceWorkerContainer.new("#{to_js_ref}.serviceWorker").as(JS::Context::ServiceWorkerContainer?)
      end
    end
  end
end
