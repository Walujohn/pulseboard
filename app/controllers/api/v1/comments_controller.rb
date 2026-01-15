module Api
  module V1
    class CommentsController < ActionController::API
      include Paginatable

      rescue_from ActiveRecord::RecordNotFound do
        render json: { error: { code: "not_found", message: "Not found" } }, status: :not_found
      end

      def index
        status_update = StatusUpdate.find(params[:status_update_id])

        scope = status_update.comments.order(created_at: :desc)

        # q filter (case-insensitive substring search)
        if params[:q].present?
          q = params[:q].to_s.strip
          scope = scope.where("body ILIKE ?", "%#{sanitize_like(q)}%")
        end

        # since filter (ISO8601 timestamp)
        if params[:since].present?
          since = Time.iso8601(params[:since]) rescue nil
          scope = scope.where("created_at >= ?", since) if since
        end

        total_count = scope.count
        items = paginate(scope)

        render json: {
          meta: {
            page: page_param,
            per_page: per_page_param,
            total_count: total_count
          },
          data: items.map { |comment| ::CommentSerializer.new(comment).as_json }
        }, status: :ok
      end

      def create
        status_update = StatusUpdate.find(params[:status_update_id])
        comment = status_update.comments.new(comment_params)

        if comment.save
          render json: { data: ::CommentSerializer.new(comment).as_json }, status: :created
        else
          render json: {
            error: {
              code: "validation_error",
              messages: comment.errors.full_messages
            }
          }, status: :unprocessable_entity
        end
      end

      private

      def comment_params
        params.require(:comment).permit(:body)
      end

      def sanitize_like(term)
        term.gsub("%", "\\%").gsub("_", "\\_")
      end
    end
  end
end
