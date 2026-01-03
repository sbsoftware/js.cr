require "../../spec_helper"

module JS::Code::AsyncAwaitSpec
  class AsyncFunctionCode < JS::Code
    def_to_js do
      handler = async do |event|
        console.log(event)
      end
    end
  end

  class AwaitCode < JS::Code
    def_to_js do
      response = await(fetch("/data"))
    end
  end

  describe "AsyncFunctionCode.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      var handler;
      handler = async function(event) {
        console.log(event);
      };
      JS

      AsyncFunctionCode.to_js.should eq(expected)
    end
  end

  describe "AwaitCode.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      var response;
      response = await fetch("/data");
      JS

      AwaitCode.to_js.should eq(expected)
    end
  end
end
