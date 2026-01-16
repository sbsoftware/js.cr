require "../../spec_helper"

module JS::Code::NativeToJsRefSpec
  class DemoJsClass < JS::Class
  end

  class ExplicitClass
    def self.to_js_ref
      "ExplicitClass"
    end
  end

  class MyCode < JS::Code
    STR_VALUE   = "hello"
    INT_VALUE   = 12
    BOOL_VALUE  = true
    FLOAT_VALUE = 1.5
    ARRAY_VALUE = [1, "two", false]
    TUPLE_VALUE = {foo: "bar", count: 2, flag: true}

    def_to_js do
      console.log(STR_VALUE)
      console.log(INT_VALUE)
      console.log(BOOL_VALUE)
      console.log(FLOAT_VALUE)
      console.log(ARRAY_VALUE)
      console.log(TUPLE_VALUE)
      console.log("direct")
      console.log(99)
      console.log(false)
      console.log(2.25)
      console.log([1, "two"])
      console.log({foo: "bar", count: 3})
      console.log(ExplicitClass)
      console.log(DemoJsClass)
    end
  end

  describe "MyCode.to_js" do
    it "should use to_js_ref for native calls" do
      expected = <<-JS.squish
      console.log("hello");
      console.log(12);
      console.log(true);
      console.log(1.5);
      console.log([1, "two", false]);
      console.log({foo: "bar", count: 2, flag: true});
      console.log("direct");
      console.log(99);
      console.log(false);
      console.log(2.25);
      console.log([1, "two"]);
      console.log({foo: "bar", count: 3});
      console.log(ExplicitClass);
      console.log(JS_Code_NativeToJsRefSpec_DemoJsClass);
      JS

      MyCode.to_js.should eq(expected)
    end
  end
end
