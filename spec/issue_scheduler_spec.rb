# frozen_string_literal: true

require 'tmpdir'

RSpec.describe IssueScheduler do
  it 'has a version number' do
    expect(IssueScheduler::VERSION).not_to be nil
  end

  describe '.lib_dir' do
    subject { IssueScheduler.lib_dir }
    it { is_expected.to be_a(String) }
  end

  describe '.parse_yaml' do
    subject { IssueScheduler.parse_yaml(yaml_string) }
    context 'when the YAML is a valid object' do
      let(:yaml_string) { <<~YAML }
        username: user
        password: pass
      YAML
      it { is_expected.to eq({ username: 'user', password: 'pass' }) }
    end

    context 'when the YAML is not valid' do
      let(:yaml_string) { <<~YAML }
        '''
      YAML
      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /\AYAML is not valid/)
      end
    end

    context 'when the YAML is not an object' do
      let(:yaml_string) { <<~YAML }
        1
      YAML
      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /\AYAML is not an object/)
      end
    end
  end

  describe '.load_yaml' do
    subject { IssueScheduler.load_yaml(yaml_file) }
    let(:yaml_file) { @yaml_file }

    context 'when the file exists and contains a valid YAML object' do
      it 'should return the parsed YAML object' do
        Dir.mktmpdir do |dir|
          @yaml_file = File.join(dir, 'data.yaml')
          File.write(yaml_file, <<~YAML)
            username: user
            password: pass
          YAML
          is_expected.to eq({ username: 'user', password: 'pass' })
        end
      end
    end

    context 'when the file does not exist' do
      it 'should raise a runtime error' do
        Dir.mktmpdir do |dir|
          @yaml_file = File.join(dir, 'data.yaml')
          expect { subject }.to raise_error(RuntimeError, /\Error reading YAML file: No such file or directory/)
        end
      end
    end
  end
end
