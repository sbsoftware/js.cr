require "../../spec_helper"

module JS::Code::ExceptionHandlingSpec
  class ExceptionCode < JS::Code
    def_to_js do
      begin
        manifest = await(response.json._call)
      rescue error
        message = error.message
        manifest = nil
      ensure
        cleanup._call
      end

      raise Error.new("Unable to cache page")
    end
  end

  class NestedAsyncCode < JS::Code
    def_to_js do
      handler = async do
        begin
          payload = await(response.json._call)
        rescue error
          console.log(error)
        end
      end
    end
  end

  class AsyncFile < JS::File
    async_js_function :load_data do
      begin
        data = await(response.json._call)
      rescue error
        raise error
      end
    end
  end

  describe "exception handling" do
    it "emits catch, finally, and throw statements with branch-local declarations" do
      expected = <<-JS.squish
      try {
        var manifest;
        manifest = await response.json();
      } catch (error) {
        var message;
        var manifest;
        message = error.message;
        manifest = undefined;
      } finally {
        cleanup();
      }
      throw new Error("Unable to cache page");
      JS

      ExceptionCode.to_js.should eq(expected)
    end

    it "works inside anonymous async functions" do
      expected = <<-JS.squish
      var handler;
      handler = async function() {
        try {
          var payload;
          payload = await response.json();
        } catch (error) {
          console.log(error);
        }
      };
      JS

      NestedAsyncCode.to_js.should eq(expected)
    end

    it "works inside async_js_function bodies" do
      expected = <<-JS.squish
      async function load_data() {
        try {
          var data;
          data = await response.json();
        } catch (error) {
          throw error;
        }
      }
      JS

      AsyncFile.load_data.to_js.should eq(expected)
    end

    {
      {"rescue error : Exception\n  console.log(error)", "does not support typed rescues"},
      {"rescue first : Exception\n  console.log(first)\nrescue second\n  console.log(second)", "at most one `rescue` clause"},
      {"rescue error\n  console.log(error)\nelse\n  console.log(\"ok\")", "does not support `else`"},
    }.each do |invalid_body, message|
      it "rejects #{message}" do
        source = <<-CR
        require "./src/js"

        class InvalidExceptionCode < JS::Code
          def_to_js do
            begin
              work._call
            #{invalid_body}
            end
          end
        end

        puts InvalidExceptionCode.to_js
        CR

        exit_code, _stdout, stderr = crystal_eval(source)
        exit_code.should_not eq(0)
        stderr.should contain(message)
      end
    end

    it "rejects bare raise" do
      source = <<-CR
      require "./src/js"

      class InvalidRaiseCode < JS::Code
        def_to_js do
          raise
        end
      end

      puts InvalidRaiseCode.to_js
      CR

      exit_code, _stdout, stderr = crystal_eval(source)
      exit_code.should_not eq(0)
      stderr.should contain("bare re-raise is not supported")
    end
  end
end
