// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

Discerner.SearchParameter.UI = function (config) {
  var parametersUrl = new Discerner.Url(config.parametersUrl),
  dictionarySelector = $('.discerner_search_dictionary select#search_dictionary_id'),
  selectedDictionaryOption = $(dictionarySelector).find('option:selected:last'),

  setupParameters = function () {
    var search_parameters = $('.search_parameters').find('.nested_records_search_parameters tr.search_parameter'),
    display_orders = search_parameters.find('input:not([name*="search_parameter_values_attributes"])[name$="[display_order]"]'),
    i = 0;

    search_parameters.filter(':visible:not(:first)').find('.parameter_boolean_operator span').html('and');

    // remove parameter options that do not belong to selected dictionary
    if (dictionarySelector.length > 0){
      dictionary_class = $(dictionarySelector).find('option:selected:last').attr('class');
      $.each($('div.parameter_category'), function(){
        if (!$(this).hasClass(dictionary_class)) {
          $(this).remove();
        }
      });
      $.each($('select.parameters_combobox_autocompleter option'), function(){
        if (!($(this).hasClass(dictionary_class) || $(this).val() === '')) {
          $(this).remove();
        }
      });
    }
    $(".parameters_combobox_autocompleter").combobox({watermark:'a criteria'});

    // get max display order
    $.each(display_orders, function(){
      var val = parseInt($(this).val(), 10);
      if (val >= i) { i = val; }
    });

    // assign display order to search predicates without it
    $.each(display_orders, function(){
      if ($(this).val().length === 0) {
        i = i + 1;
        $(this).val(i);
      }
    });
  },
  searchParametersNestedAttributesForm = new NestedAttributes({
    container: $('.search_parameters'),
    association: 'search_parameters',
    content: config.searchParametersTemplate,
    addHandler: setupParameters,
    caller: this
  });

  // handle criteria autocompleter button click
  $(document).on('click', '.parameter .categorized_autocompleter_link', function () {
    var popup = $(this).siblings('.div-category-popup'),
        select = $(this).siblings('select').first(),
        // get all the "sibling" dropdowns
        sibling_selects = $('select.' + select.attr('class')).filter(function(){
          return $(this).closest('tr').find('td.remove input[name$="[_destroy]"]:not([name*="[search_parameter_values_attributes]"])').filter(function() { return this.value === '1'; }).length === 0; // exclude rows marked for destroy
        }),
        // get all selected parameter options from sibling selects
        matching_selected_options = sibling_selects.find('option.exclusive:selected');
    // match selected options from sibling selects with the source select options
    // (they will have different base ids for each set but same value)
    popup.find('.criteria a.categorized_autocompleter_item_link').removeClass('selection_disabled');
    $.each(matching_selected_options, function(){
      option = select.find('option[value=' + $(this).val() + ']');
      popup.find('.parameter_category .criteria a.categorized_autocompleter_item_link[rel="' + $(option).attr('id') + '"]').addClass('selection_disabled');
    });
    toggleCategorizedAutocompleterPopup(this);
    toggleCategorizedAutocompleterPopup($(this).closest('.search_parameter').find('.parameter_value a.expanded_categorized_autocompleter_link'));
  });

  // handle criteria popup list link click
  $(document).on('click', '.parameter .categorized_autocompleter_item_link:not(.selection_disabled)', function () {
    var autocompleter = $(this).parents('.categorized_autocompleter').find('select.parameters_combobox_autocompleter'),
        categorizedItemEl = document.getElementById($(this).attr('rel'));
        categorizedAutocompleterLink = $(this).parents('.categorized_autocompleter').find('.categorized_autocompleter_link');
    autocompleter.combobox('setValue', categorizedItemEl.text);
    autocompleter.change();
    toggleCategorizedAutocompleterPopup(categorizedAutocompleterLink);
  });

  // toggle criteria popup
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

  // handle changing selections for criteria autocompleter
  $(document).on('change', '.parameter select.parameters_combobox_autocompleter', function () {
    var that = this,
      predicate = $(that).closest('.search_parameter'),
      selected_option = $(that).find('option:selected:last'),
      add_button = $(predicate).find('a.add_search_parameter_values');

    $(predicate).find('.nested_records_search_parameter_values .search_parameter_value .delete_search_parameter_values').click();
    if ($(selected_option).length === 0 || $(selected_option).val() === ''){
      $(add_button).hide();
    } else if ($(selected_option).hasClass('list')) {
      $($(predicate).find('.tmp_link')).remove();
      $.get(parametersUrl.sub({ question_id: this.value }), function (data) {
        $.each(data.parameter_values, function() {
          $(add_button).click();
          var row = $(predicate).find('.nested_records_search_parameter_values .search_parameter_value').filter(':last');
          row.find('.parameter_value span').text(this.name);
          row.find('.parameter_value_id').val(this.parameter_value_id);
          $(add_button).hide();
        });
     });
    } else if ($(selected_option).hasClass('exclusive_list')) {
      $($(predicate).find('.tmp_link')).remove();
      $.get(parametersUrl.sub({ question_id: this.value }), function (data) {
        $(add_button).click();
        var row = $(predicate).find('.nested_records_search_parameter_values .search_parameter_value .parameter_value').filter(':last');
        $.each(data.parameter_values, function() {
          var value_id_element = row.find('.parameter_value_id'),
              radio_id = value_id_element.attr('id') + '_' + this.parameter_value_id,
              value_item_div = $('<div>').addClass('parameter_value_item');

          radio_button      = $('<input>').attr('type', 'radio').attr('name', value_id_element.attr('name')).attr('id',radio_id).val(this.parameter_value_id);
          radio_button_text = $('<label>').attr('for', radio_id).text(this.name);
          value_item_div.append(radio_button);
          value_item_div.append(radio_button_text);
          row.append(value_item_div);
          $(add_button).hide();
        });
      });
    } else {
      $(add_button).show();
      $(add_button).click();
    }
  });
  setupParameters();
};

