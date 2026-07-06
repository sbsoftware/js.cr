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

  describe "typed event wrappers" do
    it "exposes EventTarget calls from browser context wrappers" do
      listener = JS::Context::Undefined.new("", "handleClick")
      event = JS::Context::Event.new("click", bubbles: true, cancelable: true)

      JS::Context.default.window.addEventListener("click", listener).to_js_ref.should eq("window.addEventListener(\"click\", handleClick)")
      JS::Context.default.document.removeEventListener("click", listener, true).to_js_ref.should eq("document.removeEventListener(\"click\", handleClick, true)")
      JS::Context::Element.new("document", "querySelector", "button").dispatchEvent(event).to_js_ref.should eq("document.querySelector(\"button\").dispatchEvent(new Event(\"click\", {bubbles: true, cancelable: true}))")
    end
  end
end
