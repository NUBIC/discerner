// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

Discerner.SearchCombination.UI = function (config) {
  var dictionarySelector = $('.discerner_search_dictionary select#search_dictionary_id'),
  selectedDictionaryOption = $(dictionarySelector).find('option:selected:last'),
  
  setupCombinedSearches = function () {
    var search_combinations = $('.search_combinations').find('.nested_records_search_combinations tr.search_combination'),
    display_orders = search_combinations.find('input[name$="[display_order]"]'),
    i = 0;

    // set up predicate for selected searches
    search_combinations.filter(':visible:not(:first)').find('.combined_search_operator span').html('and');
    
    // get max display order
    $.each(display_orders, function(){
      var val = parseInt($(this).val());
      if (val >= i) { i = val }
    });
        
    // assign display order to combined searches without it
    $.each(display_orders, function(){
      if ($(this).val().length == 0) {
        i = i + 1
        $(this).val(i);
      }
    })
        
    // hide combined searches options that do not belong to selected dictionary
    if (dictionarySelector.length > 0){
      dictionary_class = $(dictionarySelector).find('option:selected:last').attr('class')
      $('.search_combinations_combobox_autocompleter').find('option:not(.' + dictionary_class +'):not([value=""])').detach();
    };
    
    // setup autocompleters for newly added row
    $(".search_combinations_combobox_autocompleter").combobox({watermark:'an existing search', css_class:'autocompleter-dropdown'});
  };
  
  searchCombinationNestedAttributesForm = new NestedAttributes({
    container: $('.search_combinations'),
    association: 'search_combinations',
    content: config.searchCombinationsTemplate,
    addHandler: setupCombinedSearches,
    caller: this
  });
  
  setupCombinedSearches();
}