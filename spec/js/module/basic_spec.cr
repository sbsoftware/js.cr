require "../../spec_helper"

module JS::Module::BasicSpec
  class MyModule < JS::Module
    js_function :module_func1 do |foo|
      console.log(foo)
    end

    js_function :module_func2 do |bar|
      console.log(bar)
    end

    js_function otherFunc do |a|
      console.log(a)
    end

    def_to_js do
      module_func1.to_js_call("heck")
      module_func2.to_js_call("this works")
      otherFunc.to_js_call("a")
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
      function otherFunc(a) {
        console.log(a);
      }
      module_func1("heck");
      module_func2("this works");
      otherFunc("a");
      JS

      MyModule.to_js.should eq(expected)
    end
  end
end
