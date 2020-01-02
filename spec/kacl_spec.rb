require File.expand_path("../spec_helper", __FILE__)

module Danger
  describe Danger::DangerKacl do
    it "should be a plugin" do
      expect(Danger::DangerKacl.new(nil)).to be_a Danger::Plugin
    end

    #
    # You should test your custom attributes and methods here
    #
    describe "with Dangerfile" do
      before do
        @dangerfile = testing_dangerfile
        @my_plugin = @dangerfile.kacl
        @kacl = testing_dangerfile.prose

        # mock the PR data
        # you can then use this, eg. github.pr_author, later in the spec
        # json = File.read(File.dirname(__FILE__) + '/support/fixtures/github_pr.json') # example json: `curl https://api.github.com/repos/danger/danger-plugin-template/pulls/18 > github_pr.json`
        # allow(@my_plugin.github).to receive(:pr_json).and_return(json)
      end

      describe 'kacl-cli' do
        it 'handles kacl-cli not being installed' do
          allow(@kacl).to receive(:`).with('which kacl-cli').and_return('')
          expect(@kacl.kacl_cli_installed?).to be_falsy
        end
      end
    end
  end
end
