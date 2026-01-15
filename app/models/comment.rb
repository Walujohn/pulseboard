class Comment < ApplicationRecord
  belongs_to :status_update
  validates :body, presence: true, length: { maximum: 500 }

  scope :recent, -> { order(created_at: :desc) }
end
