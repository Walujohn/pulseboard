module JsonResponses
  extend ActiveSupport::Concern

  private

  # Render successful response
  def render_data(data, status)
    render json: { data: data }, status: status
  end

  # Render error response
  def render_error(code, message, status)
    render json: {
      error: {
        code: code,
        message: message
      }
    }, status: status
  end

  # Render validation errors from model
  def render_validation_errors(record, status)
    render json: {
      error: {
        code: "validation_error",
        messages: record.errors.full_messages
      }
    }, status: status
  end

  # Render paginated response with meta
  def render_paginated_data(items, meta, status)
    render json: {
      meta: meta,
      data: items
    }, status: status
  end

  # Serialize a single record to JSON
  def serialize_one(record)
    case record
    when StatusUpdate
      StatusUpdateSerializer.new(record).as_json
    when StatusChange
      StatusChangeSerializer.new(record).as_json
    when Comment
      CommentSerializer.new(record).as_json
    when Reaction
      ReactionSerializer.new(record).as_json
    else
      record.as_json
    end
  end

  # Serialize multiple records to JSON array
  def serialize_many(records)
    records.map { |record| serialize_one(record) }
  end
end
