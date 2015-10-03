class EventsController < ApplicationController

  before_filter :authenticate_user!, only: [:create, :update, :destroy]
  before_filter :set_defaults, only: :index
  before_filter :set_params_limit_and_offset_parsed, only: :index

  def index
    respond_to do |format|
      format.html
      format.json do
        check_mine
        @events = Event if @events.nil?
        @events = Event.where(build_query params)
        if !params[:count].nil?
          render json: { count: @events.count }
        else
          render json: Event.to_user_side(@events.limit(@limit).offset(@offset))
        end
      end
    end
  end
  def create
    @event = Event.new event_params
    @event.user = current_user
    @event.save
    render_checking_errors
  end
  def update
    @event = Event.find params[:id]
    @event.update_attributes event_params if current_user == @event.user
    render_checking_errors
  end
  def destroy
    @event = Event.find params[:id]
    @event.destroy if @event.user == current_user
    @errors = @event.errors
    @errors = ["That isn't your event"] if current_user != @event.user
    render_checking_errors
  end
  def current_user_data
    respond_to do |format|
      format.html
      format.json do
        render json: current_user
      end
    end
  end

private

  def set_defaults
    @query = ""
  end
  def event_params
    params.require(:event).permit :title, :description, :being_at, :secret
  end
  def set_params_limit_and_offset_parsed
    @offset = 0 if params[:offset].nil?
    @limit = 10 if params[:limit].nil?
    @offset = params[:offset].to_i
    @limit = params[:limit].to_i
    @offset = @limit * @offset
  end
  def parse_query
    @query += "(events.secret = 'f'"
    @query += " OR (events.secret = 't' AND events.user_id = #{current_user.id})" if !current_user.nil?
    @query += ") AND "
  end
  def build_query params
    @query += "(events.title LIKE '%#{params[:search_key]}%' OR events.description LIKE '%#{params[:search_key]}%')"
  end
  def render_checking_errors
    @errors = @event.errors
    @errors = ["That isn't your event"] if current_user != @event.user unless @_action_name == "create"
    successMessage = "Event has been successally #{@_action_name}#{"e" if @_action_name == "destroy" }d"
    if @errors.empty?
      @to_render = { status: :success, event: @event, message: successMessage }
    else
      @to_render = { status: :failure, event: @event, errors: @errors }
    end
    render json: @to_render
  end
  def check_mine
    if params[:mine] && !current_user.nil?
      @events = current_user.events
    else
      parse_query
    end
  end

end
