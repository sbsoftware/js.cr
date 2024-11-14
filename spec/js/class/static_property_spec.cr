require "../../spec_helper"

module JS::Class::StaticPropertySpec
  class MyClass < JS::Class
    static things = ["one_thing", "another_thing"]
    static dynamic_things = [JS::Class.name, JS::Code.name]
    static object_with_classes = {str: String, int: Int, obj: Object, bool: Bool, arr: Array}
  end

  describe "MyClass.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      class JS_Class_StaticPropertySpec_MyClass {
        static things = ["one_thing", "another_thing"];
        static dynamic_things = ["JS::Class", "JS::Code"];
        static object_with_classes = {str: String, int: Number, obj: Object, bool: Boolean, arr: Array};
      }
      JS

      MyClass.to_js.should eq(expected)
    end
  end
end
