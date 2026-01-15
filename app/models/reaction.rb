class Reaction < ApplicationRecord
  EMOJIS = [ "👍", "❤️", "😂", "😮", "😢", "🔥" ].freeze

  belongs_to :status_update
  validates :emoji, presence: true, inclusion: { in: EMOJIS }
  validates :user_identifier, presence: true
  validates :status_update_id, presence: true
  validates :user_identifier, uniqueness: { scope: [ :status_update_id, :emoji ], message: "can only react once per emoji per update" }

  # Useful for group-by operations in the API response
  scope :by_emoji, -> { group_by(&:emoji) }
end
