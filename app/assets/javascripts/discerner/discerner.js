Discerner = {};
Discerner.Constants = {};
Discerner.Search = {};
Discerner.SearchParameter = {};
Discerner.SearchParameterValue = {}
Discerner.SearchCombination = {};
Discerner.CategorizedAutocomplter = {};
Discerner.ExportParameters = {};
Discerner.Url = {};
NestedAttributes = {};

Discerner.Constants.EFFECT_SPEED = 1750;

$(function() {
  $(document).on('keyup', '#discerner_searches_filter input[type="text"]', function() {
    $.get($("#discerner_searches_filter").attr("action"), $("#discerner_searches_filter").serialize(), null, "script");
    return false;
  });
  $('.discerner').find('input[type=submit], a.button-discerner, button.button-discerner').button()
})