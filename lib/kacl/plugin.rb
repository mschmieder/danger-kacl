# frozen_string_literal: true

require "fileutils"
require "json"

module Danger
  # This is your plugin class. Any attributes or methods you expose here will
  # be available from within your Dangerfile.
  #
  # To be published on the Danger plugins site, you will need to have
  # the public interface documented. Danger uses [YARD](http://yardoc.org/)
  # for generating documentation from your plugin source, and you can verify
  # by running `danger plugins lint` or `bundle exec rake spec`.
  #
  # You should replace these comments with a public description of your library.
  #
  # @example Ensure people are well warned about merging on Mondays
  #
  #          my_plugin.warn_on_mondays
  #
  # @see  mschmieder/danger-kacl
  # @tags monday, weekends, time, rattata
  #
  class DangerKacl < Plugin
    ERROR_FILE_NOT_SET = "kacl report file not set. Use 'kacl_changelog.report = \"kacl_report.json\"'."
    ERROR_FILE_NOT_FOUND = "No file found at %s"

    attr_accessor :report_file
    attr_accessor :changelog_file

    def kacl_cli_installed?
      `which kacl-cli`.strip.empty? == false
    end

    def report_file
      @report_file || "kacl_report.json"
    end

    def changelog_file
      @changelog_file || nil
    end

    def validate
      # Installs a prose checker if needed
      system "pip3 install --user python-kacl" unless kacl_cli_installed?

      # Check that this is in the user's PATH after installing
      raise "kacl-cli is not in the user's PATH, or it failed to install" unless kacl_cli_installed?

      if changelog_file.should.nil?
        system "kacl-cli verify --json > #{report_file}"
      else
        system "kacl-cli -f #{changelog_file} verify --json > #{report_file}"
      end
      valid = kacl_report["valid"]
      if valid
        message  "Changelog validity is '#{valid}'"
      else
        errors = kacl_report["errors"]

        errors.each do |e|
          start_char_pos = 0
          if e.key?("start_char_pos") && e["start_char_pos"] != nil
            start_char_pos = e["start_char_pos"]
          end
          fail "CHANGELOG:#{e['line_number']}:#{start_char_pos} error: #{e['error_message']}"
        end
      end
    end

    private

    # Convenient method to not always parse the task file but keep it in the memory.
    #
    # @return [IniFile::Hash] The task report object.
    def parse_report_file
      raise ERROR_FILE_NOT_SET if report_file.nil? || report_file.empty?
      raise format(ERROR_FILE_NOT_FOUND, report_file) unless File.exist?(report_file)

      file = File.read(report_file)
      JSON.parse(file)
    end

    # Convenient method to not always parse the task file but keep it in the memory.
    #
    # @return [IniFile::Hash] The task report object.
    def kacl_report
      @kacl_report ||= parse_report_file
    end
  end
end
