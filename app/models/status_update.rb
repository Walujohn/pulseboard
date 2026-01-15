class StatusUpdate < ApplicationRecord
  MOODS = [ "focused", "calm", "happy", "blocked" ].freeze

  validates :body, presence: true, length: { maximum: 280 }
  validates :mood, presence: true, inclusion: { in: MOODS }
  has_many :comments, dependent: :destroy
  has_many :reactions, dependent: :destroy

  scope :recent, -> { order(created_at: :desc) }

  def increment_likes
    increment!(:likes_count)
  end

  def reaction_summary
    reactions.group(:emoji).count
  end
end
