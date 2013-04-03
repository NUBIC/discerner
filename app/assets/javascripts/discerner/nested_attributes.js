NestedAttributes = function (config) {
  var that = this,
    defaultConfig = {
      removeStyle: 'hide',
      undeleteOnChange: false,
      add: true,
      remove: true
    };
  this.config = $.extend(defaultConfig, config);

  if (this.config.undeleteOnChange) {
    $(this.config.container).find("input, select, textarea").change(function () {
      $(that.config.container).find('.delete_' + that.config.association).prev("input[type=hidden]").val("0");
    });
  }

  $(this.config.container).find("input, select, textarea").focus(function () {
    $(this).select();
  });

  if (this.config.remove) {
    var link = $(this.config.container).find('.delete_' + this.config.association)
    $(document).off('click', link.selector)
    $(document).on('click', link.selector, function() {
      that.remove_fields(this, that.config.removeStyle);

      if (that.config.removeHandler) {
        that.config.removeHandler.call(that.config.caller);
      }
    });
  }

  if (this.config.add) {
    var link = $(this.config.container).find('.add_' + this.config.association)
    $(document).off('click', link.selector)
    $(document).on('click', link.selector, function() {
      that.add_fields(this, that.config.association, that.config.content);

      if (that.config.addHandler) {
        that.config.addHandler.call(that.config.caller);
      }
    });
  }
};

NestedAttributes.prototype = {
  remove_fields: function (link, removeStyle) {
    $(link).prev("input[type=hidden]").val("1");
    if (removeStyle === 'hide' ) {
      $(link).closest(".fields").hide();
      $(link).closest(".fields").prev('.error').hide();
    }
    else if (removeStyle === 'clear' ) {
      $(link).closest(".fields").find('input').clearFields();
      $(link).closest(".fields").find('select').clearFields();
      $(link).closest(".fields").find('textarea').clearFields();
    }
  },

  add_fields: function(link, association, content) {
    var new_id = new Date().getTime(),
      regexp1 = new RegExp("new_" + association, "g"),
      regexp2 = new RegExp("new_nested_record", "g");

    content = content.replace(regexp1, new_id);
    content = content.replace(regexp2, 'new_nested_record_' + new_id);
    $(link).closest("." + association).find('.nested_records_' + association).append(content);
  }
};
