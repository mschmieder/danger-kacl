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

    # report file attribute
    # @return [void]
    attr_accessor :report_file

    # report file attribute
    # @return [void]
    attr_accessor :changelog_file

    # Checks wether the kacl-cli was installed
    #
    # @return [boolean] true if installed, false if not
    def kacl_cli_installed?
      `which kacl-cli`.strip.empty? == false
    end

    # Convenient method to retrieve the report file name
    # @return [void]
    def report
      @report_file || "kacl_report.json"
    end

    # Convenient method to retrieve the changelog filename
    # @return [void]
    def changelog
      @changelog_file || nil
    end

    # Actual danger function that check for validation issues
    # @return [void]
    def validate
      # Installs a kacl-cli checker if needed
      system "pip3 install --user python-kacl" unless kacl_cli_installed?

      # Check that this is in the user's PATH after installing
      raise "kacl-cli is not in the user's PATH, or it failed to install" unless kacl_cli_installed?

      if changelog.nil?
        system "kacl-cli verify --json > #{report}"
      else
        system "kacl-cli -f #{changelog} verify --json > #{report}"
      end
      valid = kacl_report["valid"]
      if valid
        message  "Changelog validity is '#{valid}'"
      else
        errors = kacl_report["errors"]

        errors.each do |e|
          start_char_pos = 0
          if e.key?("start_char_pos") && !e["start_char_pos"].nil?
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
    def parse_report
      raise ERROR_FILE_NOT_SET if report.nil? || report.empty?
      raise format(ERROR_FILE_NOT_FOUND, report) unless File.exist?(report)

      file = File.read(report)
      JSON.parse(file)
    end

    # Convenient method to not always parse the task file but keep it in the memory.
    #
    # @return [Hash] The report object.
    def kacl_report
      @kacl_report ||= parse_report
    end
  end
end
