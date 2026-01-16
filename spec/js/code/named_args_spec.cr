require "../../spec_helper"

module JS::Code::NamedArgsSpec
  class ShareCode < JS::Code
    def_to_js do
      navigator.share(text: "Test!")
    end
  end

  class MixedArgsCode < JS::Code
    def_to_js do
      api.send("ping", timeout: 5, retries: 2)
    end
  end

  class BlockArgsCode < JS::Code
    def_to_js do
      api.send("ping", timeout: 5) do |resp|
        return resp
      end
    end
  end

  describe "ShareCode.to_js" do
    it "transpiles named args to an object literal" do
      expected = <<-JS.squish
      navigator.share({text: "Test!"});
      JS

      ShareCode.to_js.should eq(expected)
    end
  end

  describe "MixedArgsCode.to_js" do
    it "appends named args as an object literal" do
      expected = <<-JS.squish
      api.send("ping", {timeout: 5, retries: 2});
      JS

      MixedArgsCode.to_js.should eq(expected)
    end
  end

  describe "BlockArgsCode.to_js" do
    it "places named args before the block callback" do
      expected = <<-JS.squish
      api.send("ping", {timeout: 5}, function(resp) {
        return resp;
      });
      JS

      BlockArgsCode.to_js.should eq(expected)
    end
  end
end
