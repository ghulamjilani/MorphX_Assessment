(function() {
  window.SessionBuyAndPurchaseOptionsView = Backbone.View.extend({
    initialize: function(options) {
      if (options == null) {
        options = {};
      }
      this.data = options.data;
      this.buy_button_label = this.isFree() ? 'Enroll' : 'Buy';
      return this;
    },
    events: {
      'click .SI-bi-Immersive [type=radio]': 'liveCheckboxClicked',
      'click .SI-bi-Livestream [type=radio]': 'liveCheckboxClicked'
    },
    checkFirstBuyMethodIfAvailable: function() {
      var availableCheckboxes;
      availableCheckboxes = this.$('label.radio.choice > input[type=radio]:not(:disabled)');
      if (availableCheckboxes.length === 1) {
        return availableCheckboxes[0].click();
      }
    },
    activateSubmitPaymentButton: function() {
      return this.$('.submit-payment').single().removeClass('disabled').show().css('visibility', 'visible');
    },
    liveCheckboxClicked: function(e) {
      var totalCost;
      $.each(this.$('label.radio.choice > input[type=radio]'), function() {
        if ($(e.target)[0] === $(this)[0]) {
          return $(this).prop('checked', true);
        } else {
          return $(this).prop('checked', false);
        }
      });
      totalCost = this.$('input[data-cost]:checked').single().data('cost');
      this.buy_button_label = totalCost === 0 ? 'Enroll' : 'Buy';
      this.obtain_type = this.$('input[data-cost]:checked').single().data('type');
      this.render();
      $('#' + $(e.target).attr('id')).single().prop('checked', true);
      if ($(e.target).data('type').indexOf('immersive') !== -1) {
        this.$('.SI-bi-main-Tittle .default_title').hide();
        if ($(e.target).data('free-trial')) {
          this.$('.availableCounter.immersive.free_trial').single().show();
        } else {
          this.$('.availableCounter.immersive.regular').single().show();
        }
      } else if ($(e.target).data('type').indexOf('livestream') !== -1 && $(e.target).data('free-trial')) {
        this.$('.SI-bi-main-Tittle .default_title').hide();
        this.$('.availableCounter.livestream.free_trial').single().show();
      } else {
        this.$('.SI-bi-main-Tittle .default_title').show();
      }
      return this.activateSubmitPaymentButton();
    },
    template: function(data) {
      var template;
      template = _.template(HandlebarsTemplates['application/session_buy_and_purchase_options'](data));
      return template.apply(this, arguments);
    },
    render: function() {
      var templateData;
      templateData = this.data;
      templateData.buy_button_label = this.buy_button_label;
      templateData.obtain_type = this.obtain_type;
      templateData.user_is_signed_in = !!Immerss.currentUserId;
      templateData.change_participation_type = false;
      templateData.could_not_be_obtained = !this.data['immersive_can_have_free_trial'] && !this.data['immersive_can_take_for_free'] && !this.data['immersive_could_be_purchased'] && !this.data['livestream_could_be_purchased'] && !this.data['livestream_can_take_for_free'] && !this.data['livestream_can_have_free_trial'];
      return this.$el.html(this.template(templateData));
    },
    isFree: function() {
      return this.data.livestream_purchase_price === '0.0' && this.data.immersive_purchase_price === '0.0' || this.data.livestream_purchase_price === null && this.data.immersive_purchase_price === '0.0' || this.data.livestream_purchase_price === '0.0' && this.data.immersive_purchase_price === null || this.data.livestream_can_have_free_trial && this.data.immersive_can_have_free_trial || this.data.livestream_purchase_price === null && this.data.immersive_can_have_free_trial || this.data.livestream_can_have_free_trial && this.data.immersive_purchase_price === null || this.data.livestream_can_have_free_trial && this.data.immersive_sold_out;
    }
  });

}).call(this);
