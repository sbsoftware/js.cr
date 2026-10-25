require "./event_target"
require "./console"
require "./undefined"

module JS
  module Context
    class Promise(T) < JS::Context::ContextObject
    end

    class WorkerLocation < JS::Context::ContextObject
    end

    class Request < JS::Context::ContextObject
    end

    class Response < JS::Context::ContextObject
    end

    class Value < JS::Context::ContextObject
    end

    class Cache < JS::Context::ContextObject
      def match(request) : JS::Context::Promise(JS::Context::Response)
        JS::Context::Promise(JS::Context::Response).new(to_js_ref, "match", request)
      end

      def put(request, response) : JS::Context::Promise(JS::Context::Undefined)
        JS::Context::Promise(JS::Context::Undefined).new(to_js_ref, "put", request, response)
      end
    end

    class CacheStorage < JS::Context::ContextObject
      def open(cache_name) : JS::Context::Promise(JS::Context::Cache)
        JS::Context::Promise(JS::Context::Cache).new(to_js_ref, "open", cache_name)
      end

      def match(request) : JS::Context::Promise(JS::Context::Response)
        JS::Context::Promise(JS::Context::Response).new(to_js_ref, "match", request)
      end
    end

    class Clients < JS::Context::ContextObject
      def claim : JS::Context::Promise(JS::Context::Undefined)
        JS::Context::Promise(JS::Context::Undefined).new(to_js_ref, "claim")
      end
    end

    class ExtendableEvent < JS::Context::ContextObject
      def initialize(to_js_ref : String)
        super(to_js_ref)
      end

      def waitUntil(promise) : JS::Context::Undefined
        JS::Context::Undefined.new(to_js_ref, "waitUntil", promise)
      end
    end

    class ExtendableMessageEvent < JS::Context::ExtendableEvent
      def data : JS::Context::Value
        JS::Context::Value.new("#{to_js_ref}.data")
      end
    end

    class FetchEvent < JS::Context::ExtendableEvent
      def request : JS::Context::Request
        JS::Context::Request.new("#{to_js_ref}.request")
      end

      def respondWith(response) : JS::Context::Undefined
        JS::Context::Undefined.new(to_js_ref, "respondWith", response)
      end
    end

    class ServiceWorkerGlobalScope < JS::Context::EventTarget
      def initialize
        super("self")
      end

      def skipWaiting : JS::Context::Promise(JS::Context::Undefined)
        JS::Context::Promise(JS::Context::Undefined).new(to_js_ref, "skipWaiting")
      end

      def console : JS::Context::Console
        JS::Context::Console.new
      end

      def clients : JS::Context::Clients
        JS::Context::Clients.new("#{to_js_ref}.clients")
      end

      def location : JS::Context::WorkerLocation
        JS::Context::WorkerLocation.new("#{to_js_ref}.location")
      end

      def caches : JS::Context::CacheStorage
        JS::Context::CacheStorage.new("#{to_js_ref}.caches")
      end

      def fetch(request) : JS::Context::Promise(JS::Context::Response)
        JS::Context::Promise(JS::Context::Response).new(to_js_ref, "fetch", request)
      end
    end

    def self.service_worker : JS::Context::ServiceWorkerGlobalScope
      JS::Context::ServiceWorkerGlobalScope.new
    end
  end
end
