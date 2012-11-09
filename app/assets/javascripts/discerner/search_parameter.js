Discerner.SearchParameter.UI = function (config) {
  var that = this,
    parametersUrl = new Discerner.Url(config.parametersUrl),
    setupOperator = function(o){
      var row = $(o).closest('tr');
      if ($(o).find('option:selected').hasClass('binary')){
        $(row).find('.additional_value').show()
      } else {
        $(row).find('.additional_value').hide()
      }
    },
    setupParameterValues = function(){
      var row = $(config.container).find('.nested_records_search_parameter_values .search_parameter_value').last(),
        selectedParameter = $(config.container).find('select.parameters_combobox_autocompleter option:selected:last');
      row.find('td').hide();
      row.find('.parameter_values_boolean_operator').show();
      if ($(selectedParameter).is('.list')){
        row.find('.chosen, .parameter_value').show();
        $(config.container).find('a.add_search_parameter_values').hide();
      } else if ($(selectedParameter).is('.date, .integer, .text')){
        row.find('.operator option:not(.' + selectedParameter.attr('class') +')').detach();
        row.find('.operator, .value, .remove').show();
        if (selectedParameter.attr('class') == 'date'){
          row.find('.value input, .additional_value input').addClass('datepicker');
        }
        $(config.container).find('a.add_search_parameter_values').show();
      } else if ($(selectedParameter).hasClass('combobox')) {
        var input = $(row).find('input.parameter_value_id');
        if (input.length > 0) {
 
          var select = $('<select>').attr('id', input.attr('id'))
            .attr('name', input.attr('name'))
            .addClass('parameter_values_combobox_autocompleter')
            .insertBefore(input);

          $.get(parametersUrl.sub({ question_id: selectedParameter.val() }), function (data) {
            $.each(data.parameter_values, function() {
              var option = $('<option>').val(this.parameter_value_id).html(this.name);
              if (this.parameter_value_id == input.val()){
                option.attr('selected', true);
              }
              option.appendTo(select);
            });
          });
          input.detach();  
        }
        $(config.container).find('.parameter_value, .remove').show();
        $(config.container).find('a.add_search_parameter_values').show();     
      }
      $(config.container).find('.nested_records_search_parameter_values tr.search_parameter_value:visible:not(:first)')
        .find('.parameter_values_boolean_operator span').html('OR');
      $(".parameter_values_combobox_autocompleter").combobox({watermark:'a value', css_class:'autocompleter-dropdown'});
      
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
  
  $('.operator select').live('change', function(){
    setupOperator(this);
  });
};