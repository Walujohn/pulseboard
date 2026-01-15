require 'rails_helper'

RSpec.describe Comment, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:body) }
    it { should validate_length_of(:body).is_at_most(500) }
  end

  describe 'associations' do
    it { should belong_to(:status_update) }
  end

  describe '.recent scope' do
    it 'returns comments with newest first' do
      status_update = create(:status_update)
      c1 = create(:comment, status_update: status_update, body: 'Old')
      c2 = create(:comment, status_update: status_update, body: 'New')

      recent = Comment.where(id: [ c1.id, c2.id ]).recent
      expect(recent.first.id).to eq(c2.id)
      expect(recent.last.id).to eq(c1.id)
    end
  end
end
