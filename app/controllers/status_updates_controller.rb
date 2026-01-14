class StatusUpdatesController < ApplicationController
  def index
    @status_update = StatusUpdate.new
    @status_updates = StatusUpdate.order(created_at: :desc)
  end

  def create
    @status_update = StatusUpdate.new(status_update_params)

    if @status_update.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to root_path }
      end
    else
      @status_updates = StatusUpdate.order(created_at: :desc)
      render :index, status: :unprocessable_entity
    end
  end

  def edit
    @status_update = StatusUpdate.find(params[:id])
  end

  def update
    @status_update = StatusUpdate.find(params[:id])

    if @status_update.update(status_update_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to root_path }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @status_update = StatusUpdate.find(params[:id])
    @status_update.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to root_path }
    end
  end

  # Stimulus endpoint (React-style "like button" → Hotwire)
  def like
    update = StatusUpdate.find(params[:id])
    update.increment!(:likes_count)
    render json: { likes_count: update.likes_count }, status: :ok
  end

  private

  def status_update_params
    params.require(:status_update).permit(:body, :mood)
  end
end

