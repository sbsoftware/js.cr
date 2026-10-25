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

  class StrictServiceWorkerCode < JS::Code
    def_to_js strict: true do
      container = navigator.serviceWorker
      if container
        registration = await(container.ready)
        worker = registration.active || registration.waiting || registration.installing
        worker.postMessage({type: "refresh", manifest: "/manifest.json"}) if worker
        container.register("/service-worker.js", scope: "/wordgame/", type: "module", updateViaCache: "none")
        console.log(container.controller) if container.controller
      end
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

    it "transpiles service worker feature detection, selection, registration, and posting" do
      expected = <<-JS.squish
      var container;
      container = navigator.serviceWorker;
      if (container) {
        registration = await container.ready;
        worker = (registration.active || registration.waiting) || registration.installing;
        if (worker) {
          worker.postMessage({type: "refresh", manifest: "/manifest.json"});
        }
        container.register("/service-worker.js", {scope: "/wordgame/", type: "module", updateViaCache: "none"});
        if (container.controller) {
          console.log(container.controller);
        }
      }
      JS

      StrictServiceWorkerCode.to_js.should eq(expected)
    end
  end

  describe "typed service worker wrappers" do
    it "exposes promise, registration state, controller, and message references" do
      container = JS::Context.default.navigator.serviceWorker.not_nil!
      registration = JS::Context::ServiceWorkerRegistration.new("registration")
      worker = registration.active || registration.waiting || registration.installing

      container.ready.to_js_ref.should eq("navigator.serviceWorker.ready")
      container.register("/service-worker.js").to_js_ref.should eq(%(navigator.serviceWorker.register("/service-worker.js")))
      container.register("/service-worker.js", scope: "/app/").to_js_ref.should eq(%(navigator.serviceWorker.register("/service-worker.js", {scope: "/app/"})))
      container.controller.not_nil!.to_js_ref.should eq("navigator.serviceWorker.controller")
      registration.waiting.not_nil!.to_js_ref.should eq("registration.waiting")
      registration.installing.not_nil!.to_js_ref.should eq("registration.installing")
      worker.postMessage({type: "refresh", manifest: "/manifest.json"}).to_js_ref.should eq(%(registration.active.postMessage({type: "refresh", manifest: "/manifest.json"}))) if worker
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
end
