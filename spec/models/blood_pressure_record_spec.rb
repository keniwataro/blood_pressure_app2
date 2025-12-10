# == Schema Information
#
# Table name: blood_pressure_records
#
#  id                 :bigint           not null, primary key
#  diastolic_pressure :integer
#  measured_at        :datetime
#  memo               :text
#  pulse_rate         :integer
#  systolic_pressure  :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  user_id            :bigint           not null
#
# Indexes
#
#  index_blood_pressure_records_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe BloodPressureRecord, type: :model do
  describe 'validations' do
    let(:user) { create(:user, :patient) }

    it 'is valid with valid attributes' do
      record = build(:blood_pressure_record, user: user)
      expect(record).to be_valid
    end

    describe 'systolic_pressure' do
      it 'is invalid without systolic_pressure' do
        record = build(:blood_pressure_record, systolic_pressure: nil)
        expect(record).not_to be_valid
        expect(record.errors[:systolic_pressure]).to include('を入力してください')
      end

      it 'is invalid with systolic_pressure less than or equal to 0' do
        record = build(:blood_pressure_record, systolic_pressure: 0)
        expect(record).not_to be_valid
        expect(record.errors[:systolic_pressure]).to include('は0より大きい値にしてください')
      end

      it 'is invalid with systolic_pressure greater than or equal to 300' do
        record = build(:blood_pressure_record, systolic_pressure: 300)
        expect(record).not_to be_valid
        expect(record.errors[:systolic_pressure]).to include('は300より小さい値にしてください')
      end

      it 'is valid with systolic_pressure between 1 and 299' do
        record = build(:blood_pressure_record, systolic_pressure: 120)
        expect(record).to be_valid
      end
    end

    describe 'diastolic_pressure' do
      it 'is invalid without diastolic_pressure' do
        record = build(:blood_pressure_record, diastolic_pressure: nil)
        expect(record).not_to be_valid
        expect(record.errors[:diastolic_pressure]).to include('を入力してください')
      end

      it 'is invalid with diastolic_pressure less than or equal to 0' do
        record = build(:blood_pressure_record, diastolic_pressure: 0)
        expect(record).not_to be_valid
        expect(record.errors[:diastolic_pressure]).to include('は0より大きい値にしてください')
      end

      it 'is invalid with diastolic_pressure greater than or equal to 200' do
        record = build(:blood_pressure_record, diastolic_pressure: 200)
        expect(record).not_to be_valid
        expect(record.errors[:diastolic_pressure]).to include('は200より小さい値にしてください')
      end

      it 'is valid with diastolic_pressure between 1 and 199' do
        record = build(:blood_pressure_record, diastolic_pressure: 80)
        expect(record).to be_valid
      end
    end

    describe 'pulse_rate' do
      it 'is invalid without pulse_rate' do
        record = build(:blood_pressure_record, pulse_rate: nil)
        expect(record).not_to be_valid
        expect(record.errors[:pulse_rate]).to include('を入力してください')
      end

      it 'is invalid with pulse_rate less than or equal to 0' do
        record = build(:blood_pressure_record, pulse_rate: 0)
        expect(record).not_to be_valid
        expect(record.errors[:pulse_rate]).to include('は0より大きい値にしてください')
      end

      it 'is invalid with pulse_rate greater than or equal to 300' do
        record = build(:blood_pressure_record, pulse_rate: 300)
        expect(record).not_to be_valid
        expect(record.errors[:pulse_rate]).to include('は300より小さい値にしてください')
      end

      it 'is valid with pulse_rate between 1 and 299' do
        record = build(:blood_pressure_record, pulse_rate: 70)
        expect(record).to be_valid
      end
    end

    describe 'measured_at' do
      it 'is invalid without measured_at' do
        record = build(:blood_pressure_record, measured_at: nil)
        expect(record).not_to be_valid
        expect(record.errors[:measured_at]).to include('を入力してください')
      end

      it 'is valid with measured_at' do
        record = build(:blood_pressure_record, measured_at: Time.current)
        expect(record).to be_valid
      end
    end
  end

  describe 'associations' do
    it 'belongs to user' do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq :belongs_to
    end
  end

  describe 'scopes' do
    let(:user) { create(:user, :patient) }
    let!(:old_record) { create(:blood_pressure_record, user: user, measured_at: 2.months.ago) }
    let!(:new_record) { create(:blood_pressure_record, user: user, measured_at: 1.day.ago) }
    let!(:newer_record) { create(:blood_pressure_record, user: user, measured_at: Time.current) }

    describe '.recent' do
      it 'orders records by measured_at in descending order' do
        expect(described_class.recent.first).to eq(newer_record)
        expect(described_class.recent.last).to eq(old_record)
      end
    end

    describe '.this_month' do
      it 'returns records from the last month' do
        expect(described_class.this_month).to include(new_record, newer_record)
        expect(described_class.this_month).not_to include(old_record)
      end
    end
  end

  describe '#blood_pressure_category' do
    let(:user) { create(:user, :patient) }

    context 'when normal blood pressure' do
      it 'returns "正常血圧" for systolic < 120 and diastolic < 80' do
        record = build(:blood_pressure_record, user: user, systolic_pressure: 110, diastolic_pressure: 70)
        expect(record.blood_pressure_category).to eq('正常血圧')
      end
    end

    context 'when normal high blood pressure' do
      it 'returns "正常高値血圧" for 120 <= systolic < 130 and 80 <= diastolic < 85' do
        record = build(:blood_pressure_record, user: user, systolic_pressure: 125, diastolic_pressure: 82)
        expect(record.blood_pressure_category).to eq('正常高値血圧')
      end
    end

    context 'when mild hypertension (grade 1)' do
      it 'returns "軽症高血圧（Ⅰ度）" for 130 <= systolic < 140 and 85 <= diastolic < 90' do
        record = build(:blood_pressure_record, user: user, systolic_pressure: 135, diastolic_pressure: 87)
        expect(record.blood_pressure_category).to eq('軽症高血圧（Ⅰ度）')
      end
    end

    context 'when moderate hypertension (grade 2)' do
      it 'returns "中等症高血圧（Ⅱ度）" for 140 <= systolic < 160 and 90 <= diastolic < 100' do
        record = build(:blood_pressure_record, user: user, systolic_pressure: 150, diastolic_pressure: 95)
        expect(record.blood_pressure_category).to eq('中等症高血圧（Ⅱ度）')
      end
    end

    context 'when severe hypertension (grade 3)' do
      it 'returns "重症高血圧（Ⅲ度）" for systolic >= 160 or diastolic >= 100' do
        record = build(:blood_pressure_record, user: user, systolic_pressure: 170, diastolic_pressure: 110)
        expect(record.blood_pressure_category).to eq('重症高血圧（Ⅲ度）')
      end
    end
  end

  describe 'factory traits' do
    describe ':normal' do
      it 'creates record with normal blood pressure values' do
        record = create(:blood_pressure_record, :normal)
        expect(record.systolic_pressure).to eq(118)
        expect(record.diastolic_pressure).to eq(78)
        expect(record.pulse_rate).to eq(72)
      end
    end

    describe ':high_normal' do
      it 'creates record with high normal blood pressure values' do
        record = create(:blood_pressure_record, :high_normal)
        expect(record.systolic_pressure).to eq(125)
        expect(record.diastolic_pressure).to eq(82)
        expect(record.pulse_rate).to eq(75)
      end
    end

    describe ':hypertension_stage1' do
      it 'creates record with stage 1 hypertension values' do
        record = create(:blood_pressure_record, :hypertension_stage1)
        expect(record.systolic_pressure).to eq(135)
        expect(record.diastolic_pressure).to eq(85)
        expect(record.pulse_rate).to eq(78)
      end
    end

    describe ':hypertension_stage2' do
      it 'creates record with stage 2 hypertension values' do
        record = create(:blood_pressure_record, :hypertension_stage2)
        expect(record.systolic_pressure).to eq(150)
        expect(record.diastolic_pressure).to eq(95)
        expect(record.pulse_rate).to eq(80)
      end
    end

    describe ':severe_hypertension' do
      it 'creates record with severe hypertension values' do
        record = create(:blood_pressure_record, :severe_hypertension)
        expect(record.systolic_pressure).to eq(180)
        expect(record.diastolic_pressure).to eq(110)
        expect(record.pulse_rate).to eq(85)
      end
    end

    describe ':low_blood_pressure' do
      it 'creates record with low blood pressure values' do
        record = create(:blood_pressure_record, :low_blood_pressure)
        expect(record.systolic_pressure).to eq(90)
        expect(record.diastolic_pressure).to eq(60)
        expect(record.pulse_rate).to eq(65)
      end
    end

    describe ':with_memo' do
      it 'creates record with memo' do
        record = create(:blood_pressure_record, :with_memo)
        expect(record.memo).to eq("朝食後30分で測定。落ち着いた状態で測定。")
      end
    end

    describe ':recent' do
      it 'creates record with recent measured_at' do
        record = create(:blood_pressure_record, :recent)
        expect(record.measured_at).to be_within(1.hour).of(1.hour.ago)
      end
    end

    describe ':old' do
      it 'creates record with old measured_at' do
        record = create(:blood_pressure_record, :old)
        expect(record.measured_at).to be_within(1.day).of(1.month.ago)
      end
    end
  end
end
