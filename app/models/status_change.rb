class StatusChange < ApplicationRecord
  belongs_to :status_update

  validates :status_update_id, presence: true
  validates :to_status, presence: true

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
