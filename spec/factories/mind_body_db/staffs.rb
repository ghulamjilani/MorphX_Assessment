# frozen_string_literal: true
FactoryBot.define do
  factory :mind_body_db_staff, class: 'MindBodyDb::Staff' do
    first_name { Forgery('name').first_name }
    last_name { Forgery('name').last_name }
    sequence(:email) { |n| "mb_user#{n}_#{rand(0..9999)}@example.com" }
    address { "#{rand(1000)} Main St." }
    appointment_instructor { [true, false].sample }
    always_allow_double_booking { [true, false].sample }
    bio { "#{first_name} has been a fitness instructor for over 10 years" }
    city { Forgery('address').city }
    country { 'UNITED STATES' }
    home_phone { Forgery('address').phone }
    independent_contractor { false }
    is_male { [true, false].sample }
    mobile_phone { Forgery('address').phone }
    name { "#{first_name} #{last_name}" }
    postal_code { '93401' }
    class_teacher { [true, false].sample }
    sort_order { 0 }
    state { 'CA' }
    work_phone { Forgery('address').phone }
    image_url { 'https://clients.mindbodyonline.com/studios/ACMEYoga/staff/1_large.jpg?osv=637160121420806704' }
  end

  factory :mind_body_db_staff_class_teacher, parent: :mind_body_db_staff do
    class_teacher { true }
  end

  factory :mind_body_db_staff_appointment_instructor, parent: :mind_body_db_staff do
    appointment_instructor { true }
  end

  factory :mind_body_db_staff_independent_contractor, parent: :mind_body_db_staff do
    independent_contractor { true }
  end

  factory :mind_body_db_staff_linked_to_user, parent: :mind_body_db_staff do
    user
    first_name { user.first_name }
    last_name { user.last_name }
    email { user.email }
  end

  factory :aa_stub_mind_body_db_staffs, parent: :mind_body_db_staff
end
