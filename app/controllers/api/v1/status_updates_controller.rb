module Api
  module V1
    class StatusUpdatesController < ActionController::API
      rescue_from ActiveRecord::RecordNotFound do
        render json: { error: "Not found" }, status: :not_found
      end

      def index
        updates = StatusUpdate.order(created_at: :desc)
        render json: updates.map { |u| serialize(u) }, status: :ok
      end

      def create
        update = StatusUpdate.new(status_update_params)

        if update.save
          render json: serialize(update), status: :created
        else
          render json: { errors: update.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def status_update_params
        params.require(:status_update).permit(:body, :mood)
      end

      def serialize(u)
        {
          id: u.id,
          body: u.body,
          mood: u.mood,
          likes_count: u.likes_count,
          created_at: u.created_at
        }
      end
    end
  end
end
