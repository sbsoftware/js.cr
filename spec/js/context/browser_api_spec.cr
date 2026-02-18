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

  describe "typed window timer wrappers" do
    it "returns a timer handle and accepts it in clearTimeout" do
      timer = JS::Context.default.window.setTimeout("tick", 1000)
      clear_result = JS::Context.default.window.clearTimeout(timer)
      forwarded_timer = JS::Context.default.setTimeout("tick", 1000)

      timer.should be_a(JS::Context::TimerHandle)
      timer.to_js_ref.should eq("window.setTimeout(\"tick\", 1000)")
      clear_result.to_js_ref.should eq("window.clearTimeout(window.setTimeout(\"tick\", 1000))")
      forwarded_timer.should be_a(JS::Context::TimerHandle)
      forwarded_timer.to_js_ref.should eq("window.setTimeout(\"tick\", 1000)")
    end
  end

  describe "typed navigator share wrapper" do
    it "builds a JS share call with required text and optional metadata" do
      result = JS::Context.default.navigator.share(text: "Done", title: "Status")

      result.should be_a(JS::Context::Undefined)
      result.to_js_ref.should eq("navigator.share({text: \"Done\", title: \"Status\"})")
    end
  end

  describe "call-chain serialization" do
    it "serializes named tuple args as JS object literals" do
      share_call = JS::Context.build_call_chain("navigator", "share", {text: "Done", url: "https://example.com"})

      share_call.should eq("navigator.share({text: \"Done\", url: \"https://example.com\"})")
    end
  end
end
