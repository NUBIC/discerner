Discerner.SearchParameterValue.UI = function (config) {
  var that = this,
    parametersUrl = new Discerner.Url(config.parametersUrl),
    hideValue = function(e){
      if (!$(e).hasClass('invisible')){
        $(e).addClass('invisible')
      }
    }
    showValue = function(e){
      if ($(e).hasClass('invisible')){
        $(e).removeClass('invisible')
      }
    }
    setupOperator = function(o){
      var row = $(o).closest('tr');
      if ($(o).find('option:selected').hasClass('range')){
        showValue($(row).find('.additional_value'))
      } else {
        hideValue($(row).find('.additional_value'))
      }
      if ($(o).find('option:selected').hasClass('presence')){
        hideValue($(row).find('.value'))
      } else {
        showValue($(row).find('.value'))
      }
    },
    setupParameterValues = function(){
      var row = $(config.container).find('.nested_records_search_parameter_values .search_parameter_value').last(),
        selectedParameter = $(config.container).find('select.parameters_combobox_autocompleter option:selected:last');
      row.find('td').hide();
      hideValue($(row).find('.additional_value').show())
      row.find('.parameter_values_boolean_operator').show();

      if ($(selectedParameter).hasClass('list')) {                                     // list parameters
        row.find('.chosen, .parameter_value').show();
        $(config.container).find('a.add_search_parameter_values').hide();
        $(config.container).find('.additional_value').hide();
      } else if ($(selectedParameter).hasClass('combobox')) {                         // combobox parameters
        var input = $(row).find('input.parameter_value_id');
        $(config.container).find('.additional_value').hide();
        if (input.length > 0) {
          $.get(parametersUrl.sub({ question_id: selectedParameter.val() }), function (html) {
            var select = $(html).find('select').attr('name', input.attr('name')).attr('id', input.attr('id'));
            $(select).find('option[value="' + input.val() + '"]').attr('selected', true);
            select.addClass('parameter_values_combobox_autocompleter')
            .insertBefore(input)
            .combobox({ watermark:'a value', css_class:'autocompleter-dropdown' });
            input.detach();
          });
        }
        $(config.container).find('.parameter_value, .remove').show();
        $(config.container).find('a.add_search_parameter_values').show();
      } else {                                                                        // date, text and numeric parameters
        var parameter_classes = ['date', 'numeric', 'text', 'string']
        for (var i in parameter_classes) {
          if ($(selectedParameter).hasClass(parameter_classes[i])) {
            row.find('.operator option:not(.' + parameter_classes[i] +')').detach();
            row.find('.operator, .value, .remove').show();
            $(config.container).find('a.add_search_parameter_values').show();
            if (parameter_classes[i] == 'date') {
              row.find('.value input, .additional_value input').addClass('datepicker');
            }
          }
        }
      }
      $(config.container).find('.nested_records_search_parameter_values tr.search_parameter_value:visible:not(:first)')
        .find('.parameter_values_boolean_operator span').html('or');

      var i = 0,
          display_orders = config.container.find('input[name*="search_parameter_values_attributes"][name$="[display_order]"]');

      // get max display order
      $.each(display_orders, function(){
        var val = parseInt($(this).val());
        if (val >= i) { i = val }
      });
      // assign display order to search predicates without it
      $.each(display_orders, function(){
        if ($(this).val().length == 0) {
          i = i + 1
          $(this).val(i);
        }
      });

    },
    searchParameterValuesNestedAttributesForm = new NestedAttributes({
      container: config.container,
      association: 'search_parameter_values',
      content: config.searchParameterValuesTemplate,
      addHandler: setupParameterValues,
      caller: this
    });

  setupParameterValues();
  $.each($('.operator'), function() { setupOperator(this); });

  $(document).on('change', '.operator select', function(){
    setupOperator(this);
  });
};