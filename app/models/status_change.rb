class StatusChange < ApplicationRecord
  # Constants: Valid status values
  STATUSES = [
    "submitted",
    "in_review",
    "approved",
    "denied",
    "needs_info"
  ].freeze

  # Relationships
  belongs_to :status_update

  # Validations
  validates :status_update_id, presence: true
  validates :to_status, presence: true, inclusion: { in: STATUSES }
  validates :from_status, inclusion: { in: STATUSES }, allow_nil: true

  # Scopes
  scope :ordered, -> { order(created_at: :asc) }
  scope :recent_first, -> { order(created_at: :desc) }

  # Create a status change and log it
  # Usage: StatusChange.log!(status_update, from: "submitted", to: "in_review")
  def self.log!(status_update, from: nil, to:, reason: nil)
    create!(
      status_update: status_update,
      from_status: from,
      to_status: to,
      reason: reason
    )
  end
end
