module Paginatable
  extend ActiveSupport::Concern

  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE = 100

  private

  def page_param
    [ params.fetch(:page, 1).to_i, 1 ].max
  end

  def per_page_param
    per = params.fetch(:per_page, DEFAULT_PER_PAGE).to_i
    per = DEFAULT_PER_PAGE if per <= 0
    [ per, MAX_PER_PAGE ].min
  end

  def paginate(scope)
    scope.offset((page_param - 1) * per_page_param).limit(per_page_param)
  end
end
