require "../../spec_helper"

module JS::Function::BasicSpec
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
  end
end
