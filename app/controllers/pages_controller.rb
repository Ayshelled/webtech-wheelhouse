class PagesController < ApplicationController
  def home
  end

  def services
    @services = [
      { name: "Tune-up", price: 15000 },
      { name: "Wheel true", price: 8000 },
      { name: "Brake bleed", price: 10000 },
      { name: "Chain replacement", price: 18000 },
      { name: "Brake pad replacement", price: 12000 },
      { name: "Tire replacement", price: 14000 },
      { name: "Tube replacement", price: 6000 },
      { name: "Gear adjustment", price: 9000 },
      { name: "Headset adjustment", price: 7000 },
      { name: "Bottom bracket service", price: 20000 },
      { name: "Spoke replacement", price: 5000 },
      { name: "Full bike wash", price: 8000 },
      { name: "Handlebar tape wrap", price: 9000 },
      { name: "Pedal replacement", price: 7000 }
    ]
  end

  def visit
  end

  def about
  end
end