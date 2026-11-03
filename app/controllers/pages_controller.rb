class PagesController < ApplicationController
  allow_unauthenticated_access only: :services

  def home
    authorize :page, :home?
  end

  def services
    authorize :page, :services?
    @services = policy_scope(ServiceCatalogItem).by_name
  end

  def visit
    authorize :page, :visit?
  end

  def about
    authorize :page, :about?
  end
end
