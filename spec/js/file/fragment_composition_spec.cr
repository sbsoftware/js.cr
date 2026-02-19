require "../../spec_helper"

module JS::File::FragmentCompositionSpec
  class MultiFragmentFile < JS::File
    js_fragment do
      console.log("first fragment")
    end

    js_fragment do
      console.log("second fragment")
    end
  end

  class ReopenedFragmentFile < JS::File
    js_fragment do
      console.log("scope-a")
    end
  end

  class ReopenedFragmentFile
    js_fragment do
      console.log("scope-b")
    end
  end

  class FunctionAndFragmentFile < JS::File
    js_function :log_scope do |scope|
      console.log(scope)
    end

    js_fragment do
      log_scope("scope-a")
    end

    def_to_js do
      log_scope("scope-b")
    end
  end

  describe "fragment composition in JS::File" do
    it "emits multiple fragments in deterministic declaration order" do
      expected = <<-JS.squish
      console.log("first fragment");
      console.log("second fragment");
      JS

      MultiFragmentFile.to_js.should eq(expected)
    end

    it "supports reopen-style fragment contributions from different call sites" do
      expected = <<-JS.squish
      console.log("scope-a");
      console.log("scope-b");
      JS

      ReopenedFragmentFile.to_js.should eq(expected)
    end

    it "keeps js_function and def_to_js compatible with fragment composition" do
      expected = <<-JS.squish
      function log_scope(scope) {
        console.log(scope);
      }
      log_scope("scope-a");
      log_scope("scope-b");
      JS

      FunctionAndFragmentFile.to_js.should eq(expected)
    end
  end
end
