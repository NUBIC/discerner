(function ($) {
  
  $.widget("ui.combobox", {
    _create: function () {
      var self = this,
      width = this.element.css('width'),
      select = this.element.hide(),
      selected = select.children(":selected"),
      value = selected.val() ? selected.text() : "",
      watermark = ('Search for ' + this.options.watermark),
      input = $("<input>").insertAfter(select).val(value).addClass(this.options.css_class);
        
      if ( width.replace(/px|em/,'') > 0 ) { 
        input.css('width', width);
      }

      input.focus(function () { this.select(); });

      input.mouseup(function (e) { e.preventDefault(); });

      function clearWatermark () {
        if ($(this).val() === watermark) {
          $(this).val('');
        }
      };

      function setWatermark () {
        input.val(watermark);
        input.bind('focus', clearWatermark);
      };

      input.blur(function (e) {
        if ($(this).val() === '') {
          input.val(watermark);
        }
        e.preventDefault();
        return false;
      });

      $(document).ready(function () {
        if ($(input).val() === '') {
          setWatermark();
        }
      });

      input.autocomplete({
        delay: 0,
        minLength: 0,
        // Optimized source function courtesy of:
        //http://stackoverflow.com/questions/5073612/jquery-ui-autocomplete-combobox-very-slow-with-large-select-lists
        source: function( request, response ) {
          var matcher = new RegExp( $.ui.autocomplete.escapeRegex(request.term), "i" ),
          select_el = select.get(0), // get dom element
          rep = new Array(); // response array
          // simple loop for the options
          for (var i = 0; i < select_el.length; i++) {
            var text = select_el.options[i].text;
            if ( select_el.options[i].value && ( !request.term || matcher.test(text) ) )
              // add element to result array
              rep.push({
                label: text.replace(
                  new RegExp(
                    "(?![^&;]+;)(?!<[^<>]*)(" +
                    $.ui.autocomplete.escapeRegex(request.term) +
                    ")(?![^<>]*>)(?![^&;]+;)", "gi"
                  ), "<strong>$1</strong>" ),
                  value: text,
                  option: select_el.options[i]
                });
              }
              // send response
              response( rep );
        },
        select: function( event, ui ) {
          ui.item.option.selected = true;
          select.val( ui.item.option.value );
          select.trigger('change');
          self._trigger( "selected", event, { item: ui.item.option });
        },
        change: function( event, ui ) {
          if ( !ui.item ) {
            var matcher = new RegExp( "^" + $.ui.autocomplete.escapeRegex( $(this).val() ) + "$", "i" ),
            valid = false;
            select.children( "option" ).each(function() {
              if ( this.value.match( matcher ) ) {
                this.selected = valid = true;
                return false;
              }
            });
            if ( !valid ) {
              // remove invalid value, as it didn't match anything
              $( this ).val( "" );
              setWatermark();
              select.val( "" );
              return false;
            }
          }
        },
        create: function (event, ui) {
          if (/(msie) ([\w.]+)/.exec(navigator.userAgent)) {
            $(input).keypress(function(event){
              var keycode = (event.keyCode ? event.keyCode : event.which);
              if (keycode === '13') {
                event.preventDefault();
                event.stopPropagation();
                var autocomplete = input.data( "autocomplete" );
                autocomplete.menu._trigger("selected", event, { item: autocomplete.menu.active });
              }
            });
          }
        }
      })
      .addClass( "ui-widget ui-widget-content ui-corner-left" );

      input.data("ui-autocomplete")._renderItem = function( ul, item ) {
        return $( "<li></li>" )
          .data( "item.autocomplete", item )
          .append( "<a>" + item.label + "</a>" )
          .appendTo( ul );
      };

      if (input.hasClass('autocompleter-dropdown')) {
        this.button = $( "<button type='button'>&nbsp;</button>" )
          .attr( "tabIndex", -1 )
          .attr( "title", "Show All Items" )
          .insertAfter( input )
          .button({ icons: { primary: "ui-icon-triangle-1-s" }, text: false})
          .removeClass( "ui-corner-all" )
          .addClass( "ui-corner-right ui-button-icon" )
          .click(function() {
            // close if already visible
            if (input.autocomplete( "widget" ).is( ":visible" ) ) {
              input.autocomplete( "close" );
              return;
            }
            // work around a bug (likely same cause as #5265)
            $(this).blur();
            // pass empty string as value to search for, displaying all results
            input.autocomplete( "search", "" );
            input.focus();
          });
      }
    },

    setValue: function (value) {
      var $input = $(this.element[0]).next();
      $("option", this.element).each(function () {
        if ($(this).text() === value) {
          this.selected = true;
          $input.val(this.text);
          return false;
        }
      });
    }
  });
})(jQuery);