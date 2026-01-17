module Api
  module V1
    # Mixin for consistent JSON responses across API controllers
    module JsonResponses
      private

      def render_data(data, status)
        render json: { data: data }, status: status
      end

      def render_error(code, message, status)
        render json: {
          error: {
            code: code,
            message: message
          }
        }, status: status
      end

      def render_validation_errors(record, status)
        render json: {
          error: {
            code: "validation_error",
            messages: record.errors.full_messages
          }
        }, status: status
      end

      def render_paginated_data(items, meta, status)
        render json: {
          meta: meta,
          data: items
        }, status: status
      end

      def serialize_one(record)
        case record
        when StatusUpdate
          StatusUpdateSerializer.new(record).as_json
        when StatusChange
          StatusChangeSerializer.new(record).as_json
        else
          record
        end
      end

      def serialize_many(records)
        records.map { |record| serialize_one(record) }
      end
    end
  end
end
