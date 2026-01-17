class StatusUpdateSerializer
  def initialize(status_update)
    @status_update = status_update
  end

  def as_json(*)
    {
      id: @status_update.id,
      body: @status_update.body,
      mood: @status_update.mood,
      likes_count: @status_update.likes_count,
      reactions: @status_update.reaction_summary,
      created_at: @status_update.created_at&.iso8601,
      updated_at: @status_update.updated_at&.iso8601
    }
  end
end
