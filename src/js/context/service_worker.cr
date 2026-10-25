require "./context_object"
require "./promise"
require "./undefined"

module JS
  module Context
    class ServiceWorker < JS::Context::ContextObject
      def initialize(to_js_ref : String)
        super(to_js_ref)
      end

      def postMessage(message) : JS::Context::Undefined
        JS::Context::Undefined.new(to_js_ref, "postMessage", message)
      end
    end

    class ServiceWorkerRegistration < JS::Context::ContextObject
      def initialize(to_js_ref : String)
        super(to_js_ref)
      end

      def active : JS::Context::ServiceWorker?
        JS::Context::ServiceWorker.new("#{to_js_ref}.active").as(JS::Context::ServiceWorker?)
      end

      def waiting : JS::Context::ServiceWorker?
        JS::Context::ServiceWorker.new("#{to_js_ref}.waiting").as(JS::Context::ServiceWorker?)
      end

      def installing : JS::Context::ServiceWorker?
        JS::Context::ServiceWorker.new("#{to_js_ref}.installing").as(JS::Context::ServiceWorker?)
      end
    end

    class ServiceWorkerContainer < JS::Context::ContextObject
      def initialize(to_js_ref : String)
        super(to_js_ref)
      end

      def ready : JS::Context::Promise(JS::Context::ServiceWorkerRegistration)
        JS::Context::Promise(JS::Context::ServiceWorkerRegistration).new("#{to_js_ref}.ready")
      end

      def register(script_url : String, **options) : JS::Context::Promise(JS::Context::ServiceWorkerRegistration)
        if options.empty?
          JS::Context::Promise(JS::Context::ServiceWorkerRegistration).new(to_js_ref, "register", script_url)
        else
          JS::Context::Promise(JS::Context::ServiceWorkerRegistration).new(to_js_ref, "register", script_url, options)
        end
      end

      def controller : JS::Context::ServiceWorker?
        JS::Context::ServiceWorker.new("#{to_js_ref}.controller").as(JS::Context::ServiceWorker?)
      end
    end
  end
end
