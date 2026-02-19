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

  describe "typed document selector return values" do
    it "models querySelector as optional Element and querySelectorAll as NodeList" do
      document = JS::Context.default.document
      title = document.querySelector(".card-title")
      cards = document.querySelectorAll(".card")
      title.should be_a(JS::Context::Element)
      title.not_nil!.to_js_ref.should eq("document.querySelector(\".card-title\")")
      cards.should be_a(JS::Context::NodeList)
      cards.to_js_ref.should eq("document.querySelectorAll(\".card\")")

      for_each_result = cards.forEach("processCard")
      for_each_result.should be_a(JS::Context::Undefined)
      for_each_result.to_js_ref.should eq("document.querySelectorAll(\".card\").forEach(\"processCard\")")

      optional_type_source = <<-CR
      require "./src/js"

      title : JS::Context::Element = JS::Context.default.document.querySelector(".card-title")
      puts title.to_js_ref
      CR
      optional_exit_code, _optional_stdout, optional_stderr = crystal_eval(optional_type_source)
      optional_exit_code.should_not eq(0)
      optional_stderr.should contain("JS::Context::Element | Nil")

      array_type_source = <<-CR
      require "./src/js"

      cards : Array(JS::Context::Element) = JS::Context.default.document.querySelectorAll(".card")
      puts cards.size
      CR
      array_exit_code, _array_stdout, array_stderr = crystal_eval(array_type_source)
      array_exit_code.should_not eq(0)
      array_stderr.should contain("JS::Context::NodeList")
    end
  end
end
