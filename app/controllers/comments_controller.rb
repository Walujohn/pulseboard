class CommentsController < ApplicationController
  before_action :set_status_update
  before_action :set_comment, only: [ :destroy ]

  def create
    @comment = @status_update.comments.new(comment_params)

    respond_to do |format|
      if @comment.save
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.prepend(dom_id(@status_update, :comments_list), partial: "comments/comment", locals: { comment: @comment }),
            turbo_stream.replace("#{dom_id(@status_update)}_comment_form", partial: "comments/form", locals: { status_update: @status_update, comment: Comment.new })
          ]
        end
        format.html { redirect_to root_path, notice: "Comment created." }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("#{dom_id(@status_update)}_comment_form", partial: "comments/form", locals: { status_update: @status_update, comment: @comment })
        end
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @comment.destroy
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.remove(dom_id(@comment))
      end
      format.html { redirect_to root_path, notice: "Comment deleted." }
    end
  end

  private

  def set_status_update
    @status_update = StatusUpdate.find(params[:status_update_id])
  end

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
