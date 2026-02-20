class UsersController < ApplicationController
  before_action :set_user, only: [:show, :create_api_key, :revoke_api_key]

  def create
    @user = User.new(user_params)
    if @user.save
      render json: @user.as_json(only: [:id, :name, :created_at]), status: :created
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def show
    render json: @user.as_json(only: [:id, :name, :created_at, :updated_at])
  end

  # POST /users/:id/api_keys
  # Returns { api_key: "<plaintext token>", id: <api_key_id> } — plaintext shown only once
  def create_api_key
    result = @user.create_api_key!(name: params[:name])
    render json: { api_key: result[:token], id: result[:api_key].id }, status: :created
  end

  # DELETE /users/:id/api_keys/:key_id
  def revoke_api_key
    api_key = @user.api_keys.find(params[:key_id])
    api_key.revoke!
    head :no_content
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def user_params
    params.require(:user).permit(:name)
  end
end