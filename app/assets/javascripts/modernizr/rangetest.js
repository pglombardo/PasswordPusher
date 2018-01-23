if (!Modernizr.inputtypes.range) {
  jQuery.getScript("#{asset_path('fd-slider.js')}")
    .done(function(){
        console.log('js loaded');
    })
    .fail(function(){
        console.log('js not loaded');
    });
  $('<link/>', {
      rel: 'stylesheet',
      type: 'text/css',
      href: "#{asset_path('fd-slider.css')}"
   }).appendTo('head');
}
