(function() {
  Handlebars.registerHelper({
    eq: function(v1, v2) {
      return v1 == v2;
    },
    ne: function(v1, v2) {
      return v1 != v2;
    },
    lt: function(v1, v2) {
      return v1 < v2;
    },
    gt: function(v1, v2) {
      return v1 > v2;
    },
    lte: function(v1, v2) {
      return v1 <= v2;
    },
    gte: function(v1, v2) {
      return v1 >= v2;
    },
    and: function(v1, v2) {
      return v1 && v2;
    },
    or: function(v1, v2) {
      return v1 || v2;
    },
    not: function(v1) {
      return !v1;
    },
    inArray: function(v1, v2) {
      return _.contains(v1, v2 * 1);
    },
    length: function(v1) {
      if (v1) {
        return v1.length;
      } else {
        return 0;
      }
    }
  });

  Handlebars.registerHelper('ifCond', function(v1, operator, v2, options) {
    switch (operator) {
      case '==':
        if (v1 === v2) {
          return options.fn(this);
        } else {
          return options.inverse(this);
        }
      case '!=':
        if (v1 !== v2) {
          return options.fn(this);
        } else {
          return options.inverse(this);
        }
      case '>=':
        if (v1 >= v2) {
          return options.fn(this);
        } else {
          return options.inverse(this);
        }
      case '>':
        if (v1 > v2) {
          return options.fn(this);
        } else {
          return options.inverse(this);
        }
      default:
        return options.inverse(this);
    }
  });

  Handlebars.registerHelper("i18n", function(str, options) {
    var params;
    params = options.hash;
    if (typeof I18n !== "undefined" && I18n !== null) {
      return I18n.t(str, params);
    } else {
      return str;
    }
  });

  Handlebars.registerHelper("monthsOptions", function(selected) {
    var list, result;
    list = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
    result = "";
    $.each(list, function(index, value) {
      var is_selected;
      is_selected = selected === index + 1 ? 'selected' : '';
      return result += "<option value='" + (index + 1) + "' " + is_selected + ">" + value + "</option>";
    });
    return new Handlebars.SafeString(result);
  });

  Handlebars.registerHelper("daysOptions", function(selected) {
    var list, result;
    list = _.range(1, 32);
    result = "";
    _(31).times(function(index) {
      var is_selected;
      is_selected = selected === index + 1 ? 'selected' : '';
      return result += "<option value='" + (index + 1) + "' " + is_selected + ">" + (index + 1) + "</option>";
    });
    return new Handlebars.SafeString(result);
  });

  Handlebars.registerHelper("yearsOptions", function(selected) {
    var current_year, list, result;
    current_year = (new Date).getFullYear();
    list = _.range(1900, current_year - 11).reverse();
    result = "";
    $.each(list, function(i, value) {
      var is_selected;
      is_selected = selected === value ? 'selected' : '';
      return result += "<option value='" + value + "' " + is_selected + ">" + value + "</option>";
    });
    return new Handlebars.SafeString(result);
  });

  Handlebars.registerHelper("genderOptions", function(selected) {
    var list, result;
    list = [
      {
        value: 'male',
        name: 'Male'
      }, {
        value: 'female',
        name: 'Female'
      }, {
        value: 'hidden',
        name: 'Private'
      }
    ];
    result = "";
    $.each(list, function(i, gender) {
      var is_selected;
      is_selected = selected === gender.value ? 'selected' : '';
      return result += "<option value='" + gender.value + "' " + is_selected + ">" + gender.name + "</option>";
    });
    return new Handlebars.SafeString(result);
  });

  Handlebars.registerHelper("timezonesOptions", function(selected) {
    var list, result;
    list = Immerss.timezones || [];
    result = "";
    if (typeof $.cookie("tzinfo") !== "undefined" || $.cookie("tzinfo") !== "false") {
      selected || (selected = $.cookie("tzinfo"));
    }
    $.each(list, function(i, tz) {
      var is_selected;
      if (!selected) {
        selected = tz.value;
      }
      is_selected = selected === tz.value ? 'selected' : '';
      return result += "<option value='" + tz.value + "' " + is_selected + ">" + tz.name + "</option>";
    });
    return new Handlebars.SafeString(result);
  });

  Handlebars.registerHelper("countriesOptions", function(selected) {
    var list, result;
    list = Immerss.countries || [];
    result = "";
    $.each(list, function(i, country) {
      var is_selected;
      is_selected = selected === country.value ? 'selected' : '';
      return result += "<option value='" + country.value + "' " + is_selected + ">" + country.name + "</option>";
    });
    return new Handlebars.SafeString(result);
  });

  Handlebars.registerHelper("channelCategoriesOptions", function(selected) {
    var list, result;
    list = Immerss.channelCategories || [];
    result = "";
    $.each(list, function(i, category) {
      var is_selected;
      is_selected = selected === category.value ? 'selected' : '';
      return result += "<option value='" + category.value + "' " + is_selected + ">" + category.name + "</option>";
    });
    return new Handlebars.SafeString(result);
  });

  Handlebars.registerHelper("channelTypesOptions", function(selected) {
    var list, result;
    list = Immerss.channelTypes || [];
    result = "";
    $.each(list, function(i, type) {
      var is_selected;
      is_selected = selected === type.value ? 'selected' : '';
      return result += "<option value='" + type.value + "' " + is_selected + ">" + type.name + "</option>";
    });
    return new Handlebars.SafeString(result);
  });

  Handlebars.registerHelper("formatUrl", function(str) {
    if (/^https?.+/.test(str)) {
      return str;
    } else {
      return 'http://' + str;
    }
  });

  Handlebars.registerHelper("formatDate", function(timestamp) {
    var date, format;
    if (timestamp.toString().length === 10) {
      timestamp *= 1000;
    }
    date = new Date(timestamp);
    format = Immerss && Immerss.timeFormat === '12hour' ? 'MMM D h:mm A' : 'MMM D H:mm';
    if (Immerss && Immerss.timezoneOffset) {
      return moment(date).utcOffset(Immerss.timezoneOffset).format(format);
    } else {
      return moment(date).format(format);
    }
  });

}).call(this);
