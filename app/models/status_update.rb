class StatusUpdate < ApplicationRecord
  MOODS = [ "focused", "calm", "happy", "blocked" ].freeze
  STATUSES = [ "submitted", "in_review", "approved", "denied", "needs_info" ].freeze

  validates :body, presence: true, length: { maximum: 280 }
  validates :mood, presence: true, inclusion: { in: MOODS }
  has_many :comments, dependent: :destroy
  has_many :reactions, dependent: :destroy
  has_many :status_changes, dependent: :destroy

  scope :recent, -> { order(created_at: :desc) }

  # Note: StatusChanges are explicitly created via StatusChange.log!, not automatically
  # from mood changes. This keeps mood tracking separate from status tracking.

  def increment_likes
    increment!(:likes_count)
  end

  def reaction_summary
    reactions.group(:emoji).count
  end
end
