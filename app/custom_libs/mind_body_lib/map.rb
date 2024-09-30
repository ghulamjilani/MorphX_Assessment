# frozen_string_literal: true

module MindBodyLib
  module Map
    class << self
      def events
        %w[
          site.created
          site.updated
          site.deactivated
          location.created
          location.updated
          location.deactivated
          classSchedule.created
          classSchedule.updated
          classSchedule.cancelled
          class.updated
          classDescription.updated
          staff.created
          staff.updated
          staff.deactivated
        ]
      end

      def class_description(params)
        params = ActiveSupport::HashWithIndifferentAccess.new(params)
        {
          active: params['Active'],
          description: params['Description'],
          remote_id: params['Id'],
          remote_level_id: params.dig('Level', 'Id'),
          image_url: params['ImageURL'],
          last_updated: params['LastUpdated'],
          level_name: params.dig('Level', 'Name'),
          level_description: params.dig('Level', 'Description'),
          name: params['Name'],
          notes: params['Notes'],
          prereq: params['Prereq'],
          category: params['Category'],
          remote_category_id: params['CategoryId'],
          subcategory: params['Subcategory'],
          remote_subcategory_id: params['SubcategoryId']
        }
      end

      def class_schedule(params)
        params = ActiveSupport::HashWithIndifferentAccess.new(params)
        {
          mind_body_db_class_description_id: params[''],
          mind_body_db_staff_id: params[''],
          mind_body_db_location_id: params[''],
          is_available: params['IsAvailable'],
          remote_id: params['Id'],
          day_sunday: params['DaySunday'],
          day_monday: params['DayMonday'],
          day_tuesday: params['DayTuesday'],
          day_wednesday: params['DayWednesday'],
          day_thursday: params['DayThursday'],
          day_friday: params['DayFriday'],
          day_saturday: params['DaySaturday'],
          allow_open_enrollment: params['AllowOpenEnrollment'],
          allow_date_forward_enrollment: params['AllowDateForwardEnrollment'],
          start_time: params['StartTime'],
          end_time: params['EndTime'],
          start_date: params['StartDate'],
          end_date: params['EndDate']
        }
      end

      def class_room(params)
        params = ActiveSupport::HashWithIndifferentAccess.new(params)
        {
          remote_class_schedule_id: params['ClassScheduleId'],
          remote_id: params['Id'],
          remote_site_id: params.dig('Location', 'SiteId'),
          max_capacity: params['MaxCapacity'],
          web_capacity: params['WebCapacity'],
          total_booked: params['TotalBooked'],
          total_booked_waitlist: params['TotalBookedWaitlist'],
          is_canceled: params['IsCanceled'],
          substitute: params['Substitute'],
          active: params['Active'],
          is_wait_list_available: params['IsWaitlistAvailable'],
          is_enrolled: params['IsEnrolled'],
          hide_cancel: params['HideCancel'],
          is_available: params['IsAvailable'],
          start_date_time: params['StartDateTime'],
          end_date_time: params['EndDateTime'],
          last_modified_date_time: params['LastModifiedDateTime'],
          mind_body_db_class_schedule_id: params['mind_body_db_class_schedule_id']
        }
      end

      def location(params)
        params = ActiveSupport::HashWithIndifferentAccess.new(params)
        {
          mind_body_db_sites_id: params['mind_body_db_sites_id'],
          additional_image_urls: params['AdditionalImageURLs'],
          address: params['Address'],
          address2: params['Address2'],
          # amenities_remote_id:      params['Amenities'][0]['Id'],
          # amenities_name:           params['Amenities'][0]['Name'],
          business_description: params['BusinessDescription'],
          city: params['City'],
          description: params['Description'],
          has_classes: params['HasClasses'],
          remote_id: params['Id'],
          latitude: params['Latitude'],
          longitude: params['Longitude'],
          name: params['Name'],
          phone: params['Phone'],
          phone_extension: params['PhoneExtension'],
          postal_code: params['PostalCode'],
          remote_site_id: params['SiteID'],
          state_prov_code: params['StateProvCode'],
          total_number_of_ratings: params['TotalNumberOfRatings'],
          average_rating: params['AverageRating'],
          total_number_of_deals: params['TotalNumberOfDeals']
        }
      end

      def site(params)
        params = ActiveSupport::HashWithIndifferentAccess.new(params)
        {
          contact_email: params['ContactEmail'],
          description: params['Description'],
          remote_id: params['Id'],
          logo_url: params['LogoUrl'],
          name: params['Name'],
          page_color_1: params['PageColor1'],
          page_color_2: params['PageColor2'],
          page_color_3: params['PageColor3'],
          page_color_4: params['PageColor4'],
          pricing_level: params['PricingLevel'],
          currency_iso_code: params['CurrencyIsoCode'],
          country_code: params['CountryCode'],
          time_zone: params['TimeZone']
        }
      end

      def staff(params)
        params = ActiveSupport::HashWithIndifferentAccess.new(params)
        {
          address: params['Address'],
          appointment_instructor: params['AppointmentInstructor'],
          always_allow_double_booking: params['AlwaysAllowDoubleBooking'],
          bio: params['Bio'],
          city: params['City'],
          country: params['Country'],
          email: params['Email'],
          first_name: params['FirstName'],
          home_phone: params['HomePhone'],
          remote_id: params['Id'],
          independent_contractor: params['IndependentContractor'],
          is_male: params['IsMale'],
          last_name: params['LastName'],
          mobile_phone: params['MobilePhone'],
          name: params['Name'],
          postal_code: params['PostalCode'],
          class_teacher: params['ClassTeacher'],
          sort_order: params['SortOrder'],
          state: params['State'],
          work_phone: params['WorkPhone'],
          image_url: params['ImageUrl']
        }
      end
    end
  end
end
