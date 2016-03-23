require 'open3'
require 'tempfile'

module Elm
  class Compiler
    def self.compile(pathname, cwd: nil)
      temp_file = Tempfile.new ['compiled_elm_output', '.js']
      @cmd ||= (`npm bin`).strip + "/elm-make"

      begin
        # need to specify LANG or else build will fail on jenkins
        # with error "elm-make: elm-stuff/build-artifacts/NoRedInk/NoRedInk/1.0.0/Quiz-QuestionStore.elmo: hGetContents: invalid argument (invalid byte sequence)"
        options = {}
        options[:chdir] = cwd if cwd
        Open3.popen3({'LANG' => 'en_US.UTF-8'}, @cmd, pathname.to_s, "--yes", "--output", temp_file.path, options) do |_stdin, stdout, stderr, wait_thr|
          compiler_output = stdout.gets(nil)
          stdout.close

          compiler_err = stderr.gets(nil)
          stderr.close

          process_status = wait_thr.value

          if process_status.exitstatus != 0
            raise compiler_err
          end
        end

        temp_file.read
      ensure
        temp_file.unlink
      end
    end
  end
end
