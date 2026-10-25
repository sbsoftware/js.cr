require "../../spec_helper"

module JS::Context::BrowserAPISpec
  class StrictWindowTimersCode < JS::Code
    def_to_js strict: true do
      timer = window.setTimeout(-> {
        console.log("tick")
      }, 1000)
      window.clearTimeout(timer)
    end
  end

  class StrictNavigatorShareCode < JS::Code
    def_to_js strict: true do
      navigator.share(text: "Done", title: "Status", url: "https://example.com")
    end
  end

  class StrictReceiverlessWindowTimersCode < JS::Code
    def_to_js strict: true do
      timer = setTimeout(-> {
        console.log("tick")
      }, 1000)
      clearTimeout(timer)
    end
  end

  class StrictDocumentSelectorsCode < JS::Code
    def_to_js strict: true do
      title = document.querySelector("title")
      cards = document.querySelectorAll(".card")
      cards.forEach do |card|
        console.log(card)
      end
      console.log(title)
    end
  end

  class StrictEventTargetCode < JS::Code
    def_to_js strict: true do
      listener = ->(event) {
        console.log("event")
      }
      event = Event.new("app-ready")
      button = document.querySelector("button")
      window.addEventListener("load", listener)
      document.addEventListener("app-ready", listener, once: true)
      button.addEventListener("click", listener)
      document.removeEventListener("app-ready", listener)
      document.dispatchEvent(event)
    end
  end

  class StrictElementDOMCode < JS::Code
    def_to_js strict: true do
      container = document.querySelector("#container")
      item = document.querySelector(".item")
      container.innerHTML = "<span>Ready</span>"
      container.textContent = "Ready"
      console.log(container.innerHTML)
      console.log(container.textContent)
      container.classList.add("is-active")
      container.classList.remove("is-hidden")
      container.classList.toggle("is-open")
      container.classList.toggle("is-disabled", false)
      container.setAttribute("role", "status")
      console.log(container.getAttribute("role"))
      container.removeAttribute("hidden")
      container.appendChild(item)
      container.removeChild(item)
    end
  end

  class StrictFetchCode < JS::Code
    def_to_js strict: true do
      request = Request.new("/manifest.json", method: "GET", mode: "same-origin", credentials: "same-origin", cache: "no-store", headers: {"Accept" => "application/json"})
      response = await(fetch(request))
      content_type = response.headers.get("Content-Type")
      copy = response.clone._call
      manifest = await(response.json._call)
      body = await(response.text._call)
      all = await(Promise.all([response.json._call, copy.text._call]))
      console.log(response.ok, request.url, request.method, request.mode, request.headers, content_type, manifest, body, all)
    end
  end

  class StrictFallbackResponseCode < JS::Code
    def_to_js strict: true do
      fallback = Response.new("Offline", status: 503, headers: {"Content-Type" => "text/plain"})
      console.log(fallback)
    end
  end

  describe "strict browser context timer calls" do
    it "transpiles window.setTimeout and window.clearTimeout in strict mode" do
      expected = <<-JS.squish
      var timer;
      timer = window.setTimeout(() => {
        console.log("tick");
      }, 1000);
      window.clearTimeout(timer);
      JS

      StrictWindowTimersCode.to_js.should eq(expected)
    end
  end

  describe "strict browser context forwarded window calls" do
    it "transpiles receiverless timer calls by forwarding through window" do
      expected = <<-JS.squish
      var timer;
      timer = setTimeout(() => {
        console.log("tick");
      }, 1000);
      clearTimeout(timer);
      JS

      StrictReceiverlessWindowTimersCode.to_js.should eq(expected)
    end
  end

  describe "strict browser context navigator calls" do
    it "transpiles navigator.share with named args in strict mode" do
      expected = <<-JS.squish
      navigator.share({text: "Done", title: "Status", url: "https://example.com"});
      JS

      StrictNavigatorShareCode.to_js.should eq(expected)
    end
  end

  describe "strict browser context document selector calls" do
    it "transpiles selector assignment and NodeList iteration in strict mode" do
      expected = <<-JS.squish
      var title;
      var cards;
      title = document.querySelector("title");
      cards = document.querySelectorAll(".card");
      cards.forEach(function(card) {
        console.log(card);
      });
      console.log(title);
      JS

      StrictDocumentSelectorsCode.to_js.should eq(expected)
    end
  end

  describe "strict browser context event target calls" do
    it "transpiles Window, Document, and Element event APIs in strict mode" do
      expected = <<-JS.squish
      var listener;
      var event;
      var button;
      listener = (event) => {
        console.log("event");
      };
      event = new Event("app-ready");
      button = document.querySelector("button");
      window.addEventListener("load", listener);
      document.addEventListener("app-ready", listener, {once: true});
      button.addEventListener("click", listener);
      document.removeEventListener("app-ready", listener);
      document.dispatchEvent(event);
      JS

      StrictEventTargetCode.to_js.should eq(expected)
    end
  end

  describe "strict browser context element DOM calls" do
    it "transpiles Element DOM manipulation APIs in strict mode" do
      expected = <<-JS.squish
      var container;
      var item;
      container = document.querySelector("#container");
      item = document.querySelector(".item");
      container.innerHTML = "<span>Ready</span>";
      container.textContent = "Ready";
      console.log(container.innerHTML);
      console.log(container.textContent);
      container.classList.add("is-active");
      container.classList.remove("is-hidden");
      container.classList.toggle("is-open");
      container.classList.toggle("is-disabled", false);
      container.setAttribute("role", "status");
      console.log(container.getAttribute("role"));
      container.removeAttribute("hidden");
      container.appendChild(item);
      container.removeChild(item);
      JS

      StrictElementDOMCode.to_js.should eq(expected)
    end
  end

  describe "typed event wrappers" do
    it "exposes EventTarget calls from browser context wrappers" do
      listener = JS::Context::Undefined.new("", "handleClick")
      event = JS::Context::Event.new("click", bubbles: true, cancelable: true)

      JS::Context.default.window.addEventListener("click", listener).to_js_ref.should eq("window.addEventListener(\"click\", handleClick)")
      JS::Context.default.document.removeEventListener("click", listener, true).to_js_ref.should eq("document.removeEventListener(\"click\", handleClick, true)")
      JS::Context::Element.new("document", "querySelector", "button").dispatchEvent(event).to_js_ref.should eq("document.querySelector(\"button\").dispatchEvent(new Event(\"click\", {bubbles: true, cancelable: true}))")
    end
  end

  describe "typed element DOM wrappers" do
    it "exposes Element DOM manipulation calls" do
      element = JS::Context::Element.new("document", "querySelector", "#container")
      child = JS::Context::Element.new("document", "querySelector", ".item")

      element.innerHTML.to_js_ref.should eq("document.querySelector(\"#container\").innerHTML")
      element.textContent.to_js_ref.should eq("document.querySelector(\"#container\").textContent")
      element.classList.add("is-active").to_js_ref.should eq("document.querySelector(\"#container\").classList.add(\"is-active\")")
      element.classList.remove("is-hidden").to_js_ref.should eq("document.querySelector(\"#container\").classList.remove(\"is-hidden\")")
      element.classList.toggle("is-open").to_js_ref.should eq("document.querySelector(\"#container\").classList.toggle(\"is-open\")")
      element.classList.toggle("is-disabled", false).to_js_ref.should eq("document.querySelector(\"#container\").classList.toggle(\"is-disabled\", false)")
      element.setAttribute("role", "status").to_js_ref.should eq("document.querySelector(\"#container\").setAttribute(\"role\", \"status\")")
      element.getAttribute("role").to_js_ref.should eq("document.querySelector(\"#container\").getAttribute(\"role\")")
      element.removeAttribute("hidden").to_js_ref.should eq("document.querySelector(\"#container\").removeAttribute(\"hidden\")")
      element.appendChild(child).to_js_ref.should eq("document.querySelector(\"#container\").appendChild(document.querySelector(\".item\"))")
      element.removeChild(child).to_js_ref.should eq("document.querySelector(\"#container\").removeChild(document.querySelector(\".item\"))")
    end
  end

  describe "strict fetch APIs" do
    it "transpiles requests, response inspection, body parsing, and Promise.all" do
      expected = <<-JS.squish
      var request;
      var response;
      var content_type;
      var copy;
      var manifest;
      var body;
      var all;
      request = new Request("/manifest.json", {method: "GET", mode: "same-origin", credentials: "same-origin", cache: "no-store", headers: {Accept: "application/json"}});
      response = await fetch(request);
      content_type = response.headers.get("Content-Type");
      copy = response.clone();
      manifest = await response.json();
      body = await response.text();
      all = await Promise.all([response.json(), copy.text()]);
      console.log(response.ok, request.url, request.method, request.mode, request.headers, content_type, manifest, body, all);
      JS

      StrictFetchCode.to_js.should eq(expected)
    end

    it "transpiles fallback response options with browser-compatible keys" do
      expected = <<-JS.squish
      var fallback;
      fallback = new Response("Offline", {status: 503, headers: {"Content-Type": "text/plain"}});
      console.log(fallback);
      JS

      StrictFallbackResponseCode.to_js.should eq(expected)
    end
  end

  describe "typed HTTP wrappers" do
    it "builds constructor option objects and response calls" do
      request_options = JS::Context::RequestOptions.new(method: JS::Context::RequestMethod::Get, mode: JS::Context::RequestMode::SameOrigin, credentials: JS::Context::RequestCredentials::SameOrigin, cache: JS::Context::RequestCache::NoStore)
      response_options = JS::Context::ResponseOptions.new(status: 503, headers: {"Content-Type" => "text/plain"})
      request = JS::Context::Request.new("/page", method: JS::Context::RequestMethod::Get, credentials: JS::Context::RequestCredentials::SameOrigin, cache: JS::Context::RequestCache::NoStore)
      response = JS::Context::Response.new("Offline", status: 503, headers: {"Content-Type" => "text/plain"})

      request_options.to_js_ref.should eq(%({method: "GET", mode: "same-origin", credentials: "same-origin", cache: "no-store"}))
      response_options.to_js_ref.should eq(%({status: 503, headers: {"Content-Type": "text/plain"}}))
      JS::Context::Request.new("/page", request_options).to_js_ref.should eq(%(new Request("/page", {method: "GET", mode: "same-origin", credentials: "same-origin", cache: "no-store"})))
      JS::Context::Response.new("Offline", response_options).to_js_ref.should eq(%(new Response("Offline", {status: 503, headers: {"Content-Type": "text/plain"}})))
      request.to_js_ref.should eq(%(new Request("/page", {method: "GET", credentials: "same-origin", cache: "no-store"})))
      request.headers.get("Accept").to_js_ref.should eq(%(new Request("/page", {method: "GET", credentials: "same-origin", cache: "no-store"}).headers.get("Accept")))
      response.to_js_ref.should eq(%(new Response("Offline", {status: 503, headers: {"Content-Type": "text/plain"}})))
      response.clone.to_js_ref.should eq(%(new Response("Offline", {status: 503, headers: {"Content-Type": "text/plain"}}).clone()))
      response.json.to_js_ref.should eq(%(new Response("Offline", {status: 503, headers: {"Content-Type": "text/plain"}}).json()))
      JS::Context.default.fetch(request).to_js_ref.should eq(%(fetch(new Request("/page", {method: "GET", credentials: "same-origin", cache: "no-store"}))))
      JS::Context.default.fetch("/page").to_js_ref.should eq(%(fetch("/page")))
      JS::Context::Promise(JS::Context::Response).all([JS::Context.default.fetch("/page")]).to_js_ref.should eq(%(Promise.all([fetch("/page")])))
    end

    it "supports mutable headers" do
      headers = JS::Context::Headers.new({"Accept" => "application/json"})

      headers.to_js_ref.should eq(%(new Headers({"Accept": "application/json"})))
      headers.set("X-Test", "yes").to_js_ref.should eq(%(new Headers({"Accept": "application/json"}).set("X-Test", "yes")))
      headers.append("Vary", "Accept").to_js_ref.should eq(%(new Headers({"Accept": "application/json"}).append("Vary", "Accept")))
      headers.delete("X-Test").to_js_ref.should eq(%(new Headers({"Accept": "application/json"}).delete("X-Test")))
    end
  end
end
