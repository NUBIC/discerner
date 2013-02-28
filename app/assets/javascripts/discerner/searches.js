// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

Discerner.Search.UI = function (config) {
  var dictionarySelector = $('.discerner_search_dictionary select#search_dictionary_id'),
      dictionaryContainer = $('.discerner_search_dictionary span'),
      selectedDictionaryOption = $(dictionarySelector).find('option:selected:last');
          
  var toggleControls = function() {
    selectedDictionaryOption = $(dictionarySelector).find('option:selected:last');
    if (dictionarySelector.length > 0 && selectedDictionaryOption.length == 0 || selectedDictionaryOption.val() == '') {
      $('.search_parameters').hide();
      $('.search_combinations').hide();
      $('.discerner_dictionary_required_message').show();
    } else {
      $('.search_parameters').show();
      $('.search_combinations').show();
      $('.discerner_dictionary_required_message').hide();
    }
  }
  
  // handle dictionary selection change
  $(dictionarySelector).bind('change', function(){
    $('a.delete_search_parameters').trigger('click');
    $('a.delete_search_combinations').trigger('click');
    toggleControls()
  });
  
  // block UI on form submit
  $('#discerner_search_form form, #results form').bind('submit', function(){
    $.blockUI({ 
        title:    'Loading ... ', 
        message:  '<p>Please be patient</p>',
        fadeIn: 0, 
        timeout: 20000000, 
        showOverlay: true, 
        centerY: true, 
        theme: true
    });
  });
    
  $(document).on('mouseover', '.datepicker', function() {
    $(this).datepicker({
      altFormat: 'yy-mm-dd',
      dateFormat: 'yy-mm-dd',
      changeMonth: true,
      changeYear: true,
      yearRange: config.yearRange
      });
  });

  // handle search name editing
  $('#discerner_search_form .discerner_search_name_edit a').bind('click', function(){
    $(this).closest('span.discerner_search_name_edit').hide();
    $(this).closest('span.discerner_search_name_edit').siblings('span.discerner_search_name').hide();
    $(this).closest('div').append($('<span>')
      .load(config.renameUrl + ' form')
      .addClass('name_edit'));
    return false;
  });
  
  // handle cancel on search name editing
  $(document).on('click', '#discerner_search_form .discerner_search_name a.cancel', function() {
    $('span.name_edit').siblings('span.discerner_search_name').show();
    $('span.name_edit').siblings('span.discerner_search_name_edit').show();
    $('span.name_edit').remove();
    $("#messages").html('');
    return false;
  });

  toggleControls();
};

