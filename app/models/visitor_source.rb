# frozen_string_literal: true

# visitor_id – генерируем и храним в куки
# refc - ищем по куке refc и показываем если есть
# user_id - когда юзер регается, то мы ищем эту запись по visitor id и обновляем registered user
# current - Параметры самого крайнего источника перехода.
# current_add - Дополнительные данные о текущем посещении пользователя: дате/времени и точке входа.
# first - Кука по составу абсолютно аналогична sbjs_current, но в ней сохраняются параметры самого первого источника посетителя. Эта кука устанавливается один раз и никогда не перезаписывается.
# first_add - Дополнительные данные о первом посещении пользователя: дате/времени и точке входа.
# session - Кука-флаг, что у пользователя открыта сессия.
# udata - Дополнительные данные о пользователе: ip и user-agent.

class VisitorSource
  include Mongoid::Document
  include Mongoid::Timestamps
  store_in collection: 'visitor_sources'

  field :visitor_id, type: String
  field :refc, type: String
  field :user_id, type: Integer
  field :current, type: String
  field :current_add, type: String
  field :first, type: String
  field :first_add, type: String
  field :session, type: String
  field :udata, type: String

  index({ visitor_id: 1 }, { unique: true })
  index(_id: 'hashed')

  def self.track_visitor(visitor_id, attributes = {})
    attributes.symbolize_keys!
    return unless visitor_id

    vs = find_or_initialize_by(visitor_id: visitor_id)
    return if vs.user_id

    vs.refc ||= attributes[:refc]
    vs.user_id = attributes[:user_id]
    vs.current = attributes[:current]
    vs.current_add = attributes[:current_add]
    vs.first = attributes[:first]
    vs.first_add = attributes[:first_add]
    vs.session = attributes[:session]
    vs.udata = attributes[:udata]
    vs.save
  end

  def browser
    uag = udata.to_s.split('|||')[2]&.gsub('uag=', '')
    [nil, '(none)'].include?(uag) ? '' : uag
  end

  def campaign
    cmp = first.to_s.split('|||')[3]&.gsub('cmp=', '')
    [nil, '(none)'].include?(cmp) ? '' : cmp
  end

  def enter_point
    ep = first_add.to_s.split('|||')[1]&.gsub('ep=', '')
    [nil, '(none)'].include?(ep) ? '' : ep
  end

  def ip_address
    uip = udata.to_s.split('|||')[1]&.gsub('uip=', '')
    [nil, '(none)'].include?(uip) ? '' : uip
  end

  def referer
    rf = first_add.to_s.split('|||')[2]&.gsub('rf=', '')
    [nil, '(none)'].include?(rf) ? '' : rf
  end

  def utm_source
    src = first.to_s.split('|||')[1]&.gsub('src=', '')
    [nil, '(direct)'].include?(src) ? 'direct' : src
  end
end
