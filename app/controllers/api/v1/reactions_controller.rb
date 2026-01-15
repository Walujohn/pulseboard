module Api
  module V1
    class ReactionsController < ActionController::API
      before_action :set_status_update
      before_action :set_reaction, only: [ :destroy ]

      # GET /api/v1/status_updates/:status_update_id/reactions
      # Returns reactions grouped by emoji with counts
      def index
        reactions_summary = @status_update.reactions.group(:emoji).count

        render json: {
          data: reactions_summary.map { |emoji, count|
            {
              emoji: emoji,
              count: count,
              users: @status_update.reactions.where(emoji: emoji).pluck(:user_identifier)
            }
          }
        }, status: :ok
      end

      # POST /api/v1/status_updates/:status_update_id/reactions
      # Creates or toggles a reaction
      def create
        existing = @status_update.reactions.find_by(
          emoji: reaction_params[:emoji],
          user_identifier: reaction_params[:user_identifier]
        )

        if existing
          # Toggle: if reaction exists, delete it
          existing.destroy
          render json: { data: { toggled: false } }, status: :ok
        else
          # Create new reaction
          @reaction = @status_update.reactions.new(reaction_params)

          if @reaction.save
            render json: { data: ::ReactionSerializer.new(@reaction).as_json }, status: :created
          else
            render json: {
              error: {
                code: "validation_error",
                messages: @reaction.errors.full_messages
              }
            }, status: :unprocessable_entity
          end
        end
      end

      # DELETE /api/v1/status_updates/:status_update_id/reactions/:id
      def destroy
        @reaction.destroy
        render json: { success: true }, status: :ok
      end

      private

      def set_status_update
        @status_update = StatusUpdate.find(params[:status_update_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Status update not found" }, status: :not_found
      end

      def set_reaction
        @reaction = @status_update.reactions.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Reaction not found" }, status: :not_found
      end

      def reaction_params
        params.require(:reaction).permit(:emoji, :user_identifier)
      end
    end
  end
end
