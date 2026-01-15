module Api
  module V1
    class StatusUpdatesController < ActionController::API
      include Paginatable

      rescue_from ActiveRecord::RecordNotFound do
        render json: { error: { code: "not_found", message: "Not found" } }, status: :not_found
      end

      def index
        scope = StatusUpdate.order(created_at: :desc)

        # Filtering (React-friendly)
        if params[:q].present?
          q = params[:q].to_s.strip
          scope = scope.where("body ILIKE ?", "%#{sanitize_like(q)}%")
        end

        scope = scope.where(mood: params[:mood]) if params[:mood].present?

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
          data: items.map { |u| StatusUpdateSerializer.new(u).as_json }
        }, status: :ok
      end

      def show
        update = StatusUpdate.find(params[:id])
        render json: { data: StatusUpdateSerializer.new(update).as_json }, status: :ok
      end

      def create
        update = StatusUpdate.new(status_update_params)

        if update.save
          render json: { data: StatusUpdateSerializer.new(update).as_json }, status: :created
        else
          render json: { error: { code: "validation_error", messages: update.errors.full_messages } },
                 status: :unprocessable_entity
        end
      end

      def update
        update = StatusUpdate.find(params[:id])

        if update.update(status_update_params)
          render json: { data: StatusUpdateSerializer.new(update).as_json }, status: :ok
        else
          render json: { error: { code: "validation_error", messages: update.errors.full_messages } },
                 status: :unprocessable_entity
        end
      end

      def destroy
        update = StatusUpdate.find(params[:id])
        update.destroy
        head :no_content
      end

      private

      def status_update_params
        params.require(:status_update).permit(:body, :mood)
      end

      def sanitize_like(term)
        term.gsub("%", "\\%").gsub("_", "\\_")
      end
    end
  end
end
