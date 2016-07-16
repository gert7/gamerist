class StaticController < ApplicationController
  def show
    sp = safe_page
    if sp
      render template: "static/" + sp
    else
      redirect_to "/"
    end
  end
  
  def safe_page
    params[:page] if ["terms", "regions"].include?(params[:page])
  end
end

