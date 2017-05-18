require_relative '../spec_helper'

RSpec.describe 'phabricator::mail', type: :class do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      include_context :module_precondition

      let(:facts) do
        facts
      end

      let(:params) do
        {
          domain: 'example.com',
        }
      end

      it { is_expected.to compile.with_all_deps }

      it do
        is_expected.to contain_php__extension('mailparse')
          .with_provider('pecl')
      end

      it do
        is_expected.to contain_sendmail__aliases__entry('phabricator')
          .with_ensure('present')
          .with_recipient('| /usr/local/src/phabricator/scripts/mail/mail_handler.php')
      end

      it do
        is_expected.to contain_sendmail__virtusertable__entry('phabricator')
          .with_ensure('present')
          .with_key("@#{params[:domain]}")
          .with_value('phabricator@localhost')
      end
    end
  end
end
