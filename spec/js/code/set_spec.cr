require "../../spec_helper"

module JS::Code::SetSpec
  class StrictEmptySetCode < JS::Code
    def_to_js strict: true do
      urls = Set.new
      console.log(urls.size)
    end
  end

  class StrictSetWorkflowCode < JS::Code
    def_to_js strict: true do
      initial_urls = ["/one", "/one", "/two"]
      urls = Set.new(initial_urls)
      urls.add("/three")
      present = urls.has("/two")
      urls.delete("/one")
      array = Array.from(urls)
      values = urls.values._call
      urls.forEach do |url|
        console.log(url)
      end
      urls.clear._call
      console.log(present, array, values, urls.size)
    end
  end

  describe "typed Set support" do
    it "constructs an empty native Set in strict mode" do
      expected = <<-JS.squish
      var urls;
      urls = new Set();
      console.log(urls.size);
      JS

      StrictEmptySetCode.to_js.should eq(expected)
    end

    it "transpiles de-duplication, membership, iteration, and array conversion" do
      expected = <<-JS.squish
      var initial_urls;
      var urls;
      var present;
      var array;
      var values;
      initial_urls = ["/one", "/one", "/two"];
      urls = new Set(initial_urls);
      urls.add("/three");
      present = urls.has("/two");
      urls.delete("/one");
      array = Array.from(urls);
      values = urls.values();
      urls.forEach(function(url) {
        console.log(url);
      });
      urls.clear();
      console.log(present, array, values, urls.size);
      JS

      StrictSetWorkflowCode.to_js.should eq(expected)
    end

    it "serializes the constructible wrapper as the native identifier" do
      Set(Int32).to_js_ref.should eq("Set")
    end
  end
end
