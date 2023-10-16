require "../../spec_helper"

module JS::File::ClassInstantiationSpec
  class MyFile < JS::File
    js_class SomeClass do
      js_method :constructor do |foo, bar|
        this.foo = foo
        this.bar = bar
      end

      js_method :do_something do
        console.log(this.foo)
      end
    end

    def_to_js do
      my_bar = "goo"
      my_class = SomeClass.new("blah", my_bar)
      my_class.do_something
    end
  end

  describe "MyFile.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      class SomeClass {
        constructor(foo, bar) {
          this.foo = foo;
          this.bar = bar;
        }

        do_something() {
          console.log(this.foo);
        }
      }

      var my_bar = "goo";
      var my_class = new SomeClass("blah", my_bar);
      my_class.do_something();
      JS

      MyFile.to_js.should eq(expected)
    end
  end
end
