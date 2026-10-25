require "../../spec_helper"

module JS::Context::CacheSpec
  class StrictVersionCleanupCode < JS::Code
    def_to_js strict: true do
      names = await(caches.keys._call)
      names.forEach do |name|
        if name != "pages-v2"
          await(caches.delete(name))
        end
      end
    end
  end

  class StrictPageLookupCode < JS::Code
    def_to_js strict: true do
      cache = await(caches.open("pages-v2"))
      cached = await(cache.match(Request.new("/play")))
      if cached
        return cached
      end
    end
  end

  class StrictResponseWriteCode < JS::Code
    def_to_js strict: true do
      cache = await(caches.open("pages-v2"))
      response = Response.new("offline", status: 200)
      await(cache.put("/play", response))
      await(cache.add("/shell.css"))
      await(cache.addAll(["/app.js", "/app.css"]))
    end
  end

  class StrictEntryDeletionCode < JS::Code
    def_to_js strict: true do
      cache = await(caches.open("pages-v2"))
      await(cache.delete(Request.new("/stale")))
      requests = await(cache.keys._call)
      matches = await(cache.matchAll("/play"))
      present = await(caches.has("pages-v2"))
      console.log(requests, matches, present)
    end
  end

  describe "strict CacheStorage and Cache APIs" do
    it "transpiles cache version cleanup" do
      StrictVersionCleanupCode.to_js.should eq(<<-JS.squish)
      var names;
      names = await caches.keys();
      names.forEach(function(name) {
        if (name != "pages-v2") {
          await caches.delete(name);
        }
      });
      JS
    end

    it "transpiles nullable page lookup and response return" do
      StrictPageLookupCode.to_js.should eq(<<-JS.squish)
      var cache;
      var cached;
      cache = await caches.open("pages-v2");
      cached = await cache.match(new Request("/play"));
      if (cached) {
        return cached;
      }
      JS
    end

    it "transpiles response writes and cache population" do
      StrictResponseWriteCode.to_js.should eq(<<-JS.squish)
      var cache;
      var response;
      cache = await caches.open("pages-v2");
      response = new Response("offline", {status: 200});
      await cache.put("/play", response);
      await cache.add("/shell.css");
      await cache.addAll(["/app.js", "/app.css"]);
      JS
    end

    it "transpiles entry deletion and remaining Cache APIs" do
      StrictEntryDeletionCode.to_js.should eq(<<-JS.squish)
      var cache;
      var requests;
      var matches;
      var present;
      cache = await caches.open("pages-v2");
      await cache.delete(new Request("/stale"));
      requests = await cache.keys();
      matches = await cache.matchAll("/play");
      present = await caches.has("pages-v2");
      console.log(requests, matches, present);
      JS
    end
  end

  describe "typed cache wrappers" do
    it "builds cache calls from a service-worker global scope" do
      caches = JS::Context::ServiceWorkerGlobalScope.new.caches
      cache = JS::Context::Cache.new("caches", "open", "pages-v2")
      request = JS::Context::Request.new("/play")
      response = JS::Context::Response.new("offline")

      caches.to_js_ref.should eq("self.caches")
      caches.open("pages-v2").to_js_ref.should eq(%(self.caches.open("pages-v2")))
      caches.match(request).to_js_ref.should eq(%(self.caches.match(new Request("/play"))))
      cache.match("/play").to_js_ref.should eq(%(caches.open("pages-v2").match("/play")))
      cache.put(request, response).to_js_ref.should eq(%(caches.open("pages-v2").put(new Request("/play"), new Response("offline"))))
      cache.delete("/stale").to_js_ref.should eq(%(caches.open("pages-v2").delete("/stale")))
    end
  end
end
