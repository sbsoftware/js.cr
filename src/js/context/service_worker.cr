require "./cache"
require "./context_object"

module JS
  module Context
    class ServiceWorkerGlobalScope < JS::Context::ContextObject
      def initialize(to_js_ref : String = "self")
        super(to_js_ref)
      end

      def caches : JS::Context::CacheStorage
        JS::Context::CacheStorage.new(to_js_ref.empty? ? "caches" : "#{to_js_ref}.caches")
      end
    end
  end
end
