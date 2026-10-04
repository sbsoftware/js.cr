require "../../spec_helper"

module JS::Code::MultiAssignmentSpec
  class MultiAssignmentCode < JS::Code
    def_to_js do
      url, response = entry
      first, second, third = values
      console.log(url, response, first, second, third)
    end
  end

  class CallbackMultiAssignmentCode < JS::Code
    def_to_js do
      entries.forEach do |entry|
        url, response = entry
        console.log(url, response)
      end
    end
  end

  class ExistingLocalMultiAssignmentCode < JS::Code
    def_to_js do
      url = "pending"
      url, response = entry
      console.log(url, response)
    end
  end

  describe "multi-assignment" do
    it "emits array destructuring and declares two and three variable bindings" do
      expected = <<-JS.squish
      var url, response;
      var first, second, third;
      [url, response] = entry;
      [first, second, third] = values;
      console.log(url, response, first, second, third);
      JS

      MultiAssignmentCode.to_js.should eq(expected)
    end

    it "declares and uses destructured variables inside a callback" do
      expected = <<-JS.squish
      entries.forEach(function(entry) {
        var url, response;
        [url, response] = entry;
        console.log(url, response);
      });
      JS

      CallbackMultiAssignmentCode.to_js.should eq(expected)
    end

    it "does not redeclare an existing implicit local" do
      expected = <<-JS.squish
      var url;
      var response;
      url = "pending";
      [url, response] = entry;
      console.log(url, response);
      JS

      ExistingLocalMultiAssignmentCode.to_js.should eq(expected)
      ExistingLocalMultiAssignmentCode.to_js.scan("var url;").size.should eq(1)
    end

    it "fails at compile-time for property targets" do
      source = <<-CR
      require "./src/js"

      class InvalidMultiAssignmentCode < JS::Code
        def_to_js do
          value, object.property = entry
        end
      end

      puts InvalidMultiAssignmentCode.to_js
      CR

      exit_code, _stdout, stderr = crystal_eval(source)
      exit_code.should_not eq(0)
      stderr.should contain("Multi-assignment only supports plain local-variable targets")
    end

    it "fails at compile-time for index targets" do
      source = <<-CR
      require "./src/js"

      class InvalidMultiAssignmentCode < JS::Code
        def_to_js do
          value, items[0] = entry
        end
      end

      puts InvalidMultiAssignmentCode.to_js
      CR

      exit_code, _stdout, stderr = crystal_eval(source)
      exit_code.should_not eq(0)
      stderr.should contain("Multi-assignment only supports plain local-variable targets")
    end
  end
end
