require "spec"
require "../src/js"

class String
  def squish
    split(/\n\s*/).join
  end
end

def crystal_eval(source : String)
  stdout = IO::Memory.new
  stderr = IO::Memory.new
  status = Process.run(
    "crystal",
    ["eval", source],
    chdir: File.expand_path("..", __DIR__),
    env: {"CRYSTAL_CACHE_DIR" => "/tmp/.crystal-cache-js"},
    output: stdout,
    error: stderr
  )

  {status.exit_code, stdout.to_s, stderr.to_s}
end
