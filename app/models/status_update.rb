class StatusUpdate < ApplicationRecord
    validates :body, presence: true, length: { maximum: 280 }
    validates :mood, presence: true
end
