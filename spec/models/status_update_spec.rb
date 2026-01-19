require 'rails_helper'

RSpec.describe StatusUpdate, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:body) }
    it { should validate_length_of(:body).is_at_most(280) }
    it { should validate_presence_of(:mood) }
  end

  describe 'associations' do
    it { should have_many(:comments).dependent(:destroy) }
  end

  describe '#increment_likes' do
    let(:status_update) { create(:status_update, likes_count: 5) }

    it 'increments the likes count' do
      expect {
        status_update.increment_likes
      }.to change(status_update, :likes_count).from(5).to(6)
    end

    it 'persists the change to database' do
      status_update.increment_likes
      expect(StatusUpdate.find(status_update.id).likes_count).to eq(6)
    end
  end

  describe '.recent scope' do
    it 'returns status updates with newest first' do
      # Create isolated records
      su1 = create(:status_update, body: 'Oldest')
      su2 = create(:status_update, body: 'Newest')

      # Use where to isolate just the ones we created, then order by id to be deterministic
      recent = StatusUpdate.where(id: [ su1.id, su2.id ]).recent
      expect(recent.first.id).to eq(su2.id)
      expect(recent.last.id).to eq(su1.id)
    end
  end

  describe 'mood enum' do
    it 'has all expected moods' do
      expect(StatusUpdate.moods.keys).to include('focused', 'calm', 'happy', 'blocked')
    end

    it 'generates scope methods for each mood' do
      create(:status_update, mood: :focused)
      expect(StatusUpdate.focused.count).to be > 0
    end

    it 'cannot be set to an invalid value' do
      expect {
        build(:status_update, mood: 'invalid')
      }.to raise_error(ArgumentError)
    end
  end
end
