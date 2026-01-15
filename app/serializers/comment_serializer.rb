class CommentSerializer
  def initialize(comment)
    @comment = comment
  end

  def as_json(*)
    {
      id: @comment.id,
      status_update_id: @comment.status_update_id,
      body: @comment.body,
      created_at: @comment.created_at&.iso8601,
      updated_at: @comment.updated_at&.iso8601
    }
  end
end
