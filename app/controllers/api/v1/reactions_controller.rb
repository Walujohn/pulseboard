module Api
  module V1
    class ReactionsController < ActionController::API
      include JsonResponses

      before_action :set_status_update
      before_action :set_reaction, only: [ :destroy ]

      # GET /api/v1/status_updates/:status_update_id/reactions
      # Returns reactions grouped by emoji with counts
      def index
        reactions_summary = @status_update.reactions.group(:emoji).count

        data = reactions_summary.map { |emoji, count|
          {
            emoji: emoji,
            count: count,
            users: @status_update.reactions.where(emoji: emoji).pluck(:user_identifier)
          }
        }

        render_data(data, :ok)
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
          render_data({ toggled: false }, :ok)
        else
          # Create new reaction
          @reaction = @status_update.reactions.new(reaction_params)

          if @reaction.save
            render_data(serialize_one(@reaction), :created)
          else
            render_validation_errors(@reaction, :unprocessable_entity)
          end
        end
      end

      # DELETE /api/v1/status_updates/:status_update_id/reactions/:id
      def destroy
        @reaction.destroy
        render_data({ success: true }, :ok)
      end

      private

      def set_status_update
        @status_update = StatusUpdate.find(params[:status_update_id])
      rescue ActiveRecord::RecordNotFound
        render_error("not_found", "Status update not found", :not_found)
      end

      def set_reaction
        @reaction = @status_update.reactions.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_error("not_found", "Reaction not found", :not_found)
      end

      def reaction_params
        params.require(:reaction).permit(:emoji, :user_identifier)
      end
    end
  end
end
