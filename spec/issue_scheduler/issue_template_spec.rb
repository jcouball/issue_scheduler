# frozen_string_literal: true

RSpec.describe IssueScheduler::IssueTemplate do
  describe '#initialize' do
    subject { described_class.new(template_yaml) }
    context 'with a valid template that specifies all values' do
      let(:template_yaml) { <<~YAML }
        template_name: Take out the trash
        recurrance_rule: RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR
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
          template_name: 'Take out the trash',
          recurrance_rule: RRule::Rule,
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
        template_name: Take out the trash
        recurrance_rule: 'RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR'
        project: 'MYPROJECT'
        summary: 'Take out the trash'
      YAML

      let(:expected_attributes) do
        {
          template_name: 'Take out the trash',
          recurrance_rule: RRule::Rule,
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

    context 'when template_name is not given' do
      let(:template_yaml) { <<~YAML }
        recurrance_rule: 'RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR'
        project: MYPROJECT
        summary: 'Take out the trash'
      YAML

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /Missing issue template keys: \[:template_name\]/)
      end
    end

    context 'when template_name is not a string' do
      let(:template_yaml) { <<~YAML }
        template_name: 123
        recurrance_rule: RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR
        project: MYPROJECT
        summary: Take out the trash
      YAML

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /Invalid value for template_name/)
      end
    end

    context 'when template_name is an empty string' do
      let(:template_yaml) { <<~YAML }
        template_name: ""
        recurrance_rule: RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR
        project: MYPROJECT
        summary: Take out the trash
      YAML

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /Invalid value for template_name/)
      end
    end

    context 'when recurrence_rule is not given' do
      let(:template_yaml) { <<~YAML }
        template_name: Take out the trash
        project: 'MYPROJECT'
        summary: 'Take out the trash'
      YAML

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /Missing issue template keys: \[:recurrance_rule\]/)
      end
    end

    context 'when recurrence_rule is not a string' do
      let(:template_yaml) { <<~YAML }
        template_name: Take out the trash
        recurrance_rule: 1
        project: 'MYPROJECT'
        summary: 'Take out the trash'
      YAML

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /Invalid value for recurrance_rule/)
      end
    end

    context 'when recurrence_rule is an empty string' do
      let(:template_yaml) { <<~YAML }
        template_name: Take out the trash
        recurrance_rule: ""
        project: 'MYPROJECT'
        summary: 'Take out the trash'
      YAML

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /Invalid value for recurrance_rule/)
      end
    end

    context 'when recurrence_rule is not a valid RRULE' do
      let(:template_yaml) { <<~YAML }
        template_name: Take out the trash
        recurrance_rule: "asdfasdf"
        project: 'MYPROJECT'
        summary: 'Take out the trash'
      YAML

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /Invalid value for recurrance_rule/)
      end
    end

    context 'when project is not given' do
      # component, description, type, and due_date are optional

      let(:template_yaml) { <<~YAML }
        template_name: Take out the trash
        recurrance_rule: 'RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR'
        summary: 'Take out the trash'
      YAML

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /Missing issue template keys: \[:project\]/)
      end
    end

    context 'when project is not a string' do
      # component, description, type, and due_date are optional

      let(:template_yaml) { <<~YAML }
        template_name: Take out the trash
        recurrance_rule: 'RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR'
        project: 1
        summary: 'Take out the trash'
      YAML

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /Invalid value for project/)
      end
    end

    context 'when project is an empty string' do
      let(:template_yaml) { <<~YAML }
        template_name: Take out the trash
        recurrance_rule: 'RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR'
        project: ""
        summary: 'Take out the trash'
      YAML

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /Invalid value for project/)
      end
    end

    context 'when project is a lowercase string' do
      let(:template_yaml) { <<~YAML }
        template_name: Take out the trash
        recurrance_rule: 'RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR'
        project: myproject
        summary: 'Take out the trash'
      YAML

      it 'should upcase project' do
        is_expected.to have_attributes(project: 'MYPROJECT')
      end
    end

    context 'when component is am empty string' do
      let(:template_yaml) { <<~YAML }
        template_name: Take out the trash
        recurrance_rule: 'RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR'
        project: MYPROJECT
        component: ""
        summary: 'Take out the trash'
      YAML

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /Invalid value for component/)
      end
    end

    context 'when summary is not given' do
      let(:template_yaml) { <<~YAML }
        template_name: Take out the trash
        recurrance_rule: 'RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR'
        project: MYPROJECT
      YAML

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /Missing issue template keys: \[:summary\]/)
      end
    end

    context 'when summary is not a string' do
      let(:template_yaml) { <<~YAML }
        template_name: Take out the trash
        recurrance_rule: 'RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR'
        project: MYPROJECT
        summary: 1
      YAML

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /Invalid value for summary/)
      end
    end

    context 'when summary is an empty string' do
      let(:template_yaml) { <<~YAML }
        template_name: Take out the trash
        recurrance_rule: 'RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR'
        project: MYPROJECT
        summary: ""
      YAML

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /Invalid value for summary/)
      end
    end

    context 'when description is an empty string' do
      let(:template_yaml) { <<~YAML }
        template_name: Take out the trash
        recurrance_rule: 'RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR'
        project: MYPROJECT
        summary: 'Take out the trash'
        description: ""
      YAML

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /Invalid value for description/)
      end
    end

    context 'when type is an empty string' do
      let(:template_yaml) { <<~YAML }
        template_name: Take out the trash
        recurrance_rule: 'RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR'
        project: MYPROJECT
        summary: 'Take out the trash'
        type: ""
      YAML

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /Invalid value for type/)
      end
    end

    context 'when due_date is not a string' do
      let(:template_yaml) { <<~YAML }
        template_name: Take out the trash
        recurrance_rule: 'RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR'
        project: MYPROJECT
        summary: 'Take out the trash'
        due_date: 1
      YAML

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /Invalid value for due_date/)
      end
    end

    context 'when due_date is an empty string' do
      let(:template_yaml) { <<~YAML }
        template_name: Take out the trash
        recurrance_rule: 'RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR'
        project: MYPROJECT
        summary: 'Take out the trash'
        due_date: ""
      YAML

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /Invalid value for due_date/)
      end
    end

    context 'when due_date is not a valid date' do
      let(:template_yaml) { <<~YAML }
        template_name: Take out the trash
        recurrance_rule: 'RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR'
        project: MYPROJECT
        summary: 'Take out the trash'
        due_date: 99-99-99
      YAML

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /Invalid value for due_date/)
      end
    end

    context 'when due_date is a is a Date' do
      let(:template_yaml) { <<~YAML }
        template_name: Take out the trash
        recurrance_rule: 'RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR'
        project: MYPROJECT
        summary: 'Take out the trash'
        due_date: 2022-05-01
      YAML

      it { is_expected.to have_attributes(due_date: Date.parse('2022-05-01')) }
    end

    context 'when the template is not valid YAML' do
      let(:template_yaml) { <<~YAML }
        :
        :ads+_)()
      YAML

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /Error parsing YAML template/)
      end
    end

    context 'when the template is not an object' do
      let(:template_yaml) { <<~YAML }
        1
      YAML

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, /YAML issue template is not an object/)
      end
    end

    context 'when the template includes unexpected keys' do
      let(:template_yaml) { <<~YAML }
        unexpected_key: value
      YAML

      it 'should raise a RuntimeError' do
        expect { subject }.to raise_error(RuntimeError, 'Unexpected issue template keys: [:unexpected_key]')
      end
    end
  end
end
