require 'rails_helper'

RSpec.describe Reaction, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:emoji) }
    it { should validate_inclusion_of(:emoji).in_array(Reaction::EMOJIS) }
    it { should validate_presence_of(:user_identifier) }
    it { should validate_presence_of(:status_update_id) }
  end

  describe 'associations' do
    it { should belong_to(:status_update) }
  end

  describe 'uniqueness validation' do
    let(:status_update) { create(:status_update) }
    let(:user_id) { "user_123" }
    let(:emoji) { "👍" }

    before do
      create(:reaction, status_update: status_update, user_identifier: user_id, emoji: emoji)
    end

    it 'prevents duplicate reactions from same user with same emoji' do
      duplicate = build(:reaction, status_update: status_update, user_identifier: user_id, emoji: emoji)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_identifier]).to be_present
    end

    it 'allows same user to react with different emoji' do
      different_emoji = create(:reaction, status_update: status_update, user_identifier: user_id, emoji: "❤️")
      expect(different_emoji).to be_valid
    end

    it 'allows different users to react with same emoji' do
      other_user = create(:reaction, status_update: status_update, user_identifier: "other_user", emoji: emoji)
      expect(other_user).to be_valid
    end
  end

  describe '.by_emoji scope' do
    let(:status_update) { create(:status_update) }

    before do
      create(:reaction, status_update: status_update, emoji: "👍")
      create(:reaction, status_update: status_update, emoji: "👍")
      create(:reaction, status_update: status_update, emoji: "❤️")
    end

    it 'groups reactions by emoji' do
      grouped = status_update.reactions.group_by(&:emoji)

      expect(grouped["👍"].length).to eq(2)
      expect(grouped["❤️"].length).to eq(1)
    end
  end
end
