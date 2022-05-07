# frozen_string_literal: true

RSpec.describe IssueScheduler do
  it 'has a version number' do
    expect(IssueScheduler::VERSION).not_to be nil
  end

  describe '.lib_dir' do
    subject { IssueScheduler.lib_dir }
    it { is_expected.to be_a(String) }
  end
end
