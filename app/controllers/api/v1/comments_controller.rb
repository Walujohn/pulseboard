module Api
  module V1
    class CommentsController < ActionController::API
      include Paginatable
      include JsonResponses

      before_action :set_status_update

      rescue_from ActiveRecord::RecordNotFound do
        render_error("not_found", "Not found", :not_found)
      end

      def index
        scope = apply_filters(@status_update.comments.order(created_at: :desc))
        total_count = scope.count
        items = paginate(scope)

        render_paginated_data(
          serialize_many(items),
          paginated_meta(total_count),
          :ok
        )
      end

      def create
        comment = @status_update.comments.new(comment_params)
        save_and_respond(comment, :created)
      end

      private

      def set_status_update
        @status_update = StatusUpdate.find(params[:status_update_id])
      end

      def save_and_respond(record, status)
        if record.save
          render_data(serialize_one(record), status)
        else
          render_validation_errors(record, :unprocessable_entity)
        end
      end

      def apply_filters(scope)
        scope = scope.where("body ILIKE ?", "%#{sanitize_like(params[:q])}%") if params[:q].present?
        scope = scope.where("created_at >= ?", Time.iso8601(params[:since])) if params[:since].present?
        scope
      rescue ArgumentError
        scope
      end

      def paginated_meta(total_count)
        {
          page: page_param,
          per_page: per_page_param,
          total_count: total_count
        }
      end

      def comment_params
        params.require(:comment).permit(:body)
      end

      def sanitize_like(term)
        term.gsub("%", "\\%").gsub("_", "\\_")
      end
    end
  end
end
