require 'rails_helper'

# ==============================================================================
# StatusChange Model Tests
#
# Purpose: Verify the StatusChange model correctly tracks status transitions
#
# What we're testing:
#   ✓ Associations (belongs_to :status_update)
#   ✓ Validations (to_status required, must be in STATUSES, from_status optional)
#   ✓ The .log! factory method (creates change with proper values)
#   ✓ Scopes (ordered, recent_first)
#   ✓ Concerns the model has (like being destroyed when parent is)
# ==============================================================================

RSpec.describe StatusChange, type: :model do
  describe 'associations' do
    it { should belong_to(:status_update) }

    it 'is destroyed when status_update is destroyed' do
      status_update = create(:status_update)
      change = create(:status_change, status_update: status_update)

      expect {
        status_update.destroy
      }.to change(StatusChange, :count).by(-1)
    end
  end

  describe 'validations' do
    let(:status_update) { create(:status_update) }
    let(:change) { build(:status_change, status_update: status_update) }

    context 'to_status' do
      it 'requires to_status to be present' do
        change.to_status = nil
        expect(change).not_to be_valid
        expect(change.errors[:to_status]).to include("can't be blank")
      end

      it 'requires to_status to be in STATUSES constant' do
        change.to_status = 'invalid_status'
        expect(change).not_to be_valid
        expect(change.errors[:to_status]).to include("is not included in the list")
      end

      it 'accepts valid STATUSES values' do
        status_update = create(:status_update)
        StatusChange::STATUSES.each do |status|
          change = build(:status_change, status_update: status_update, to_status: status)
          # Only validate to_status, not the whole record
          expect(change).to be_valid
        end
      end
    end

    context 'from_status' do
      it 'allows from_status to be nil (initial status)' do
        change.from_status = nil
        expect(change).to be_valid
      end

      it 'allows from_status to be in STATUSES' do
        change.from_status = 'submitted'
        expect(change).to be_valid
      end

      it 'rejects from_status that is not in STATUSES' do
        change.from_status = 'invalid_status'
        expect(change).not_to be_valid
      end
    end
  end

  describe 'STATUSES constant' do
    it 'is defined' do
      expect(StatusChange::STATUSES).to be_present
    end

    it 'is frozen to prevent modification' do
      expect(StatusChange::STATUSES.frozen?).to be true
    end

    it 'contains expected status values' do
      expect(StatusChange::STATUSES).to include(
        'submitted', 'in_review', 'approved', 'denied', 'needs_info'
      )
    end
  end

  describe '.log! factory method' do
    # This is the key method that creates a StatusChange record
    # It's used by the StatusUpdate model callback

    let(:status_update) { create(:status_update) }

    it 'creates a new StatusChange record' do
      expect {
        StatusChange.log!(status_update, from: 'submitted', to: 'in_review')
      }.to change(StatusChange, :count).by(1)
    end

    it 'sets the from_status correctly' do
      change = StatusChange.log!(status_update, from: 'submitted', to: 'in_review')
      expect(change.from_status).to eq('submitted')
    end

    it 'sets the to_status correctly' do
      change = StatusChange.log!(status_update, from: 'submitted', to: 'in_review')
      expect(change.to_status).to eq('in_review')
    end

    it 'associates with the provided status_update' do
      change = StatusChange.log!(status_update, from: 'submitted', to: 'in_review')
      expect(change.status_update_id).to eq(status_update.id)
    end

    it 'allows optional reason parameter' do
      change = StatusChange.log!(
        status_update,
        from: 'submitted',
        to: 'in_review',
        reason: 'Needs legal review'
      )
      expect(change.reason).to eq('Needs legal review')
    end

    it 'allows reason to be nil' do
      change = StatusChange.log!(
        status_update,
        from: 'submitted',
        to: 'in_review'
      )
      expect(change.reason).to be_nil
    end

    it 'records the timestamp' do
      before_time = Time.current
      change = StatusChange.log!(status_update, from: 'submitted', to: 'in_review')
      after_time = Time.current

      expect(change.created_at).to be_between(before_time, after_time)
    end
  end

  describe 'scopes' do
    let(:status_update) { create(:status_update) }

    before do
      # Create multiple changes with specific order
      @change1 = create(:status_change, status_update: status_update, from_status: nil, to_status: 'submitted')
      sleep(0.01)  # Small delay to ensure different timestamps
      @change2 = create(:status_change, status_update: status_update, from_status: 'submitted', to_status: 'in_review')
      sleep(0.01)
      @change3 = create(:status_change, status_update: status_update, from_status: 'in_review', to_status: 'approved')
    end

    describe '.ordered' do
      it 'returns changes in ascending order (oldest first)' do
        ordered = StatusChange.where(status_update_id: status_update.id).ordered
        expect(ordered.pluck(:id)).to eq([ @change1.id, @change2.id, @change3.id ])
      end

      it 'is useful for displaying timeline chronologically' do
        ordered = status_update.status_changes.ordered
        expect(ordered.first.to_status).to eq('submitted')
        expect(ordered.last.to_status).to eq('approved')
      end
    end

    describe '.recent_first' do
      it 'returns changes in descending order (newest first)' do
        recent = StatusChange.where(status_update_id: status_update.id).recent_first
        expect(recent.pluck(:id)).to eq([ @change3.id, @change2.id, @change1.id ])
      end

      it 'is useful for dashboards showing latest activity' do
        recent = status_update.status_changes.recent_first
        expect(recent.first.to_status).to eq('approved')
        expect(recent.last.to_status).to eq('submitted')
      end
    end
  end

  describe 'integration with StatusUpdate' do
    # These tests verify the relationship between StatusChange and StatusUpdate

    it 'is created when explicitly logged via StatusChange.log!' do
      status_update = create(:status_update)

      # StatusChange records are created explicitly, not via callbacks
      expect {
        StatusChange.log!(status_update, from: 'submitted', to: 'in_review')
      }.to change(StatusChange, :count).by(1)
    end

    it 'records the from and to values from the log method' do
      status_update = create(:status_update)

      StatusChange.log!(status_update, from: 'submitted', to: 'in_review')

      change = status_update.status_changes.first
      expect(change.from_status).to eq('submitted')
      expect(change.to_status).to eq('in_review')
    end

    it 'allows querying all changes for a status_update' do
      status_update = create(:status_update)
      create(:status_change, status_update: status_update)
      create(:status_change, status_update: status_update)

      expect(status_update.status_changes.count).to eq(2)
    end

    it 'cascades delete when status_update is destroyed' do
      status_update = create(:status_update)
      change_id = create(:status_change, status_update: status_update).id

      status_update.destroy

      expect(StatusChange.find_by(id: change_id)).to be_nil
    end
  end
end
