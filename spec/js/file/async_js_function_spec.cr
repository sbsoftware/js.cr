require "../../spec_helper"

module JS::File::AsyncJSFunctionSpec
  class MyFile < JS::File
    async_js_function :load_data do
      console.log("loading")
    end

    def_to_js do
      load_data.to_js_call
    end
  end

  describe "MyFile.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      async function load_data() {
        console.log("loading");
      }
      load_data();
      JS

      MyFile.to_js.should eq(expected)
    end
  end
end
