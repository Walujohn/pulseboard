class StatusUpdatesController < ApplicationController
  before_action :set_status_update, only: [ :show, :edit, :update, :destroy, :like ]

  def index
    @status_update = StatusUpdate.new
    @status_updates = StatusUpdate.recent
  end

  def show
    @changes = @status_update.status_changes.ordered
  end

  def create
    @status_update = StatusUpdate.new(status_update_params)

    if @status_update.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to root_path }
      end
    else
      @status_updates = StatusUpdate.recent
      render :index, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @status_update.update(status_update_params)
      @changes = @status_update.status_changes.ordered
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to root_path }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @status_update.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to root_path }
    end
  end

  def like
    @status_update.increment_likes
    render json: { likes_count: @status_update.likes_count }, status: :ok
  end

  private

  def set_status_update
    @status_update = StatusUpdate.find(params[:id])
  end

  def status_update_params
    params.require(:status_update).permit(:body, :mood)
  end
end
