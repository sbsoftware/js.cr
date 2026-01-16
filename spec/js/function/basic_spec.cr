require "../../spec_helper"

module JS::Function::BasicSpec
  class DemoJsClass < JS::Class
  end

  class ExplicitClass
    def self.to_js_ref
      "ExplicitClass"
    end
  end

  class FunctionCode < JS::Function
    def_to_js :my_func do |foo, bar|
      console.log(foo)
      OtherFunction.to_js_call("bla")
      console.log(bar)
    end
  end

  class OtherFunction < JS::Function
    def_to_js do |meh|
      console.log(meh)
    end
  end

  class CustomRef
    def to_js_ref
      "custom_ref()"
    end
  end

  describe "FunctionCode.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      function my_func(foo, bar) {
        console.log(foo);
        other_function("bla");
        console.log(bar);
      }
      JS

      FunctionCode.to_js.should eq(expected)
    end
  end

  describe "FunctionCode.to_js_call" do
    it "should copy literal strings to the JS context" do
      expected = <<-JS
      my_func("blah", "maah")
      JS

      FunctionCode.to_js_call("blah", "maah").should eq(expected)
    end

    it "should copy Integers to the JS context" do
      expected = <<-JS
      my_func(2, 3)
      JS

      FunctionCode.to_js_call(2, 3).should eq(expected)
    end

    it "should use to_js_ref for non-string values" do
      expected = <<-JS
      my_func(custom_ref(), 2)
      JS

      FunctionCode.to_js_call(CustomRef.new, 2).should eq(expected)
    end

    it "should map nil to undefined" do
      expected = <<-JS
      my_func(undefined, "maah")
      JS

      FunctionCode.to_js_call(nil, "maah").should eq(expected)
    end

    it "should copy Bool values to the JS context" do
      expected = <<-JS
      my_func(true, false)
      JS

      FunctionCode.to_js_call(true, false).should eq(expected)
    end

    it "should copy Float values to the JS context" do
      expected = <<-JS
      my_func(1.5, 2.75)
      JS

      FunctionCode.to_js_call(1.5, 2.75).should eq(expected)
    end

    it "should copy Arrays to the JS context" do
      expected = <<-JS
      my_func([1, "two"], ["a", 3])
      JS

      FunctionCode.to_js_call([1, "two"], ["a", 3]).should eq(expected)
    end

    it "should copy NamedTuples to the JS context" do
      expected = <<-JS
      my_func({foo: "bar", count: 2}, {flag: false})
      JS

      FunctionCode.to_js_call({foo: "bar", count: 2}, {flag: false}).should eq(expected)
    end

    it "should copy class references to the JS context" do
      expected = <<-JS
      my_func(ExplicitClass, JS_Function_BasicSpec_DemoJsClass)
      JS

      FunctionCode.to_js_call(ExplicitClass, DemoJsClass).should eq(expected)
    end
  end
end
