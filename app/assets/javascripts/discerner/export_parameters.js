Discerner.ExportParameters.UI = function() {
  $(document).on('click','#discerner_exportable_fields a.select_all_parameters', function(){
    $(this).closest("div[class^='parameter_category_']").find("input[type='checkbox']:not(:checked)").prop('checked', true);
    $(this).removeClass('select_all_parameters').addClass('deselect_all_parameters').html('Deselect all')
    $(this)
  });

  $(document).on('click','#discerner_exportable_fields a.deselect_all_parameters', function(){
    $(this).closest("div[class^='parameter_category_']").find("input[type='checkbox']:checked").prop('checked', false);
    $(this).removeClass('deselect_all_parameters').addClass('select_all_parameters').html('Select all')
  });
}