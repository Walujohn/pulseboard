class StatusUpdate < ApplicationRecord
  enum :mood, { focused: 0, calm: 1, happy: 2, blocked: 3 }

  has_many :comments, dependent: :destroy
  has_many :reactions, dependent: :destroy
  has_many :status_changes, dependent: :destroy

  validates :body, presence: true, length: { maximum: 280 }
  validates :mood, presence: true

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
