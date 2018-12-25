class ApiController < ApplicationController
  def create
    # Required Parameters
    #   api_key=string
    #   password=string

    # Optional 1 time parameters
    #   expire_days=number
    #   expire_views=number
    
    unless params.has_key?(:api_key)
      respond_to do |format|
          format.text { render text: t('api.error.provide_key') }
      end
      return
    end
    
    
  end

  def generate
  end

  def list
  end

  def config
  end

end
