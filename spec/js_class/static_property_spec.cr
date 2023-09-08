require "../spec_helper"

module JsClass::StaticPropertySpec
  class MyClass < JsClass
    static things = ["one_thing", "another_thing"]
  end

  describe "MyClass.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      class MyClass {
        static things = ["one_thing", "another_thing"];
      }
      JS

      MyClass.to_js.should eq(expected)
    end
  end
end
