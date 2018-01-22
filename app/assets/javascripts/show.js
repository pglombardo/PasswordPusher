//CSP-Fix

function unblur(spoiler) {
  if (spoiler.data('spoiler-state') == 'shrouded') {
    spoiler.data('spoiler-state', 'revealed')
      .attr('title', '')
      .css('cursor', 'auto')
    performBlur(0, -1)
  } else {
    spoiler.data('spoiler-state', 'shrouded')
      .attr('title', hintText)
      .css('cursor', 'pointer')
    performBlur(partialBlur, 1)
  }
}

if (document.getElementById("url") != null) {
  document.getElementById("url").addEventListener("focus",function(){
     $(this).focus(); $(this).select();
   });

  document.getElementById("url").addEventListener("click",function(){
    $(this).select();
  });
}
(function(){
   if (document.getElementById("copyButton") != null) {
    new Clipboard('#copyButton');
   } 


   if ((p_div = document.getElementById("payload_div") )!= null) {
    $spoiler = $($('spoiler, .spoiler'))
   
    p_div.addEventListener("click",function(){
      if ($spoiler.data('spoiler-state') == 'revealed') {
        unblur($spoiler);
      } else {
        if (document.queryCommandSupported("copy")){
          alert("Password has been saved to your Clipboard!")
        } else {
          alert("Press CTRL+v to copy the Password to your Clipboard!")
        }
    }
    });
    new Clipboard('#payload_div');

    if ((cLink = document.getElementById("copyLink")) != null){
      cLink.addEventListener("click", function(){
        unblur($spoiler);
        setTimeout(function(){
          if ($spoiler.data('spoiler-state') == 'revealed') {
            unblur($spoiler);
          }
        },10000)
      })
    }

   }


   
   
   
})();

