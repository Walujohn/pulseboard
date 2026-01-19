module Api
  module V1
    class StatusUpdatesController < ActionController::API
      include Paginatable
      include JsonResponses

      before_action :set_status_update, only: [ :show, :update, :destroy, :timeline ]

      rescue_from ActiveRecord::RecordNotFound do
        render_error("not_found", "Not found", :not_found)
      end

      def index
        scope = apply_filters(StatusUpdate.order(created_at: :desc))
        total_count = scope.count
        items = paginate(scope)

        render_paginated_data(
          items.map { |u| serialize_one(u) },
          paginated_meta(total_count),
          :ok
        )
      end

      def show
        render_data(serialize_one(@status_update), :ok)
      end

      def create
        @status_update = StatusUpdate.new(status_update_params)
        save_and_respond(@status_update, :created)
      end

      def update
        save_and_respond(@status_update, :ok, status_update_params)
      end

      def destroy
        @status_update.destroy
        head :no_content
      end

      def timeline
        changes = @status_update.status_changes.ordered
        render_data(serialize_many(changes), :ok)
      end

      private

      def set_status_update
        @status_update = StatusUpdate.find(params[:id])
      end

      def save_and_respond(record, status, update_params = nil)
        update_params ? record.update(update_params) : record.save

        if record.errors.empty?
          render_data(serialize_one(record), status)
        else
          render_validation_errors(record, :unprocessable_entity)
        end
      end

      def apply_filters(scope)
        scope = scope.where("body ILIKE ?", "%#{sanitize_like(params[:q])}%") if params[:q].present?
        scope = scope.where(mood: params[:mood]) if params[:mood].present? && StatusUpdate.moods.key?(params[:mood])
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

      def status_update_params
        params.require(:status_update).permit(:body, :mood)
      end

      def sanitize_like(term)
        term.gsub("%", "\\%").gsub("_", "\\_")
      end
    end
  end
end
