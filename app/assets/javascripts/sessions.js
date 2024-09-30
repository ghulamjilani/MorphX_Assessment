//= require cookie
//= require_tree ./templates/sessions
//= require_self

(function() {
  var showAgeRestrictionInfo,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  // TEMPORARY DISABLED MOBILE SESSIONS
  window.mobileDisabledNotification = function() {
    $.showFlashMessage("Mobile app is temporarily disabled", {type: 'error', timeout: 3000});
  };

  window.buyButtonClickedByUnsignedInUser = function(aTag) {
    var href;
    if ($(aTag).hasClass('disabled')) {
      return;
    }
    href = $(aTag).attr('href');
    window.eventHub.$emit("open-modal:auth", "sign-up", {action: "close-and-reload"})
    // $('#loginPopup').modal('show');
    return false;
  };

  window.immersiveServiceFee = function(duration) {
    return (duration / 5 - 2) * 0.1 + 1.5;
  };

  window.livestreamServiceFee = function(duration) {
    return (duration / 5 - 2) * 0.1 + 0.5;
  };

  window.recordedServiceFee = function(duration) {
    return (duration / 5 - 2) * 0.05;
  };

  window.immersiveMinCost = function(duration) {
    if (typeof Immerss.overridenMinimumLiveSessionCost === 'undefined') {
      return (duration / 5 - 2) * 0.5 + 4.99;
    } else {
      return Immerss.overridenMinimumLiveSessionCost;
    }
  };

  window.livestreamMinCost = function(duration) {
    var num;
    if (typeof Immerss.overridenMinimumLiveSessionCost === 'undefined') {
      num = (duration / 5.0 - 2.0) * 0.2 + 2.99;
      return Math.round(num * 100) / 100;
    } else {
      return Immerss.overridenMinimumLiveSessionCost;
    }
  };

  window.recordedMinCost = function(duration) {
    return (duration / 5 - 2) * 0.05 + 0.99;
  };

  $(function() {
    $('body').on('shown.bs.modal', '#invite-co-presenter-modal', function() {
      return window.hideOrDisplayPayForThisUserOptions();
    });
    $('body').on('shown.bs.modal', '.preview-cancel', function() {
      return $(".preview-cancel.modal form").submit(function() {
        var properSelect;
        properSelect = _.last($('select[name*=cancel_reason_id]'));
        if ($(properSelect).val() === '') {
          $.showFlashMessage("Please choose a reason", {
            type: 'error',
            timeout: 3000
          });
          return false;
        } else {
          return true;
        }
      });
    });
    $('select[name*=duration]').on('change', function(event) {
      var newVal;
      if ($(event.target).hasClass('disabled')) {
        return false;
      }
      newVal = $('.tab-pane.active select[name*=duration]').val();
      deliveryMethodsView.model.set({
        duration: newVal
      });
      deliveryMethodsView.readJqueryCostsAndAssignToModel();
      deliveryMethodsView.calcPotentialRevenueAndFees();
      return true;
    });
    return $('#session_adult_true, #session_adult_false').on('click', function(event) {
      if ($(event.target).hasClass('disabled')) {
        return false;
      }
      if (confirm("Are you sure?")) {
        deliveryMethodsView.model.set({
          adult: true
        });
        deliveryMethodsView.readJqueryCostsAndAssignToModel();
        return true;
      } else {
        deliveryMethodsView.model.set({
          adult: false
        });
        deliveryMethodsView.readJqueryCostsAndAssignToModel();
        $(this).removeAttr('checked');
        event.preventDefault();
        return false;
      }
    });
  });

  window.Session = Backbone.Model.extend({
      initialize: function(options){}
  });

  window.DeliveryMethodsView = (function(superClass) {
    extend(DeliveryMethodsView, superClass);

    function DeliveryMethodsView(options) {
      var intervalID;
      if (options == null) {
        options = {};
      }
      this.render = bind(this.render, this);
      this.additionalParametersLinkClicked = bind(this.additionalParametersLinkClicked, this);
      this.afterRender = bind(this.afterRender, this);
      this.checkRenderQueue = bind(this.checkRenderQueue, this);
      this.postponedRender = bind(this.postponedRender, this);
      DeliveryMethodsView.__super__.constructor.apply(this, arguments);
      this.renderQueue = $({});
      this.immersiveServiceFee = 0;
      this.immersiveTotalPurchasePrice = 0;
      this.immersiveMinCost = 0;
      this.immersiveEarningsPerSeat = 0;
      this.livestreamServiceFee = 0;
      this.livestreamTotalPurchasePrice = 0;
      this.livestreamMinCost = 0;
      this.livestreamEarningsPerSeat = 0;
      this.recordedServiceFee = 0;
      this.recordedTotalPurchasePrice = 0;
      this.recordedMinCost = 0;
      this.recordedEarningsPerSeat = 0;
      this.potentialRevenueFrom = 0;
      this.potentialRevenueTo = 0;
      this.approximateLivestreamUsersCount = 0;
      this.approximateVodUsersCount = 0;
      this.lists = options.lists;
      this.model.bind('change:immersive', function() {
        var cb;
        cb = function() {
          return sessionInviteUserModalView.render();
        };
        setTimeout(cb, 40);
        if (!this.get('immersive') && !this.get('livestream')) {
          return this.set({
            "private": false
          });
        }
      });
      this.model.bind('change:livestream', function() {
        var cb;
        cb = function() {
          return sessionInviteUserModalView.render();
        };
        setTimeout(cb, 40);
        if (!this.get('immersive') && !this.get('livestream')) {
          return this.set({
            "private": false
          });
        }
      });
      this.model.bind('change:private', function() {
        if (this.get('private') === true) {
          return this.set({
            livestream_free_trial: false,
            immersive_free_trial: false
          });
        }
      });
      this.model.bind('change:immersive_free_trial', function() {
        if (this.get('immersive_free_trial') === true) {
          this.set({
            immersive_free_trial: false
          });
          if (this.get('immersive')) {
            return this.set({
              immersive_free_slots: 1
            });
          }
        } else {
          return this.set({
            immersive_free_slots: null
          });
        }
      });
      this.model.bind('change:livestream_free_trial', function() {
        if (this.get('livestream_free_trial') === true) {
          this.set({
            livestream_free_trial: false
          });
          if (this.get('livestream')) {
            return this.set({
              livestream_free_slots: 1
            });
          }
        } else {
          return this.set({
            livestream_free_slots: null
          });
        }
      });
      this.model.bind('change:immersive_free', function() {
        if (this.get('immersive_free') !== true) {
          return;
        }
        this.set({
          immersive_free_trial: false
        });
        this.set({
          immersive_type: 'group'
        });
        if (this.get('can_create_free_private_sessions_without_permission') === false) {
          this.set({
            "private": false
          });
        }
        $('input[name*=paid_by_organizer_user]').attr('checked', false);
        $('input[name*=paid_by_organizer_user]').attr('disabled', true);
        if (this.get('immersive')) {
          this.set({
            immersive_access_cost: 0.0
          });
        }
        return this.set({
          immersive_free_slots: null
        });
      });
      this.model.bind('change:livestream_free', function() {
        if (this.get('livestream_free') !== true) {
          return;
        }
        this.set({
          livestream_free_trial: false
        });
        if (this.get('can_create_free_private_sessions_without_permission') === false) {
          this.set({
            "private": false
          });
        }
        $('input[name*=paid_by_organizer_user]').attr('checked', false);
        $('input[name*=paid_by_organizer_user]').attr('disabled', true);
        if (this.get('livestream')) {
          this.set({
            livestream_access_cost: 0.0
          });
        }
        return this.set({
          livestream_free_slots: null
        });
      });
      this.model.bind('change:recorded_free', function() {
        if (this.get('recorded_free') !== true) {
          return;
        }
        if (this.get('can_create_free_private_sessions_without_permission') === false) {
          this.set({
            "private": false
          });
        }
        $('input[name*=paid_by_organizer_user]').attr('checked', false);
        $('input[name*=paid_by_organizer_user]').attr('disabled', true);
        if (this.get('record')) {
          return this.set({
            recorded_access_cost: 0.0
          });
        }
      });
      this.model.bind('change:max_number_of_immersive_participants', function() {
        if (this.get('max_number_of_immersive_participants') === '1' || this.get('max_number_of_immersive_participants') === 1) {
          this.set({
            immersive_type: Immerss.oneOnOneType
          });
          this.set({
            livestream: 0,
            livestream_free: false,
            livestream_access_cost: null
          });
          return this.set({
            immersive_free: false
          });
        } else {
          return this.set({
            immersive_type: Immerss.groupType
          });
        }
      });
      this.model.on('change', (function(_this) {
        return function() {
          return setTimeout(_this.postponedRender, 20);
        };
      })(this));
      setTimeout(function() {
        return window.scrollTo1stValidationErrorIfPresent();
      }, 100);
      intervalID = setInterval(this.checkRenderQueue, 20);
      this.render = _.wrap(this.render, (function(_this) {
        return function(render) {
          render();
          return _this;
        };
      })(this));
    }

    DeliveryMethodsView.prototype.template = function(data) {
      var template;
      template = _.template(HandlebarsTemplates['sessions/delivery_methods'](data));
      return template.apply(this, arguments);
    };

    DeliveryMethodsView.prototype.tagName = 'div';

    DeliveryMethodsView.prototype.el = '#delivery-methods-placeholder';

    DeliveryMethodsView.prototype.postponedRender = function() {
      this.renderQueue.queue('update', function(next) {});
      return this.renderQueue.queue('update').length;
    };

    DeliveryMethodsView.prototype.checkRenderQueue = function() {
      if (this.renderQueue.queue('update').length > 0) {
        this.renderQueue.clearQueue('update');
        return this.render();
      }
    };

    DeliveryMethodsView.prototype.events = {
      "click #session_immersive": "sessionImmersiveCheckboxClicked",
      "click #session_livestream": "sessionLivestreamCheckboxClicked",
      "click #session_record": "sessionRecordCheckboxClicked",
      "change #livestream_free_trial": "livestreamFreeTrialChanged",
      "change #immersive_free_trial": "immersiveFreeTrialChanged",
      "change #session_private": "privateClicked",
      "change #session_public": "publicClicked",
      "change #session_min_number_of_immersive_and_livestream_participants": "minNumberOfParticipantsChanged",
      "change [name='session[max_number_of_immersive_participants]']": "maxNumberOfParticipantsChanged",
      "change [name='session[immersive_free_slots]']": "immersiveFreeSlotsChanged",
      "change [name='session[livestream_free_slots]']": "livestreamFreeSlotsChanged",
      "click #additional_parameters_link": "additionalParametersLinkClicked",
      "keyup input[type=number]": "calcPotentialRevenueAndFees",
      "change select, input[type=number]": "calcPotentialRevenueAndFees",
      "keyup #session_immersive_access_cost, #session_livestream_access_cost, #session_recorded_access_cost": "calcPotentialRevenueAndFees",
      "change #session_immersive_access_cost": "readJqueryCostsAndAssignToModel",
      "change #session_livestream_access_cost": "readJqueryCostsAndAssignToModel",
      "change #session_recorded_access_cost": "readJqueryCostsAndAssignToModel",
      "[name='session[record]'], [name='session[livestream]'], [name='session[immersive]']": "calcPotentialRevenue",
      "change #immersive_price_type_input input[name='session[immersive_free]']": "immersivePriceTypeChanged",
      "change #livestream_price_type_input input[name='session[livestream_free]']": "livestreamPriceTypeChanged",
      "change #record_price_type_input input[name='session[recorded_free]']": "recordPriceTypeChanged",
      "click  .service_type_href": "serviceTypeUpdate"
    };

    DeliveryMethodsView.prototype.immersivePriceTypeChanged = function(e) {
      if ($(e.target).val() === 'true') {
        this.model.set({
          immersive_access_cost: 0.0
        });
        this.model.set({
          immersive_free: true
        });
        if (this.model.get('max_number_of_immersive_participants') === '1' || this.model.get('max_number_of_immersive_participants') === 1) {
          this.model.set({
            max_number_of_immersive_participants: this.model.get('immersive_participants_count') || 2
          });
          this.model.set({
            immersive_type: Immerss.groupType
          });
        }
      } else {
        this.model.set({
          immersive_access_cost: immersiveMinCost(this.model.get('duration')).toFixed(2)
        });
        this.model.set({
          immersive_free: false
        });
      }
    };

    DeliveryMethodsView.prototype.livestreamPriceTypeChanged = function(e) {
      if ($(e.target).val() === 'true') {
        this.model.set({
          livestream_access_cost: 0.0
        });
        this.model.set({
          livestream_free: true
        });
      } else {
        this.model.set({
          livestream_access_cost: livestreamMinCost(this.model.get('duration')).toFixed(2)
        });
        this.model.set({
          livestream_free: false
        });
      }
    };

    DeliveryMethodsView.prototype.recordPriceTypeChanged = function(e) {
      if ($(e.target).val() === 'true') {
        this.model.set({
          recorded_access_cost: 0.0
        });
        this.model.set({
          recorded_free: true
        });
      } else {
        this.model.set({
          recorded_access_cost: recordedMinCost(this.model.get('duration')).toFixed(2)
        });
        this.model.set({
          recorded_free: false
        });
      }
    };

    DeliveryMethodsView.prototype.serviceTypeUpdate = function(e) {
      var $current;
      e.preventDefault();
      $current = $(e.target).parent('a');
      if (!$current.hasClass("active")) {
        $(".service_type_href").removeClass("active");
        $current.addClass("active");
        if ($current.hasClass("rtmp")) {
          this.model.set({
            service_type: 'rtmp'
          });
        } else {
          this.model.set({
            service_type: 'webrtcservice'
          });
        }
      }
    };

    DeliveryMethodsView.prototype.afterRender = function() {
      var first_case, isFreeAndCanPublishInstantly, label, legend, model, participantSection, status;
      alert('1');
      $('#users-record-num, #users-livestream-num').spinner({
        stop: function(event, ui) {
          return $(this).change();
        }
      });
      participantSection = $('.custom-input.users');
      if (participantSection.length !== 1) {
        throw new Error('can not find Participants section');
      }
      if (!this.model.get('immersive') && !this.model.get('livestream')) {
        $('input[name*=invited_par]').remove();
        participantSection.hide();
      } else {
        participantSection.show();
      }
      if (this.model.get('max_number_of_immersive_participants') === '1' || this.model.get('max_number_of_immersive_participants') === 1) {
        $('input[name*=invited_co_prese]').remove();
        this.model.set({
          immersive_type: Immerss.oneOnOneType
        });
      }
      if ($('#session_livestream').prop('checked')) {
        $('.steamDevice').show();
      } else {
        $('.steamDevice').hide();
      }
      legend = Immerss.freePrivateSessionsWithoutAdminApprovalLeftCount === 0 && this.model.get('livestream_free') && !this.model.get('requested_free_session_satisfied_at') || this.model.get('immersive_free') && !this.model.get('requested_free_session_satisfied_at') ? I18n.t('sessions.form.publish_immediately_after_admin_approval') : this.model.get('id') === null ? I18n.t('sessions.form.publish_publicaly_immediately_after_creation') + ' <i class="VideoClientIcon-q5 text-color-Blue" rel="tipsy" title="We recommend you leave this box checked to ensure your session is searchable to the public. If your not ready to go public dont worry you can always adjust your content and publish later."></i>' : I18n.t('sessions.form.publish_immediately_after_submitting') + ' <i class="icon-help-circled text-color-Blue" rel="tipsy" title="We recommend you leave this box checked to ensure your session is searchable to the public. If your not ready to go public dont worry you can always adjust your content and publish later."></i>';
      $('#publish_after_requested_free_session_is_satisfied_by_admin_legend').html(legend);
      isFreeAndCanPublishInstantly = this.model.get('private') === false || this.model.get('private') === true && (Immerss.canCreateFreePrivateSessionsWithoutPermission === true || Immerss.freePrivateSessionsWithoutAdminApprovalLeftCount > 0);
      first_case = (this.model.get('livestream_free') || this.model.get('immersive_free')) && this.model.get('status') !== 'published' && this.model.get('status') !== 'requested_free_session_approved';
      if (first_case && isFreeAndCanPublishInstantly === false) {
        $('input[name*=publish_after_requested_free_session_is_satisfied_by_admin]').parents('.control-group:first').show();
      } else {
        $('input[name*=publish_after_requested_free_session_is_satisfied_by_admin]').parents('.control-group:first').hide();
      }
      status = this.model.get('status');
      $('button[data-form=session_form]').html('').hide();
      if (!isFreeAndCanPublishInstantly && (this.model.get('livestream_free') || this.model.get('immersive_free')) && status !== 'requested_free_session_pending' && status !== 'requested_free_session_approved' && status !== 'requested_free_session_rejected') {
        $('button[data-form=session_form]').html('Submit for Approval').show();
      } else if (status === 'published' || status === 'requested_free_session_pending') {
        $('button[data-form=session_form]').html('Update Session').show();
      } else if (this.model.get('belongs_to_listed_channel') === true) {
        label = (function() {
          if (this.model.get('private') === true) {
            if ($('body.sessions-edit').length === 0) {
              return 'Create Private Session';
            } else {
              return 'Update Private Session';
            }
          } else if (this.model.get('private') === false) {
            if ($('body.sessions-edit').length === 0) {
              return 'Create Session';
            } else {
              return 'Update Session';
            }
          } else {
            throw new Error('can not interpret private status - ' + this.model.get('private'));
          }
        }).call(this);
        $('button[data-form=session_form]').html(label);
        $('button[data-form=session_form]').show();
      } else if (this.model.get('belongs_to_listed_channel') === false) {
        if (this.model.get('private') === false) {
          $('button[data-form=session_form]').html('Create Session').show();
        } else if (this.model.get('private') === true) {
          $('.orBlock').show();
          label = $('body.sessions-edit').length === 0 ? 'Create Private Session' : 'Update Private Session';
          $('button[data-form=session_form]').html(label).removeAttr('disabled').removeClass('disabled');
          $('button[data-form=session_form]').show();
        } else {
          throw new Error('can not interpret private status - ' + this.model.get('private'));
        }
      }
      $('button[data-form=session_form]').click(function(event) {
        var actual;
        actual = $(event.target).html();
        if (actual === 'Create Private Session' || actual === 'Create Session' || actual === 'Update Private Session' || actual === 'Update Session' || actual === 'Submit for Approval') {
          status = 'published';
        } else {
          throw new Error('can not interpret button title - ' + actual);
        }
        $('form.formtastic.session').find("input[name='clicked_button_type']").remove();
        $('form.formtastic.session').append("<input type='hidden' name='clicked_button_type' value='" + status + "'>");
        return true;
      });
      $('.row-buttons').show();
      $('select.styled-select, select[name*=duration], #session_start_at_4i, #session_start_at_5i, #session_pre_time, #session_min_number_of_immersive_and_livestream_participants').select2({
        minimumResultsForSearch: -1
      });
      if (this.model.get('can_change_immersive_access_cost') === false || this.model.get('immersive_free') === true) {
        this.$('#session_immersive_access_cost').spinner({
          disabled: true
        });
      } else {
        model = this.model;
        this.$('#session_immersive_access_cost').spinner({
          min: immersiveMinCost(model.get('duration')).toFixed(2),
          max: Immerss.maxGroupImmersiveSessionAccessCost,
          step: 0.5,
          numberFormat: "C",
          culture: "en-US",
          spin: function(event, ui) {
            return setTimeout(function() {
              return model.set({
                immersive_access_cost: $('#session_immersive_access_cost').val()
              });
            }, 20);
          }
        });
      }
      if (this.model.get('can_change_livestream_access_cost') === false || this.model.get('livestream_free') === true) {
        this.$("#session_livestream_access_cost").spinner({
          disabled: true
        });
      } else {
        model = this.model;
        this.$("#session_livestream_access_cost").spinner({
          min: livestreamMinCost(model.get('duration')).toFixed(2),
          max: Immerss.maxLivestreamSessionAccessCost,
          step: 0.2,
          numberFormat: 'C',
          culture: 'en-US',
          spin: function(event, ui) {
            return setTimeout(function() {
              return model.set({
                livestream_access_cost: $('#session_livestream_access_cost').val()
              });
            }, 20);
          }
        });
      }
      if (this.model.get('can_change_recorded_access_cost') === false || this.model.get('recorded_free') === true) {
        return this.$('#session_recorded_access_cost').spinner({
          disabled: true
        });
      } else {
        model = this.model;
        return this.$('#session_recorded_access_cost').spinner({
          min: recordedMinCost(model.get('duration')).toFixed(2),
          max: Immerss.maxRecordedSessionAccessCost,
          step: 0.5,
          numberFormat: 'C',
          culture: 'en-US',
          spin: function(event, ui) {
            return setTimeout(function() {
              return model.set({
                recorded_access_cost: $('#session_recorded_access_cost').val()
              });
            }, 20);
          }
        });
      }
    };

    DeliveryMethodsView.prototype.readJqueryCostsAndAssignToModel = function() {
      return $.each(['immersive', 'livestream', 'recorded'], (function(_this) {
        return function(_i, type) {
          var inputElement;
          inputElement = $("input[name*='" + type + "_access_cost']");
          return _this.model.set(type + "_access_cost", inputElement.val());
        };
      })(this));
    };

    DeliveryMethodsView.prototype.additionalParametersLinkClicked = function(event) {
      if (this.model.get('additional_parameters_link_class') === 'opened') {
        return this.model.set('additional_parameters_link_class', 'closed');
      } else {
        return this.model.set('additional_parameters_link_class', 'opened');
      }
    };

    DeliveryMethodsView.prototype.livestreamFreeTrialChanged = function(e) {
      if ($(e.target).hasClass('disabled')) {
        return false;
      }
      return this.model.set({
        livestream_free_trial: $(e.target).is(':checked')
      });
    };

    DeliveryMethodsView.prototype.immersiveFreeTrialChanged = function(e) {
      if ($(e.target).hasClass('disabled')) {
        return false;
      }
      return this.model.set({
        immersive_free_trial: $(e.target).is(':checked')
      });
    };

    DeliveryMethodsView.prototype.privateClicked = function(e) {
      if ($(e.target).hasClass('disabled')) {
        return false;
      }
      this.model.set({
        "private": true
      });
      return this.readJqueryCostsAndAssignToModel();
    };

    DeliveryMethodsView.prototype.publicClicked = function(e) {
      this.model.set({
        "private": false
      });
      return this.readJqueryCostsAndAssignToModel();
    };

    DeliveryMethodsView.prototype.sessionImmersiveCheckboxClicked = function(event) {
      if ($(event.target).hasClass('disabled')) {
        return false;
      }
      this.readJqueryCostsAndAssignToModel();
      if ($('#session_immersive').prop('checked')) {
        this.model.set({
          immersive: true,
          immersive_free: true
        });
        if (this.model.get('immersive_type') == null) {
          this.model.set({
            immersive_type: Immerss.groupType
          });
        }
        if (this.model.get('min_number_of_immersive_and_livestream_participants') == null) {
          this.model.set({
            min_number_of_immersive_and_livestream_participants: 1
          });
        }
        if (!this.model.get('max_number_of_immersive_participants')) {
          return this.model.set({
            max_number_of_immersive_participants: this.model.get('max_number_of_immersive_participants_with_sources')
          });
        }
      } else {
        this.model.set({
          immersive: false,
          immersive_free: false,
          immersive_access_cost: null
        });
        if (!this.model.get('livestream')) {
          this.model.set({
            min_number_of_immersive_and_livestream_participants: null
          });
        }
        return this.model.set({
          max_number_of_immersive_participants: null
        });
      }
    };

    DeliveryMethodsView.prototype.sessionLivestreamCheckboxClicked = function(event) {
      if ($(event.target).hasClass('disabled')) {
        return false;
      }
      this.readJqueryCostsAndAssignToModel();
      if ($('#session_livestream').prop('checked')) {
        this.model.set({
          livestream: true,
          livestream_free: true
        });
        if (this.model.get('min_number_of_immersive_and_livestream_participants') == null) {
          this.model.set({
            min_number_of_immersive_and_livestream_participants: 1
          });
        }
      } else {
        this.model.set({
          livestream: false,
          livestream_free: false,
          livestream_access_cost: null
        });
      }
      return this.model.set({
        service_type: 'webrtcservice'
      });
    };

    DeliveryMethodsView.prototype.sessionRecordCheckboxClicked = function(event) {
      if ($(event.target).hasClass('disabled')) {
        return false;
      }
      this.readJqueryCostsAndAssignToModel();
      if ($('#session_record').prop('checked')) {
        return this.model.set({
          record: true,
          recorded_free: true
        });
      } else {
        return this.model.set({
          record: false,
          recorded_free: false,
          recorded_access_cost: null
        });
      }
    };

    DeliveryMethodsView.prototype.minNumberOfParticipantsChanged = function(event) {
      this.model.set({
        min_number_of_immersive_and_livestream_participants: $(event.target).val()
      });
      return this.readJqueryCostsAndAssignToModel();
    };

    DeliveryMethodsView.prototype.maxNumberOfParticipantsChanged = function() {
      this.model.set({
        max_number_of_immersive_participants: $("[name='session[max_number_of_immersive_participants]']").val()
      });
      $("input[name='session[immersive_access_cost]']").val(immersiveMinCost(this.model.get('duration')).toFixed(2));
      this.readJqueryCostsAndAssignToModel();
      return this.syncParticipantsListSection();
    };

    DeliveryMethodsView.prototype.immersiveFreeSlotsChanged = function() {
      this.model.set({
        immersive_free_slots: $("[name='session[immersive_free_slots]']").val()
      });
      return this.readJqueryCostsAndAssignToModel();
    };

    DeliveryMethodsView.prototype.livestreamFreeSlotsChanged = function() {
      this.model.set({
        livestream_free_slots: $("[name='session[livestream_free_slots]']").val()
      });
      return this.readJqueryCostsAndAssignToModel();
    };

    DeliveryMethodsView.prototype.render = function() {
      var data;
      data = this.model.toJSON();
      data.serviceTypeRtmp = data.service_type === "rtmp";
      data.immersiveServiceFee = this.immersiveServiceFee;
      data.immersiveMinCost = this.immersiveMinCost;
      data.immersiveTotalPurchasePrice = this.immersiveTotalPurchasePrice;
      data.immersiveEarningsPerSeat = this.immersiveEarningsPerSea;
      data.livestreamServiceFee = this.livestreamServiceFee;
      data.livestreamMinCost = this.livestreamMinCost;
      data.livestreamTotalPurchasePrice = this.livestreamTotalPurchasePrice;
      data.livestreamEarningsPerSeat = this.livestreamEarningsPerSeat;
      data.recordedServiceFee = this.recordedServiceFee;
      data.recordedMinCost = this.recordedMinCost;
      data.recordedTotalPurchasePrice = this.recordedTotalPurchasePrice;
      data.recordedEarningsPerSeat = this.recordedEarningsPerSeat;
      data.potentialRevenueFrom = this.potentialRevenueFrom;
      data.potentialRevenueTo = this.potentialRevenueTo;
      data.approximateLivestreamUsersCount = this.approximateLivestreamUsersCount;
      data.approximateVodUsersCount = this.approximateVodUsersCount;
      data.hideLivestreamFreeTrialBlock = !data.livestream || data.livestream_free || !data.livestream_free_trial || data["private"];
      data.hideImmersiveFreeTrialBlock = !data.immersive || data.immersive_free || !data.immersive_free_trial || data["private"];
      data.lists = this.lists;
      data.Immerss = Immerss;
      this.$el.html(this.template(data));
      this.calcPotentialRevenueAndFees();
      this.syncParticipantsListSection();
      $(window).trigger("scroll");
      return this.afterRender();
    };

    DeliveryMethodsView.prototype.toggleCalcAdditionalFields = function() {
      this.$(".livestream-users-num, .record-users-num").hide();
      if (this.$("[name='session[livestream]']").is(":checked")) {
        if (!$('#session_livestream').hasClass('disabled')) {
          this.$(".livestream-users-num").show();
        }
        this.approximateLivestreamUsersCount = parseInt(this.$('#users-livestream-num').val()) || 0;
      } else {
        this.approximateLivestreamUsersCount = 0;
      }
      if (this.$("[name='session[record]']").is(":checked")) {
        if (!$('#session_record').hasClass('disabled')) {
          this.$(".record-users-num").show();
        }
        return this.approximateVodUsersCount = parseInt(this.$("#users-record-num").val()) || 0;
      } else {
        return this.approximateVodUsersCount = 0;
      }
    };

    DeliveryMethodsView.prototype.syncParticipantsListSection = function() {
      var section;
      section = $('.custom-input.users');
      if (section.length !== 1) {
        throw new Error('can not find Users section');
      }
      if ($('input[name*=immersive][type=checkbox]').is(':checked') || $('input[name*=livestream][type=checkbox]').is(':checked')) {
        return section.show();
      } else {
        $('input[name*=invited_participants]').remove();
        return section.hide();
      }
    };

    DeliveryMethodsView.prototype.calcServiceFeesAndTotalPurchasePrices = function() {
      return _.defer((function(_this) {
        return function() {
          var duration, immersiveCost, livestreamCost, recordedCost;
          immersiveCost = parseFloat(_this.$("[name='session[immersive_access_cost]']").val()) || 0;
          livestreamCost = parseFloat(_this.$("[name='session[livestream_access_cost]']").val()) || 0;
          recordedCost = parseFloat(_this.$("[name='session[recorded_access_cost]']").val()) || 0;
          _this.immersiveServiceFee = 0.0;
          _this.livestreamServiceFee = 0.0;
          _this.recordedServiceFee = 0.0;
          _this.immersiveTotalPurchasePrice = 0.0;
          _this.livestreamTotalPurchasePrice = 0.0;
          _this.recordedTotalPurchasePrice = 0.0;
          duration = parseInt($('.tab-pane.active select[name*=duration]').val(), 10);
          if (_this.$("[name='session[immersive]']").is(":checked") && immersiveCost > 0) {
            _this.immersiveServiceFee = immersiveServiceFee(duration);
            _this.immersiveTotalPurchasePrice = immersiveCost + _this.immersiveServiceFee;
          }
          if (_this.$("[name='session[livestream]']").is(":checked") && livestreamCost > 0) {
            _this.livestreamServiceFee = livestreamServiceFee(duration);
            _this.livestreamTotalPurchasePrice = livestreamCost + _this.livestreamServiceFee;
          }
          if (_this.$("[name='session[record]']").is(":checked") && recordedCost > 0) {
            _this.recordedServiceFee = recordedServiceFee(duration);
            _this.recordedTotalPurchasePrice = recordedCost + _this.recordedServiceFee;
          }
          _this.immersiveMinCost = immersiveMinCost(duration);
          _this.livestreamMinCost = livestreamMinCost(duration);
          _this.recordedMinCost = recordedMinCost(duration);
          _this.immersiveEarningsPerSeat = immersiveCost * Immerss.revenueSplitMultiplier;
          if (_this.immersiveEarningsPerSeat < 0) {
            _this.immersiveEarningsPerSeat = 0.0;
          }
          _this.livestreamEarningsPerSeat = livestreamCost * Immerss.revenueSplitMultiplier;
          if (_this.livestreamEarningsPerSeat < 0) {
            _this.livestreamEarningsPerSeat = 0.0;
          }
          _this.recordedEarningsPerSeat = recordedCost * Immerss.revenueSplitMultiplier;
          $("#immersive-service-fee").text("$" + (_this.immersiveServiceFee.toFixed(2)));
          $("#immersive-total-purchase-price").text("$" + (_this.immersiveTotalPurchasePrice.toFixed(2)));
          $("#immersive-min-cost").text("$" + (_this.immersiveMinCost.toFixed(2)));
          $("#immersive-earnings-per-seat").text("$" + (_this.immersiveEarningsPerSeat.toFixed(2)));
          $("#livestream-service-fee").text("$" + (_this.livestreamServiceFee.toFixed(2)));
          $("#livestream-total-purchase-price").text("$" + (_this.livestreamTotalPurchasePrice.toFixed(2)));
          $("#livestream-min-cost").text("$" + (_this.livestreamMinCost.toFixed(2)));
          $("#livestream-earnings-per-seat").text("$" + (_this.livestreamEarningsPerSeat.toFixed(2)));
          $("#recorded-service-fee").text("$" + (_this.recordedServiceFee.toFixed(2)));
          $("#recorded-total-purchase-price").text("$" + (_this.recordedTotalPurchasePrice.toFixed(2)));
          $("#recorded-min-cost").text("$" + (_this.recordedMinCost.toFixed(2)));
          return $("#recorded-earnings-per-seat").text("$" + (_this.recordedEarningsPerSeat.toFixed(2)));
        };
      })(this));
    };

    DeliveryMethodsView.prototype.calcPotentialRevenueAndFees = function() {
      this.calcServiceFeesAndTotalPurchasePrices();
      return this.calcPotentialRevenue();
    };

    DeliveryMethodsView.prototype.calcPotentialRevenue = function() {
      this.toggleCalcAdditionalFields();
      return _.defer((function(_this) {
        return function() {
          var amount, immersiveCost, livestreamCost, maxUsersNum, minNumberField, minUsersNum, newValue1, newValue2, recordedCost, sessionType, was1, was2;
          immersiveCost = parseFloat(_this.$("[name='session[immersive_access_cost]']").val()) || 0;
          livestreamCost = parseFloat(_this.$("[name='session[livestream_access_cost]']").val()) || 0;
          recordedCost = parseFloat(_this.$("[name='session[recorded_access_cost]']").val()) || 0;
          _this.potentialRevenueFrom = 0.0;
          _this.potentialRevenueTo = 0.0;
          if (_this.$("[name='session[immersive]']").is(":checked") && immersiveCost > 0) {
            sessionType = _this.$("[name='session[max_number_of_immersive_participants]']").val();
            if (sessionType > 1) {
              _this.model.set({
                immersive_type: Immerss.groupType
              });
              minNumberField = $("[name='session[min_number_of_immersive_and_livestream_participants]']");
              if (minNumberField.length !== 1) {
                throw new Error('can not find min number of participants field');
              }
              minUsersNum = parseInt(minNumberField.val());
              maxUsersNum = parseInt(_this.$("[name='session[max_number_of_immersive_participants]']").val());
              _this.potentialRevenueFrom += immersiveCost * minUsersNum * Immerss.revenueSplitMultiplier;
              _this.potentialRevenueTo += immersiveCost * maxUsersNum * Immerss.revenueSplitMultiplier;
            } else {
              _this.model.set({
                immersive_type: Immerss.oneOnOneType
              });
              _this.potentialRevenueFrom += _this.potentialRevenueTo = immersiveCost * 1 * Immerss.revenueSplitMultiplier;
            }
          }
          if (_this.$("[name='session[livestream]']").is(":checked") && livestreamCost > 0) {
            amount = livestreamCost * _this.approximateLivestreamUsersCount * Immerss.revenueSplitMultiplier;
            _this.potentialRevenueFrom += amount;
            _this.potentialRevenueTo += amount;
          }
          if (_this.$("[name='session[record]']").is(":checked") && recordedCost > 0) {
            _this.potentialRevenueFrom += (recordedCost * _this.approximateVodUsersCount) * Immerss.revenueSplitMultiplier;
            _this.potentialRevenueTo += (recordedCost * _this.approximateVodUsersCount) * Immerss.revenueSplitMultiplier;
          }
          was1 = $("#revenue-from").text();
          was2 = $("#revenue-to").text();
          newValue1 = "$" + (_this.potentialRevenueFrom.toFixed(2));
          newValue2 = "$" + (_this.potentialRevenueTo.toFixed(2));
          if (_this.potentialRevenueFrom >= 0) {
            $("#revenue-from").text(newValue1);
            return $("#revenue-to").text(newValue2);
          } else {
            $("#revenue-from").text("$0.00");
            return $("#revenue-to").text("$0.00");
          }
        };
      })(this));
    };

    return DeliveryMethodsView;

  })(Backbone.View);

  $(document).on('click', '.addUserToContacts', function(event) {
    var $checkbox;
    event.preventDefault();
    $checkbox = $(this);
    $checkbox.prop('checked', true);
    return $.ajax({
      url: $(this).data('url'),
      type: 'POST',
      dataType: 'html',
      error: function(jqXHR, textStatus, errorThrown) {
        return $checkbox.prop('checked', false);
      },
      success: function(data, textStatus, jqXHR) {
        $checkbox.parents('.addToContacts').slideUp();
        return setTimeout((function() {
          $checkbox.parents('.friend_input_content').remove();
        }), 500);
      }
    });
  });

  showAgeRestrictionInfo = function() {
    var $container, active;
    $container = $('#session_age_restrictions_input').parent();
    active = $container.find('input:checked').next('span').attr('class');
    $container.find('.info').hide();
    return $container.find('.info.' + active).show();
  };

  $('#session_age_restrictions_input input[type=radio]').on('change', function() {
    return showAgeRestrictionInfo();
  });

  showAgeRestrictionInfo();

  $('#session_adult_input input').on('change', function(e) {
    if ($(e.target).is(':checked')) {
      $('#session_age_restrictions_input #session_age_restrictions_0').attr('disabled', 'disabled');
      if ($('#session_age_restrictions_input #session_age_restrictions_0').is(':checked')) {
        $('#session_age_restrictions_input #session_age_restrictions_0').removeAttr('checked');
        return $('#session_age_restrictions_input #session_age_restrictions_1').attr('checked', true);
      }
    } else {
      return $('#session_age_restrictions_input #session_age_restrictions_0').removeAttr('disabled');
    }
  });

  $(document).ready(function() {
    $('a.add_answer').on('click', function(e) {
      e.preventDefault();
      return $('.poll-fields ol').append("<li class=\"controls\"><input type=\"text\" name=\"session[poll][sides][][answer]\"><a class='remove_answer btn-red btn-withIcon ml20'><i class=\"GlobalIcon-clear\"></i>Remove</a></li>");
    });
    $('.poll-fields').delegate('a.remove_answer', 'click', function(e) {
      e.preventDefault();
      return $(this).closest('.controls').remove();
    });
    $('a[data-toggle=tab][aria-controls=schedule]').on('shown.bs.tab', function(e) {
      $("input[name='session[start_now]']").val('false');
      $("#start_now select[name='session[duration]']").attr('disabled', true);
      return $("#schedule select[name='session[duration]']").removeAttr('disabled');
    });
    return $('a[data-toggle=tab][aria-controls=start_now]').on('shown.bs.tab', function(e) {
      $("input[name='session[start_now]']").val('true');
      $("#start_now select[name='session[duration]']").removeAttr('disabled');
      $("#schedule select[name='session[duration]']").attr('disabled', true);
      return $("select[name='session[duration]']:disabled").trigger('change');
    });
  });

}).call(this);
