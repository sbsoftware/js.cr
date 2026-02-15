require "./context_object"
require "./undefined"

module JS
  module Context
    class ShareData < JS::Context::ContextObject
      def initialize(text : String, title : String? = nil, url : String? = nil)
        super(build_payload_ref(text, title, url))
      end

      private def build_payload_ref(text : String, title : String?, url : String?) : String
        String.build do |io|
          io << "{text: "
          io << text.to_js_ref
          if title
            io << ", title: "
            io << title.to_js_ref
          end
          if url
            io << ", url: "
            io << url.to_js_ref
          end
          io << "}"
        end
      end
    end

    class Navigator < JS::Context::ContextObject
      def initialize
        super("navigator")
      end

      def share(*, text : String, title : String? = nil, url : String? = nil) : JS::Context::Undefined
        payload = JS::Context::ShareData.new(text, title, url)
        JS::Context::Undefined.new(to_js_ref, "share", payload)
      end
    end
  end
end
