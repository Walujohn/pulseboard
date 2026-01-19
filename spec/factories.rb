FactoryBot.define do
  factory :status_update do
    body { Faker::Lorem.sentence }
    mood { StatusUpdate.moods.keys.sample }
    likes_count { 0 }
  end

  factory :comment do
    association :status_update
    body { Faker::Lorem.sentence }
  end

  factory :reaction do
    association :status_update
    emoji { Reaction::EMOJIS.sample }
    user_identifier { "user_#{SecureRandom.random_bytes(4).unpack1('H*')}" }
  end

  factory :status_change do
    association :status_update
    from_status { nil }
    to_status { 'approved' }
    reason { nil }
  end
end
