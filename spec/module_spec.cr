require "./spec_helper"

module Js::ModuleSpec
  class MyModule < JsModule
    function :module_func1 do |foo|
      console.log(foo)
    end

    function :module_func2 do |bar|
      console.log(bar)
    end

    def_to_js do
      module_func1.to_js_call("heck")
      module_func2.to_js_call("this works")
    end
  end

  describe "MyModule.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      function module_func1(foo) {
        console.log(foo);
      }
      function module_func2(bar) {
        console.log(bar);
      }
      module_func1("heck");
      module_func2("this works");
      JS

      MyModule.to_js.should eq(expected)
    end
  end
end
