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

   if ((p_div = $('spoiler, .spoiler')) != null) {
    new Clipboard('#payload_div');
    p_div.addEventListener("click",function(){
      if (p_div.data('spoiler-state') == 'revealed') {
        unblur(p_div);
      } else {
        if (document.queryCommandSupported("copy")){
          alert("Password has been saved to your Clipboard!")
        } else {
          alert("Press CTRL+v to copy the Password to your Clipboard!")
        }
    }
    });

    if (cLink = document.getElementById("copyLink") != null){
      cLink.addEventListener("click", function(){
        unblur(p_div);
        setTimeout(function(){
          if (p_div.data('spoiler-state') == 'revealed') {
            unblur(p_div);
          }
        },10000)
      })
    }

   }


   
   
   
})();

