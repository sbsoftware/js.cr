require "./context_object"
require "./undefined"

module JS
  module Context
    enum RequestMethod
      Get
      Head
      Post
      Put
      Delete
      Connect
      Options
      Trace
      Patch

      def to_js_ref : String
        to_s.upcase.to_js_ref
      end
    end

    enum RequestMode
      Cors
      NoCors
      SameOrigin
      Navigate

      def to_js_ref : String
        to_s.underscore.gsub('_', '-').to_js_ref
      end
    end

    enum RequestCredentials
      Omit
      SameOrigin
      Include

      def to_js_ref : String
        to_s.underscore.gsub('_', '-').to_js_ref
      end
    end

    enum RequestCache
      Default
      NoStore
      Reload
      NoCache
      ForceCache
      OnlyIfCached

      def to_js_ref : String
        to_s.underscore.gsub('_', '-').to_js_ref
      end
    end

    alias HeadersInit = Hash(String, String) | JS::Context::Headers
    alias RequestInput = String | JS::Context::Request
    alias RequestMethodValue = String | JS::Context::RequestMethod
    alias RequestModeValue = String | JS::Context::RequestMode
    alias RequestCredentialsValue = String | JS::Context::RequestCredentials
    alias RequestCacheValue = String | JS::Context::RequestCache

    class Value < JS::Context::ContextObject
      def initialize(to_js_ref : String)
        super(to_js_ref)
      end

      def initialize(preceding_call_chain : String, method_name : String, *args)
        super(preceding_call_chain, method_name, *args)
      end
    end

    class Promise(T) < JS::Context::ContextObject
      def self.to_js_ref : String
        "Promise"
      end

      def self.all(promises) : JS::Context::Promise(Array(T))
        JS::Context::Promise(Array(T)).new("Promise", "all", promises)
      end
    end

    class Headers < JS::Context::ContextObject
      def self.to_js_ref : String
        "Headers"
      end

      def initialize
        super("new Headers()")
      end

      def initialize(to_js_ref : String)
        super(to_js_ref)
      end

      def initialize(init : JS::Context::HeadersInit)
        super("new Headers(#{init.to_js_ref})")
      end

      def get(name : String) : JS::Context::Value
        JS::Context::Value.new(to_js_ref, "get", name)
      end

      def has(name : String) : JS::Context::Value
        JS::Context::Value.new(to_js_ref, "has", name)
      end

      def set(name : String, value : String) : JS::Context::Undefined
        JS::Context::Undefined.new(to_js_ref, "set", name, value)
      end

      def append(name : String, value : String) : JS::Context::Undefined
        JS::Context::Undefined.new(to_js_ref, "append", name, value)
      end

      def delete(name : String) : JS::Context::Undefined
        JS::Context::Undefined.new(to_js_ref, "delete", name)
      end
    end

    class RequestOptions < JS::Context::ContextObject
      def initialize(*, method : JS::Context::RequestMethodValue? = nil, mode : JS::Context::RequestModeValue? = nil, credentials : JS::Context::RequestCredentialsValue? = nil, cache : JS::Context::RequestCacheValue? = nil, headers : JS::Context::HeadersInit? = nil)
        super(JS::Context.build_options(method: method, mode: mode, credentials: credentials, cache: cache, headers: headers))
      end
    end

    class ResponseOptions < JS::Context::ContextObject
      def initialize(*, status : Int? = nil, headers : JS::Context::HeadersInit? = nil)
        super(JS::Context.build_options(status: status, headers: headers))
      end
    end

    class Request < JS::Context::ContextObject
      def self.to_js_ref : String
        "Request"
      end

      def initialize(input : JS::Context::RequestInput, *, method : JS::Context::RequestMethodValue? = nil, mode : JS::Context::RequestModeValue? = nil, credentials : JS::Context::RequestCredentialsValue? = nil, cache : JS::Context::RequestCacheValue? = nil, headers : JS::Context::HeadersInit? = nil)
        super(JS::Context.build_constructor("Request", input, method: method, mode: mode, credentials: credentials, cache: cache, headers: headers))
      end

      def initialize(input : JS::Context::RequestInput, options : JS::Context::RequestOptions)
        super("new Request(#{input.to_js_ref}, #{options.to_js_ref})")
      end

      def url : JS::Context::Value
        JS::Context::Value.new("#{to_js_ref}.url")
      end

      def method : JS::Context::Value
        JS::Context::Value.new("#{to_js_ref}.method")
      end

      def mode : JS::Context::Value
        JS::Context::Value.new("#{to_js_ref}.mode")
      end

      def headers : JS::Context::Headers
        JS::Context::Headers.new("#{to_js_ref}.headers")
      end
    end

    class Response < JS::Context::ContextObject
      def self.to_js_ref : String
        "Response"
      end

      def initialize(body = nil, *, status : Int? = nil, headers : JS::Context::HeadersInit? = nil)
        super(JS::Context.build_constructor("Response", body, status: status, headers: headers))
      end

      def initialize(body, options : JS::Context::ResponseOptions)
        super("new Response(#{body.to_js_ref}, #{options.to_js_ref})")
      end

      def initialize(preceding_call_chain : String, method_name : String, *args)
        super(preceding_call_chain, method_name, *args)
      end

      def ok : JS::Context::Value
        JS::Context::Value.new("#{to_js_ref}.ok")
      end

      def headers : JS::Context::Headers
        JS::Context::Headers.new("#{to_js_ref}.headers")
      end

      def clone : JS::Context::Response
        JS::Context::Response.new(to_js_ref, "clone")
      end

      def json : JS::Context::Promise(JS::Context::Value)
        JS::Context::Promise(JS::Context::Value).new(to_js_ref, "json")
      end

      def text : JS::Context::Promise(JS::Context::Value)
        JS::Context::Promise(JS::Context::Value).new(to_js_ref, "text")
      end
    end

    # Constructors omit nil options because absent browser options and explicit null values differ.
    def self.build_constructor(name : String, first_arg, **options) : String
      String.build do |io|
        io << "new " << name << "(" << first_arg.to_js_ref
        serialized_options = build_options(**options)
        io << ", " << serialized_options unless serialized_options == "{}"
        io << ")"
      end
    end

    def self.build_options(**options) : String
      String.build do |io|
        io << "{"
        wrote_option = false
        options.each do |key, value|
          next if value.nil?
          io << ", " if wrote_option
          io << key << ": " << value.to_js_ref
          wrote_option = true
        end
        io << "}"
      end
    end
  end
end
