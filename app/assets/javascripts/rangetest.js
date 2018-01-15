Modernizr.load([
{
  // Test if Input Range is supported using Modernizr
  test: Modernizr.inputtypes.range,
  // If ranges are not supported, load the slider script and CSS file
  nope: [
    // The slider CSS file
    "css!#{asset_path('fd-slider.css')}"
    // Javascript file for slider
    ,"#{asset_path('fd-slider.js')}"
  ],
  callback: function(id, testResult) {
    // If the slider file has loaded then fire the onDomReady event
    if("fdSlider" in window && typeof (fdSlider.onDomReady) != "undefined") {
      try { fdSlider.onDomReady(); } catch(err) {};
    };
  }
}
]);
