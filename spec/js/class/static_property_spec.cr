require "../../spec_helper"

module JS::Class::StaticPropertySpec
  class MyClass < JS::Class
    static things = ["one_thing", "another_thing"]
    static dynamic_things = [JS::Class.name, JS::Code.name]
  end

  describe "MyClass.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      class JS_Class_StaticPropertySpec_MyClass {
        static things = ["one_thing", "another_thing"];
        static dynamic_things = ["JS::Class", "JS::Code"];
      }
      JS

      MyClass.to_js.should eq(expected)
    end
  end
end
