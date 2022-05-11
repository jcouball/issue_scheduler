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

  let(:config_hash) { IssueScheduler.parse_yaml(config_yaml) }

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
    subject { described_class.new(config_hash).to_h }
    context 'with a valid config that specifies all values' do
      it { is_expected.to eq(expected_config) }
    end
  end

  describe '#to_jira_options' do
    subject { described_class.new(config_hash).to_jira_options }
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
    subject { described_class.new(config_hash) }

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
        expect { subject }.to raise_error(RuntimeError, /\AYAML is not valid/i)
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

  describe '#load_issue_templates' do
    let(:config) { described_class.new(config_hash) }

    let(:config_yaml) { <<~YAML }
      username: user
      password: pass
      site: https://jira.org
      auth_type: basic
      issue_templates: config/issue_templates/**/*.yaml
    YAML

    let(:template1_yaml) { <<~YAML }
      cron: 0 0 * * * America/Los_Angeles
      project: 'MYPROJECT'
      summary: 'Take out the trash'
    YAML

    let(:template2_yaml) { <<~YAML }
      cron: 0 0 * * * America/Los_Angeles
      project: 'ANOTHER PROJECT'
      summary: 'Wash the dog'
    YAML

    let(:config_hash) { IssueScheduler.parse_yaml(config_yaml) }

    before do
      @dir = Dir.mktmpdir
      @saved_dir = Dir.pwd
      Dir.chdir @dir
    end

    after do
      Dir.chdir @saved_dir if @saved_dir
      FileUtils.rm_rf(@dir) if Dir.exist?(@dir)
    end

    let(:dir) { @dir }

    context 'with no templates' do
      before do
        IssueScheduler::IssueTemplate.delete_all

        FileUtils.mkdir_p(File.join(dir, 'config', 'issue_templates'))
        File.write(File.join(dir, 'config', 'config.yaml'), config_yaml)
      end

      it 'should not load any templates' do
        config.load_issue_templates

        expect(IssueScheduler::IssueTemplate.size).to eq(0)
      end
    end

    context 'with one valid template' do
      before do
        IssueScheduler::IssueTemplate.delete_all

        FileUtils.mkdir_p(File.join(dir, 'config', 'issue_templates'))
        File.write(File.join(dir, 'config', 'config.yaml'), config_yaml)
        File.write(File.join(dir, 'config', 'issue_templates', 'template1.yaml'), template1_yaml)
      end

      it 'should load the template' do
        config.load_issue_templates

        expect(IssueScheduler::IssueTemplate.size).to eq(1)
        expect(IssueScheduler::IssueTemplate.all.map(&:summary)).to eq(['Take out the trash'])
      end

      it 'should set the name of the template to the filename' do
        config.load_issue_templates

        expect(IssueScheduler::IssueTemplate.all.first.name).to(
          eq('config/issue_templates/template1.yaml')
        )
      end
    end

    context 'with two valid templates' do
      before do
        IssueScheduler::IssueTemplate.delete_all

        FileUtils.mkdir_p(File.join(dir, 'config', 'issue_templates'))
        File.write(File.join(dir, 'config', 'config.yaml'), config_yaml)
        File.write(File.join(dir, 'config', 'issue_templates', 'template1.yaml'), template1_yaml)
        File.write(File.join(dir, 'config', 'issue_templates', 'template2.yaml'), template2_yaml)
      end

      it 'should load the two templates' do
        config.load_issue_templates

        expect(IssueScheduler::IssueTemplate.size).to eq(2)
        expect(IssueScheduler::IssueTemplate.all.map(&:summary)).to eq(['Take out the trash', 'Wash the dog'])
      end

      it 'should set the name for each template to the filename' do
        config.load_issue_templates

        expect(
          IssueScheduler::IssueTemplate.all.map(&:name)
        ).to eq(
          ['config/issue_templates/template1.yaml', 'config/issue_templates/template2.yaml']
        )
      end
    end

    context 'with an invalid template' do
      let(:bad_template_yaml) { <<~YAML }
        # missing cron
        project: 'MYPROJECT'
        summary: 'Take out the trash'
      YAML

      before do
        IssueScheduler::IssueTemplate.delete_all

        FileUtils.mkdir_p(File.join(dir, 'config', 'issue_templates'))
        File.write(File.join(dir, 'config', 'config.yaml'), config_yaml)
        File.write(File.join(dir, 'config', 'issue_templates', 'template1.yaml'), bad_template_yaml)
      end

      let(:expected_error_message) { %r{\ASkipping invalid issue template config/issue_templates/template1.yaml} }

      it 'should output an error to stderr about the template not being loaded' do
        expect { config.load_issue_templates }.to output(expected_error_message).to_stderr
      end
      it 'should continue without loading the bad template' do
        expect { config.load_issue_templates }.to output.to_stderr
        expect(IssueScheduler::IssueTemplate.size).to eq(0)
      end
    end
  end
end
