# frozen_string_literal: true

RSpec.describe IssueScheduler::IssueTemplate do
  let(:attributes) do
    YAML.safe_load(
      template_yaml,
      permitted_classes: [Symbol, Date],
      aliases: true,
      symbolize_names: true
    )
  end

  let(:template) do
    described_class.new(attributes)
  end

  before do
    IssueScheduler::IssueTemplate.delete_all
  end

  describe '.new' do
    subject { template }

    context 'with a valid template that specifies all values' do
      let(:template_yaml) { <<~YAML }
        name: Take out the trash
        cron: 0 0 * * * America/Los_Angeles
        project: MYPROJECT
        component: Internal
        summary: Take out the trash
        description: |
          Take out the trash in the following rooms:
          - kitchen
          - bathroom
          - bedroom
        type: Story
        due_date: 2022-05-03
      YAML

      let(:expected_attributes) do
        {
          name: 'Take out the trash',
          cron: '0 0 * * * America/Los_Angeles',
          project: 'MYPROJECT',
          component: 'Internal',
          summary: 'Take out the trash',
          description: "Take out the trash in the following rooms:\n- kitchen\n- bathroom\n- bedroom\n",
          type: 'Story',
          due_date: Date.parse('2022-05-03')
        }
      end

      it { is_expected.to have_attributes(expected_attributes) }
    end

    context 'with a valid template that specified minimal values' do
      # component, description, type, and due_date are optional

      let(:template_yaml) { <<~YAML }
        name: Take out the trash
        cron: 0 0 * * * America/Los_Angeles
        project: 'MYPROJECT'
        summary: 'Take out the trash'
      YAML

      let(:expected_attributes) do
        {
          name: 'Take out the trash',
          cron: '0 0 * * * America/Los_Angeles',
          project: 'MYPROJECT',
          component: nil,
          summary: 'Take out the trash',
          description: nil,
          type: nil,
          due_date: nil
        }
      end
      it { is_expected.to have_attributes(**expected_attributes) }
    end

    context 'with a template the includes unexpected keys' do
      let(:template_yaml) { <<~YAML }
        unexpected_key: value
      YAML

      it 'should raise an UnknownAttributeError' do
        expect { subject }.to(
          raise_error(
            ActiveModel::UnknownAttributeError,
            /\Aunknown attribute 'unexpected_key'/
          )
        )
      end
    end
  end

  describe '.find' do
    subject { described_class.find(name) }

    context 'with a template named weekly_status_report' do
      let(:name) { 'weekly_status_report' }

      let(:template_yaml) { <<~YAML }
        name: #{name}
        cron: 0 0 * * * America/Los_Angeles
        project: 'MYPROJECT'
        summary: 'Take out the trash'
      YAML

      before do
        IssueScheduler::IssueTemplate.create!(attributes)
      end

      context 'when finding a template with name weekly_status_report' do
        it { is_expected.to be_a(IssueScheduler::IssueTemplate) }
        it { is_expected.to have_attributes(name:) }
      end
    end
  end

  describe '#valid?' do
    subject { template.valid? }

    context 'with a valid template that specifies all values' do
      let(:template_yaml) { <<~YAML }
        name: Take out the trash
        cron: 0 0 * * * America/Los_Angeles
        project: MYPROJECT
        component: Internal
        summary: Take out the trash
        description: |
          Take out the trash in the following rooms:
          - kitchen
          - bathroom
          - bedroom
        type: Story
        due_date: 2022-05-03
      YAML

      it { is_expected.to eq(true) }
    end

    context 'with a valid template that specified minimal values' do
      # component, description, type, and due_date are optional

      let(:template_yaml) { <<~YAML }
        name: Take out the trash
        cron: 0 0 * * * America/Los_Angeles
        project: 'MYPROJECT'
        summary: 'Take out the trash'
      YAML

      it { is_expected.to eq(true) }
    end

    context 'when name is not given' do
      let(:template_yaml) { <<~YAML }
        cron: 0 0 * * * America/Los_Angeles
        project: MYPROJECT
        summary: 'Take out the trash'
      YAML

      it { is_expected.to eq(false) }

      it 'should have an set an error message' do
        subject
        expect(template.errors.full_messages).to include('Name can\'t be blank')
      end
    end

    context 'when name is not a string' do
      let(:template_yaml) { <<~YAML }
        name: 123
        cron: 0 0 * * * America/Los_Angeles
        project: MYPROJECT
        summary: Take out the trash
      YAML

      it { is_expected.to eq(true) }

      it 'should convert name to a string' do
        expect(template.name).to eq('123')
      end
    end

    context 'when name is an empty string' do
      let(:template_yaml) { <<~YAML }
        name: ""
        cron: 0 0 * * * America/Los_Angeles
        project: MYPROJECT
        summary: Take out the trash
      YAML

      it { is_expected.to eq(false) }

      it 'should have an set an error message' do
        subject
        expect(template.errors.full_messages).to include('Name can\'t be blank')
      end
    end

    context 'when cron is not given' do
      let(:template_yaml) { <<~YAML }
        name: Take out the trash
        project: 'MYPROJECT'
        summary: 'Take out the trash'
      YAML

      it { is_expected.to eq(false) }

      it 'should have an set an error message' do
        subject
        expect(template.errors.full_messages).to include('Cron can\'t be blank')
      end
    end

    context 'when cron is an empty string' do
      let(:template_yaml) { <<~YAML }
        name: Take out the trash
        cron: ""
        project: 'MYPROJECT'
        summary: 'Take out the trash'
      YAML

      it { is_expected.to eq(false) }

      it 'should have an set an error message' do
        subject
        expect(template.errors.full_messages).to include('Cron can\'t be blank')
      end
    end

    context 'when cron is not a valid cron spec' do
      let(:template_yaml) { <<~YAML }
        name: Take out the trash
        cron: "asdfasdf"
        project: 'MYPROJECT'
        summary: 'Take out the trash'
      YAML

      it { is_expected.to eq(false) }

      it 'should have an set an error message' do
        subject
        expect(template.errors.full_messages).to include('Cron is not a valid cron string')
      end
    end

    context 'when project is not given' do
      # component, description, type, and due_date are optional

      let(:template_yaml) { <<~YAML }
        name: Take out the trash
        cron: 0 0 * * * America/Los_Angeles
        summary: 'Take out the trash'
      YAML

      it { is_expected.to eq(false) }

      it 'should have an set an error message' do
        subject
        expect(template.errors.full_messages).to include('Project can\'t be blank')
      end
    end

    context 'when project is not a string' do
      # component, description, type, and due_date are optional

      let(:template_yaml) { <<~YAML }
        name: Take out the trash
        cron: 0 0 * * * America/Los_Angeles
        project: 1
        summary: 'Take out the trash'
      YAML

      it { is_expected.to eq(true) }

      it 'should convert project to a string' do
        expect(template.project).to eq('1')
      end
    end

    context 'when project is an empty string' do
      let(:template_yaml) { <<~YAML }
        name: Take out the trash
        cron: 0 0 * * * America/Los_Angeles
        project: ""
        summary: 'Take out the trash'
      YAML

      it { is_expected.to eq(false) }

      it 'should have an set an error message' do
        subject
        expect(template.errors.full_messages).to include('Project can\'t be blank')
      end
    end

    context 'when project is a lowercase string' do
      let(:template_yaml) { <<~YAML }
        name: Take out the trash
        cron: 0 0 * * * America/Los_Angeles
        project: myproject
        summary: 'Take out the trash'
      YAML

      it { is_expected.to eq(true) }

      it 'should upcase project' do
        expect(template.project).to eq('MYPROJECT')
      end
    end

    context 'when component is am empty string' do
      let(:template_yaml) { <<~YAML }
        name: Take out the trash
        cron: 0 0 * * * America/Los_Angeles
        project: MYPROJECT
        component: ""
        summary: 'Take out the trash'
      YAML

      it { is_expected.to eq(false) }

      it 'should have an set an error message' do
        subject
        expect(template.errors.full_messages).to include('Component can\'t be blank')
      end
    end

    context 'when summary is not given' do
      let(:template_yaml) { <<~YAML }
        name: Take out the trash
        cron: 0 0 * * * America/Los_Angeles
        project: MYPROJECT
      YAML

      it { is_expected.to eq(false) }

      it 'should have an set an error message' do
        subject
        expect(template.errors.full_messages).to include('Summary can\'t be blank')
      end
    end

    context 'when summary is not a string' do
      let(:template_yaml) { <<~YAML }
        name: Take out the trash
        cron: 0 0 * * * America/Los_Angeles
        project: MYPROJECT
        summary: 1
      YAML

      it { is_expected.to eq(true) }

      it 'should convert summary to a string' do
        expect(template.summary).to eq('1')
      end
    end

    context 'when summary is an empty string' do
      let(:template_yaml) { <<~YAML }
        name: Take out the trash
        cron: 0 0 * * * America/Los_Angeles
        project: MYPROJECT
        summary: ""
      YAML

      it { is_expected.to eq(false) }

      it 'should have an set an error message' do
        subject
        expect(template.errors.full_messages).to include('Summary can\'t be blank')
      end
    end

    context 'when description is an empty string' do
      let(:template_yaml) { <<~YAML }
        name: Take out the trash
        cron: 0 0 * * * America/Los_Angeles
        project: MYPROJECT
        summary: 'Take out the trash'
        description: ""
      YAML

      it { is_expected.to eq(false) }

      it 'should have an set an error message' do
        subject
        expect(template.errors.full_messages).to include('Description can\'t be blank')
      end
    end

    context 'when type is an empty string' do
      let(:template_yaml) { <<~YAML }
        name: Take out the trash
        cron: 0 0 * * * America/Los_Angeles
        project: MYPROJECT
        summary: 'Take out the trash'
        type: ""
      YAML

      it { is_expected.to eq(false) }

      it 'should have an set an error message' do
        subject
        expect(template.errors.full_messages).to include('Type can\'t be blank')
      end
    end

    context 'when due_date is a string' do
      let(:template_yaml) { <<~YAML }
        name: Take out the trash
        cron: 0 0 * * * America/Los_Angeles
        project: MYPROJECT
        summary: 'Take out the trash'
        due_date: "2022-05-06"
      YAML

      it { is_expected.to eq(true) }

      it 'should convert the due_date to a Date' do
        expect(template.due_date).to eq(Date.new(2022, 5, 6))
      end
    end

    context 'when due_date is date' do
      let(:template_yaml) { <<~YAML }
        name: Take out the trash
        cron: 0 0 * * * America/Los_Angeles
        project: MYPROJECT
        summary: 'Take out the trash'
        due_date: 2022-05-06
      YAML

      it { is_expected.to eq(true) }

      it 'should convert the due_date to a Date' do
        expect(template.due_date).to eq(Date.new(2022, 5, 6))
      end
    end

    context 'when due_date is an empty string' do
      let(:template_yaml) { <<~YAML }
        name: Take out the trash
        cron: 0 0 * * * America/Los_Angeles
        project: MYPROJECT
        summary: 'Take out the trash'
        due_date: ""
      YAML

      it { is_expected.to eq(false) }

      it 'should have an set an error message' do
        subject
        expect(template.errors.full_messages).to include("Due date '' is not a valid date")
      end
    end

    context 'when due_date is not a valid date' do
      let(:template_yaml) { <<~YAML }
        name: Take out the trash
        cron: 0 0 * * * America/Los_Angeles
        project: MYPROJECT
        summary: 'Take out the trash'
        due_date: 99-99-99
      YAML

      it { is_expected.to eq(false) }

      it 'should have an set an error message' do
        subject
        expect(template.errors.full_messages).to include('Due date \'99-99-99\' is not a valid date')
      end
    end

    context 'when due_date is a is a String' do
      let(:template_yaml) { <<~YAML }
        name: Take out the trash
        cron: 0 0 * * * America/Los_Angeles
        project: MYPROJECT
        summary: 'Take out the trash'
        due_date: "2022-05-06"
      YAML

      it { is_expected.to eq(true) }

      it 'should convert the due_date to a Date' do
        expect(template.due_date).to eq(Date.new(2022, 5, 6))
      end
    end

    # context 'when the template is not valid YAML' do
    #   let(:template_yaml) { <<~YAML }
    #     :
    #     :ads+_)()
    #   YAML

    #   it 'should raise a RuntimeError' do
    #     expect { subject }.to raise_error(RuntimeError, /Error parsing YAML template/)
    #   end
    # end

    # context 'when the template is not an object' do
    #   let(:template_yaml) { <<~YAML }
    #     1
    #   YAML

    #   it 'should raise a RuntimeError' do
    #     expect { subject }.to raise_error(RuntimeError, /YAML issue template is not an object/)
    #   end
    # end
  end
end
