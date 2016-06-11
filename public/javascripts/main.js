$(document).ready(function() {

  // Product image rotater
  $('.img-thumbs img').on('click', function(){
    var this_id = $(this).attr('id'),
        this_src = $(this).attr('src'),
        this_alt = $(this).attr('alt'),
        src = getPathFromUrl(this_src),
        display = $('.js-img-display img').attr('src'),
        display_size = '?' + getQueryFromUrl(display);

    $('.js-img-display').empty().append('<img id=\'' + this_id + '\' src=\'' + src + display_size + '\' alt=\'' + this_alt + '\' >');
  });

  function getPathFromUrl(url) {
      return url.split(/[?].+/)[0];
  }
  function getQueryFromUrl(url) {
    return url.split(/.+[?]/)[1];
  }

});
