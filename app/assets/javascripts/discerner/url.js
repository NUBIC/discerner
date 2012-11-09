Discerner.Url = function (url) {
  this.url = url;
};

Discerner.Url.prototype = {
  sub: function (params) {
    var url = this.url,
        newUrl = this.url,
        queryString = [],
        encodedArg = undefined,
        encodeParam = undefined,
        param = undefined;

    for (param in params) {
      if (params.hasOwnProperty(param)) {
        encodedParam = encodeURIComponent(param);
        encodedArg = encodeURIComponent(params[param]);
        newUrl = url.replace(':' + param, encodedArg);
        if (url == newUrl) {
          queryString.push(encodedParam + '=' + encodedArg);
        }
        url = newUrl;
      }
    }

    if (queryString.length > 0) {
      if (url.indexOf('?') > 0) {
        return url + queryString.join('&');
      } else {
        return url + '?' + queryString.join('&');
      }
    } else {
      return url;
    }
  },

  parameters: function () {
    return $.map(this.url.match(/:\w+/g) || [], function (o, i) {
      return o.substring(1);
    });
  }
};