class PagesController < ApplicationController
  allow_unauthenticated_access only: :services

  def home
  end

  def services
    @services = ServiceCatalogItem.by_name
  end

  def visit
  end

  def about
  end
end
