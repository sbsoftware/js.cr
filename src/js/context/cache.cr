require "./context_object"
require "./http"

module JS
  module Context
    alias CacheKey = String | JS::Context::Request

    class CacheStorage < JS::Context::ContextObject
      def initialize(to_js_ref : String)
        super(to_js_ref)
      end

      def open(cache_name : String) : JS::Context::Promise(JS::Context::Cache)
        JS::Context::Promise(JS::Context::Cache).new(to_js_ref, "open", cache_name)
      end

      def match(request : JS::Context::CacheKey) : JS::Context::Promise(JS::Context::Response?)
        JS::Context::Promise(JS::Context::Response?).new(to_js_ref, "match", request)
      end

      def has(cache_name : String) : JS::Context::Promise(JS::Context::Value)
        JS::Context::Promise(JS::Context::Value).new(to_js_ref, "has", cache_name)
      end

      def delete(cache_name : String) : JS::Context::Promise(JS::Context::Value)
        JS::Context::Promise(JS::Context::Value).new(to_js_ref, "delete", cache_name)
      end

      def keys : JS::Context::Promise(Array(JS::Context::Value))
        JS::Context::Promise(Array(JS::Context::Value)).new(to_js_ref, "keys")
      end
    end

    class Cache < JS::Context::ContextObject
      def match(request : JS::Context::CacheKey) : JS::Context::Promise(JS::Context::Response?)
        JS::Context::Promise(JS::Context::Response?).new(to_js_ref, "match", request)
      end

      def matchAll(request : JS::Context::CacheKey) : JS::Context::Promise(Array(JS::Context::Response))
        JS::Context::Promise(Array(JS::Context::Response)).new(to_js_ref, "matchAll", request)
      end

      def add(request : JS::Context::CacheKey) : JS::Context::Promise(JS::Context::Undefined)
        JS::Context::Promise(JS::Context::Undefined).new(to_js_ref, "add", request)
      end

      def addAll(requests) : JS::Context::Promise(JS::Context::Undefined)
        JS::Context::Promise(JS::Context::Undefined).new(to_js_ref, "addAll", requests)
      end

      def put(request : JS::Context::CacheKey, response : JS::Context::Response) : JS::Context::Promise(JS::Context::Undefined)
        JS::Context::Promise(JS::Context::Undefined).new(to_js_ref, "put", request, response)
      end

      def delete(request : JS::Context::CacheKey) : JS::Context::Promise(JS::Context::Value)
        JS::Context::Promise(JS::Context::Value).new(to_js_ref, "delete", request)
      end

      def keys : JS::Context::Promise(Array(JS::Context::Request))
        JS::Context::Promise(Array(JS::Context::Request)).new(to_js_ref, "keys")
      end
    end
  end
end
