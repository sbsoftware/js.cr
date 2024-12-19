require "../../spec_helper"

module JS::Class::BasicSpec
  class MyClass < JS::Class
    js_extends Controller

    js_method :do_something do
      console.log(this.element.name)
    end

    js_method :doAnotherThing do
      console.log("Wuuaaahhh!")
    end
  end

  describe "MyClass.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      class JS_Class_BasicSpec_MyClass extends Controller {
        do_something() {
          console.log(this.element.name);
        }
        doAnotherThing() {
          console.log("Wuuaaahhh!");
        }
      }
      JS

      MyClass.to_js.should eq(expected)
    end
  end
end
