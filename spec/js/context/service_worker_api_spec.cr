require "../../spec_helper"

module JS::Context::ServiceWorkerAPISpec
  class WorkerListenersCode < JS::Code
    def_to_js strict: true, context: :service_worker do
      self.addEventListener("install") do |event|
        event.waitUntil(self.skipWaiting._call)
      end
      self.addEventListener("activate") do |event|
        event.waitUntil(self.clients.claim._call)
      end
      self.addEventListener("message") do |event|
        console.log(event.data)
      end
      self.addEventListener("fetch") do |event|
        event.respondWith(self.fetch(event.request))
      end
    end
  end

  class WorkerCacheCode < JS::Code
    def_to_js strict: true, context: :service_worker do
      self.addEventListener("fetch") do |event|
        response_promise = self.caches.match(event.request)
        event.respondWith(response_promise)
      end
    end
  end

  class BrowserSelfCode < JS::Code
    def_to_js strict: true do
      self.toString._call
    end
  end

  class WorkerFragmentFile < JS::File
    js_fragment strict: true, context: :service_worker do
      self.addEventListener("install") do |event|
        event.waitUntil(self.skipWaiting._call)
      end
    end
  end

  describe "strict service worker context" do
    it "emits typed install, activate, message, and fetch listeners" do
      expected = <<-JS.squish
      self.addEventListener("install", function(event) {
        event.waitUntil(self.skipWaiting());
      });
      self.addEventListener("activate", function(event) {
        event.waitUntil(self.clients.claim());
      });
      self.addEventListener("message", function(event) {
        console.log(event.data);
      });
      self.addEventListener("fetch", function(event) {
        event.respondWith(self.fetch(event.request));
      });
      JS

      WorkerListenersCode.to_js.should eq(expected)
    end

    it "composes FetchEvent, Promise, and CacheStorage references" do
      expected = <<-JS.squish
      self.addEventListener("fetch", function(event) {
        var response_promise;
        response_promise = self.caches.match(event.request);
        event.respondWith(response_promise);
      });
      JS

      WorkerCacheCode.to_js.should eq(expected)
    end

    it "keeps the default context's self as a JavaScript instance receiver" do
      BrowserSelfCode.to_js.should eq("this.toString();")
    end

    it "allows file fragments to select the context explicitly" do
      WorkerFragmentFile.to_js.should eq(%(self.addEventListener("install", function(event) {event.waitUntil(self.skipWaiting());});))
    end
  end

  describe "service worker wrappers" do
    it "keeps composed operations typed" do
      worker = JS::Context.service_worker
      event = JS::Context::FetchEvent.new("event")

      worker.skipWaiting.to_js_ref.should eq("self.skipWaiting()")
      worker.clients.claim.to_js_ref.should eq("self.clients.claim()")
      worker.caches.match(event.request).to_js_ref.should eq("self.caches.match(event.request)")
      event.respondWith(worker.fetch(event.request)).to_js_ref.should eq("event.respondWith(self.fetch(event.request))")
      JS::Context::ExtendableMessageEvent.new("event").data.to_js_ref.should eq("event.data")
    end
  end
end
