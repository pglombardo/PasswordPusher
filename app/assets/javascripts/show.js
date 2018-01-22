//CSP-Fix



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
    new Clipboard('#payload_div')
    p_div.addEventListener("click",function(){
      if ($spoiler.data('spoiler-state') == 'revealed') {
        p_div.dispatchEvent(new Event('switchBlur'))
      } else {
        if (document.queryCommandSupported("copy")){
          alert("Password has been saved to your Clipboard!")
        } else {
          alert("Press CTRL+v to copy the Password to your Clipboard!")
        }
    }
    });
    

    if ((cLink = document.getElementById("copyLink")) != null){
      cLink.addEventListener("click", function(){
        if ($spoiler.data('spoiler-state') == 'shrouded') {
          p_div.dispatchEvent(new Event('switchBlur'))
        }
        setTimeout(function(){
          if ($spoiler.data('spoiler-state') == 'revealed') {
            p_div.dispatchEvent(new Event('switchBlur'))
          }
        },10000)
      })
    }

   }


   
   
   
})();

