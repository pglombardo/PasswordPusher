# frozen_string_literal: true

class PagesController < ApplicationController
  include HighVoltage::StaticPage

  # def layout_for_page
  #   case params[:id]
  #   when 'home'
  #     'home'
  #   else
  #     'article'
  #   end
  # end
end
