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
    $(".parameters_combobox_autocompleter").combobox({watermark:'a question'});

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
    })

    // hide parameter options that do not belong to selected dictionary
    if (dictionarySelector.length > 0){
      $.each($('div.parameter_category'), function(){
        dictionary_class = $(dictionarySelector).find('option:selected:last').attr('class')
        if ($(this).hasClass(dictionary_class)) {
          $(this).show();
        } else {
          $(this).hide();
        }
      })
    };
  },
  searchParametersNestedAttributesForm = new NestedAttributes({
    container: $('.search_parameters'),
    association: 'search_parameters',
    content: config.searchParametersTemplate,
    addHandler: setupParameters,
    caller: this
  });

  // handle criteria autocompleter button click
  $(document).on('click', '.categorized_autocompleter_link', function () {
    var select = $(this).siblings('select').first(),
        sibling_selects = $('select.' + select.attr('class')).filter(function(){
          return $(this).closest('tr').find('td.remove input[name$="[_destroy]"]:not([name*="[search_parameter_values_attributes]"])[value="1"]').length == 0 // exclude rows marked for destroy
        }),  // get all the "sibling" dropdowns
        matching_selected_options = sibling_selects.find('option.exclusive:selected'),
        popup = $(this).siblings('.div-criteria-popup'); // find selected options in "sibling" dropdowns that match current option value (do not count if option text matches "Text search diagnosis")

    popup.find('.criteria a.categorized_autocompleter_item_link').removeClass('selection_disabled');
    $.each(matching_selected_options, function(){
      popup.find('.criteria a.categorized_autocompleter_item_link[rel="' + $(this).html() + '"]').addClass('selection_disabled');
    })
    toggleCategorizedAutocompleterPopup(this);
  });

  // handle criteria popup list link click
  $(document).on('click', '.categorized_autocompleter_item_link:not(.selection_disabled)', function () {
    var autocompleter = $(this).parents('.categorized_autocompleter').find('.parameters_combobox_autocompleter'),
      categorizedItem = $(this).attr('rel'),
      categorizedAutocompleterLink = $(this).parents('.categorized_autocompleter').find('.categorized_autocompleter_link');
    autocompleter.combobox('setValue', categorizedItem);
    autocompleter.change();
    toggleCategorizedAutocompleterPopup(categorizedAutocompleterLink);
  });

  // toggle criteria popup
  var toggleCategorizedAutocompleterPopup = function (link) {
    var popup = $(link).parents('.categorized_autocompleter').find('.div-criteria-popup');
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
  $(document).on('change', 'select.parameters_combobox_autocompleter', function () {
    var that = this,
      predicate = $(that).closest('.search_parameter'),
      selected_option = $(that).find('option:selected:last'),
      add_button = $(predicate).find('a.add_search_parameter_values');

    $(predicate).find('.nested_records_search_parameter_values .search_parameter_value .delete_search_parameter_values').click();
    if ($(selected_option).length == 0 || $(selected_option).val() == ''){
      $(add_button).hide();
    }
    else if ($(selected_option).hasClass('list')){
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
    } else {
      $(add_button).show();
      $(add_button).click();
    }
  });

  setupParameters();
};

