require "../../spec_helper"

module JS::File::BasicSpec
  class MyFile < JS::File
    js_function :func1 do |foo|
      console.log(foo)
    end

    js_function :func2 do |bar|
      console.log(bar)
    end

    def_to_js do
      func1.to_js_call("This is")
      func2.to_js_call("Sparta")
    end
  end

  describe "MyFile.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      function func1(foo) {
        console.log(foo);
      }
      function func2(bar) {
        console.log(bar);
      }
      func1("This is");
      func2("Sparta");
      JS

      MyFile.to_js.should eq(expected)
    end
  end
end
