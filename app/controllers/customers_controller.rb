class CustomersController < ApplicationController
  before_action :set_customer, only: %i[show edit update destroy]

  def index
    authorize Customer
    @customers = policy_scope(Customer).by_name
  end

  def show
    authorize @customer
  end

  def new
    authorize Customer
    @customer = Customer.new
  end

  def edit
    authorize @customer
  end

  def create
    authorize Customer
    @customer = Customer.new(customer_params)
    if @customer.save
      redirect_to @customer, notice: "Customer #{@customer.name} was created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @customer
    if @customer.update(customer_params)
      redirect_to @customer, notice: "Customer #{@customer.name} was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @customer
    if @customer.destroy
      redirect_to customers_path, notice: "Customer #{@customer.name} was deleted.", status: :see_other
    else
      redirect_to @customer, alert: @customer.errors.full_messages.to_sentence
    end
  end

  private

  def set_customer
    @customer = Customer.includes(bikes: :customer).find(params[:id])
  end

  def customer_params
    params.expect(customer: %i[name phone])
  end
end
