class ReactionSerializer
  def initialize(reaction)
    @reaction = reaction
  end

  def as_json(*)
    {
      id: @reaction.id,
      emoji: @reaction.emoji,
      user_identifier: @reaction.user_identifier,
      status_update_id: @reaction.status_update_id,
      created_at: @reaction.created_at&.iso8601
    }
  end
end
