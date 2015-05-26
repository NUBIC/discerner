Discerner.SearchParameterValue.UI = function (config) {
  var that = this,
    parametersUrl = new Discerner.Url(config.parametersUrl),
    hideValue = function(e){
      if (!$(e).hasClass('invisible')){
        $(e).addClass('invisible');
      }
    };
    showValue = function(e){
      if ($(e).hasClass('invisible')){
        $(e).removeClass('invisible');
      }
    };
    setupOperator = function(o){
      var row = $(o).closest('tr');
      option = $(o).find('option:selected');
      if (option.hasClass('range')){
        showValue($(row).find('.additional_value'));
      } else {
        hideValue($(row).find('.additional_value'));
      }
      if (option.hasClass('presence')){
        hideValue($(row).find('.value'));
      } else {
        showValue($(row).find('.value'));
      }
    },
    setupParameterValues = function(){
      var row = $(config.container).find('.nested_records_search_parameter_values .search_parameter_value').last(),
        selectedParameter = $(config.container).find('select.parameters_combobox_autocompleter option:selected:last');

      row.find('td').hide();
      hideValue($(row).find('.additional_value').show());
      row.find('.parameter_values_boolean_operator').show();

      if ($(selectedParameter).hasClass('list')){                                      // list parameters
        row.find('.chosen, .parameter_value').show();
        $(config.container).find('a.add_search_parameter_values').hide();
        $(config.container).find('.additional_value').hide();
      } else if ($(selectedParameter).hasClass('combobox')) {                         // combobox parameters
        var input = $(row).find('input.parameter_value_id');
        var offset = $(row).offset();
        $(config.container).find('.additional_value').hide();
        if (input.length > 0) {
            $('.discerner-spinner').css({ left: offset.left });
            $('.discerner-spinner').css({ top: offset.top });
            $('.discerner-spinner').removeClass('hide');
            $.get( parametersUrl.sub({ question_id: selectedParameter.val(), search_parameter_value_id: input.closest('tr.search_parameter_value').attr('id') }), function( data ) {
              container = $(input).closest('td');
              $(input).detach();
              container.append( data );
              container.find('select').attr('id', input.attr('id')).attr('name', input.attr('name')).combobox({ watermark:'a value'});
              handleParameterValuelPopupListClick(row);
              handleParameterValueAutocompleterButtonLink(row);
              $('.discerner-spinner').addClass('hide');
            });
          }
        $(config.container).find('.parameter_value, .remove').show();
        $(config.container).find('a.add_search_parameter_values').show();
      } else if ($(selectedParameter).hasClass('exclusive_list')) {                   // exclusive parameter values list
        $(config.container).find('a.add_search_parameter_values').hide();
        $(config.container).find('.additional_value', '.chosen').hide();
        $(config.container).find('.parameter_value').show();
      } else {                                                                        // date, text and numeric parameters
        var parameter_classes = ['date', 'numeric', 'text', 'string'];
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
      $(config.container).find(".parameter_values_combobox_autocompleter").combobox({watermark:'a value'});
    },
    searchParameterValuesNestedAttributesForm = new NestedAttributes({
      container: config.container,
      association: 'search_parameter_values',
      content: config.searchParameterValuesTemplate,
      addHandler: setupParameterValues,
      caller: this
  });

  // toggle parameter value popup
  var toggleCategorizedAutocompleterPopup = function (link) {
    var popup = $(link).parents('.categorized_autocompleter').find('.div-category-popup');
    if ($(link).hasClass('collapsed_categorized_autocompleter_link')) {
      popup.show();
      $(link).removeClass('collapsed_categorized_autocompleter_link');
      $(link).addClass('expanded_categorized_autocompleter_link');
    }
    else {
      popup.hide();
      $(link).removeClass('expanded_categorized_autocompleter_link');
      $(link).addClass('collapsed_categorized_autocompleter_link');
    }
  };

  // handle parameter value autocompleter button click
  var handleParameterValueAutocompleterButtonLink = function(container){
    $(container).find('.parameter_value .categorized_autocompleter_link').on('click', function(){
      var popup = $(this).siblings('.div-category-popup'),
          select = $(this).siblings('select').first(),
          // get all the "sibling" dropdowns
          sibling_selects = $('select.' + select.attr('class')).filter(function(){
            return $(this).closest('tr').find('td.remove input[name$="[_destroy]"]:not([name*="[search_parameter_values_attributes]"])').filter(function() { return this.value === '1'; }).length == 0 // exclude rows marked for destroy
          }),
          // get all selected parameter options from sibling selects
          matching_selected_options = sibling_selects.find('option.exclusive:selected');
      // match selected options from sibling selects with the source select options
      // (they will have different base ids for each set but same value)
      popup.find('.parameter value a.categorized_autocompleter_item_link').removeClass('selection_disabled');
      $.each(matching_selected_options, function(){
        option = select.find('option[value=' + $(this).val() + ']');
        popup.find('.search_parameter .parameter value a.categorized_autocompleter_item_link[rel="' + $(option).attr('id') + '"]').addClass('selection_disabled');
      })
      toggleCategorizedAutocompleterPopup(this);
      toggleCategorizedAutocompleterPopup($(this).closest('.search_parameter').find('.parameter a.expanded_categorized_autocompleter_link'));
    });
  }

  // handle parameter value popup list link click
  var handleParameterValuelPopupListClick = function(container) {
    $(container).find('.parameter_value .categorized_autocompleter_item_link:not(.selection_disabled)').on('click', function(e){
      e.preventDefault();
      var autocompleter = $(this).parents('.categorized_autocompleter').find('select.parameter_values_combobox_autocompleter'),
          categorizedItemEl = document.getElementById($(this).attr('rel'));
          categorizedAutocompleterLink = $(this).parents('.categorized_autocompleter').find('.categorized_autocompleter_link');
      autocompleter.combobox('setValue', categorizedItemEl.text);
      autocompleter.change();
      toggleCategorizedAutocompleterPopup(categorizedAutocompleterLink);
    });
  }

  setupParameterValues();
  handleParameterValuelPopupListClick(config.container);
  handleParameterValueAutocompleterButtonLink(config.container);

  $.each($('.operator'), function() { setupOperator(this); });

  $(document).on('change', '.operator select', function(){
    setupOperator(this);
  });

  $(document).on('click', '.show-category-items', function(e) {
    e.preventDefault();
    $(this).closest('.categorized-parameter-values, .uncategorized-parameter-values').find('.category-items').show();
    $(this).addClass('hide-category-items');
    $(this).removeClass('show-category-items');
    $(this).html('less');
  });

  $(document).on('click', '.hide-category-items', function(e) {
    e.preventDefault();
    $(this).closest('.categorized-parameter-values, .uncategorized-parameter-values').find('.category-items').hide();
    $(this).addClass('show-category-items');
    $(this).removeClass('hide-category-items');
    $(this).html('more');
  });
};