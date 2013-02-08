Discerner = {};
Discerner.Constants = {};
Discerner.Search = {};
Discerner.SearchParameter = {};
Discerner.SearchParameterValue = {}
Discerner.SearchCombination = {};
Discerner.CategorizedAutocomplter = {};
Discerner.Url = {};
NestedAttributes = {};

Discerner.Constants.EFFECT_SPEED = 1750;

$(function() {
  $("#discerner_searches_filter input[type=\"text\"]").live("keyup",
  function() {
    $.get($("#discerner_searches_filter").attr("action"), $("#discerner_searches_filter").serialize(), null, "script");
    return false;
  });
})