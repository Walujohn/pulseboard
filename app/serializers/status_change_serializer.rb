class StatusChangeSerializer
  def initialize(status_change)
    @status_change = status_change
  end

  def as_json
    {
      id: @status_change.id,
      from_status: @status_change.from_status,
      to_status: @status_change.to_status,
      reason: @status_change.reason,
      changed_at: @status_change.created_at.iso8601,
      status_display: status_display
    }
  end

  private

  # Human-readable status labels for React to display
  def status_display
    {
      from: human_readable(@status_change.from_status),
      to: human_readable(@status_change.to_status)
    }
  end

  def human_readable(status)
    return nil if status.nil?
    status.humanize.titleize  # "submitted" → "Submitted", "in_review" → "In Review"
  end
end
