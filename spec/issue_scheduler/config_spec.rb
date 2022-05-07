# frozen_string_literal: true

RSpec.describe IssueScheduler::Config do
  let(:config_yaml) { <<~YAML }
    username: test_user
    password: test_password
    site: test_site
    context_path: test_context_path
    auth_type: test_auth_type
    issue_templates: test_issue_templates
  YAML

  let(:expected_config) do
    {
      username: 'test_user',
      password: 'test_password',
      site: 'test_site',
      context_path: 'test_context_path',
      auth_type: 'test_auth_type',
      issue_templates: 'test_issue_templates'
    }
  end

  describe '#to_h' do
    subject { described_class.new(config_yaml).to_h }
    context 'with a valid config that specifies all values' do
      it { is_expected.to eq(expected_config) }
    end
  end

  describe '#to_jira_options' do
    subject { described_class.new(config_yaml).to_jira_options }
    let(:expected_jira_options) do
      {
        username: 'test_user',
        password: 'test_password',
        site: 'test_site',
        context_path: 'test_context_path',
        auth_type: 'test_auth_type'
      }
    end

    it { is_expected.to eq(expected_jira_options) }
  end

  describe '.new' do
    subject { described_class.new(config_yaml) }
    context 'with a valid config that specifies all values' do
      it { is_expected.to have_attributes(expected_config) }
    end

    context 'with an empty config' do
      let(:config_yaml) { '' }
      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /is not an object/i)
      end
    end

    context 'with an invalid YAML in the config' do
      let(:config_yaml) { ':' }

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /error parsing yaml/i)
      end
    end

    context 'when the config contains something other than an object' do
      let(:config_yaml) { 'bogus string value' }

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /is not an object/i)
      end
    end

    context 'when the config contains unexpected keys' do
      let(:config_yaml) { <<~YAML }
        password_key: 'password'
      YAML

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /unexpected configuration keys/i)
      end
    end

    context 'when the config is missing required values' do
      let(:config_yaml) { <<~YAML }
        username: user
        password: pass
      YAML

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /missing configuration values/i)
      end
    end
  end
end
