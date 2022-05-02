# frozen_string_literal: true

RSpec.describe IssueScheduler::Config do
  let(:config_file) { File.expand_path('~/.issue_scheduler.yaml') }

  describe '.new' do
    subject { described_class.new }
    context 'with a valid config file that specifies all values' do
      let(:config) do
        {
          'username' => 'test_user',
          'password' => 'test_password',
          'site' => 'test_site',
          'context_path' => 'test_context_path',
          'auth_type' => 'test_auth_type',
          'issue_files' => 'test_issue_files'
        }
      end
      before do
        allow(YAML).to receive(:load_file).with(config_file).and_return(config)
      end
      it { is_expected.to have_attributes(config) }
    end

    context 'when the config file does not exist' do
      before do
        allow(YAML).to receive(:load_file).with(config_file).and_raise(Errno::ENOENT)
      end
      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /does not exist/i)
      end
    end

    context 'with an empty config file' do
      let(:config) { {} }
      before do
        allow(YAML).to receive(:load_file).with(config_file).and_return(config)
      end
      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /missing configuration values/i)
      end
    end

    context 'with an invalid YAML in the config file' do
      before do
        allow(YAML).to(
          receive(:load_file)
            .with(config_file)
            .and_raise(Psych::SyntaxError.new(config_file, 1, 1, 1, 'Syntax Error', nil))
        )
      end

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /error parsing yaml/i)
      end
    end

    context 'when the config file contains something other than an object' do
      let(:config) { 'bogus string value' }
      before do
        allow(YAML).to receive(:load_file).with(config_file).and_return(config)
      end

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /is not an object/i)
      end
    end

    context 'when the config file contains unexpected keys' do
      let(:config) { { 'password_key' => 'password' } }
      before do
        allow(YAML).to receive(:load_file).with(config_file).and_return(config)
      end

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /unexpected configuration keys/i)
      end
    end
  end
end
