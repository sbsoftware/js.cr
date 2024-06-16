require "../../spec_helper"

module JS::Class::VariableAssignmentSpec
  class MyClass < JS::Class
    js_method :do_it do
      my_var = this.element
    end
  end

  describe "MyClass.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      class JS_Class_VariableAssignmentSpec_MyClass {
        do_it() {
          var my_var;
          my_var = this.element;
        }
      }
      JS

      MyClass.to_js.should eq(expected)
    end
  end
end
