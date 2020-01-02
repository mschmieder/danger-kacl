require 'fileutils'
require 'json'

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
  # @see  Matthias Schmieder/danger-kacl
  # @tags monday, weekends, time, rattata
  #
  class DangerKacl < Plugin
    ERROR_FILE_NOT_SET = "kacl report file not set. Use 'kacl_changelog.report = \"kacl_report.json\"'.".freeze
    ERROR_FILE_NOT_FOUND = "No file found at %s".freeze

    attr_accessor :kacl_report_file

    def kacl_cli_installed?
      `which kacl-cli`.strip.empty? == false
    end

    def kacl_report_file
      @kacl_report_file || "kacl_report.json"
    end


    def is_valid
      valid = kacl_report['valid']
      if valid
        message  "Changelog validity is '%s'" % [valid]
      else
        errors = kacl_report['errors']

        for e in errors do
          start_char_pos = 0
          if e.key?("start_char_pos") and e['start_char_pos'] != nil
            start_char_pos = e['start_char_pos']
          end
          fail "CHANGELOG:#{e['line_number']}:#{start_char_pos} error: #{e['error_message']}"
        end
      end

    end

    private

    # Convenient method to not always parse the task file but keep it in the memory.
    #
    # @return [IniFile::Hash] The task report object.
    def parse_kacl_report_file
      raise ERROR_FILE_NOT_SET if kacl_report_file.nil? || kacl_report_file.empty?
      raise format(ERROR_FILE_NOT_FOUND, kacl_report_file) unless File.exist?(kacl_report_file)

      file = File.read(kacl_report_file)
      JSON.parse(file)
    end

    # Convenient method to not always parse the task file but keep it in the memory.
    #
    # @return [IniFile::Hash] The task report object.
    def kacl_report
      @kacl_report ||= parse_kacl_report_file
    end
  end
end
