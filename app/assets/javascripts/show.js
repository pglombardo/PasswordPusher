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


   var myTimeOut;

   if ((p_div = document.getElementById("payload_div") )!= null) {
    $spoiler = $($('spoiler, .spoiler'))
    new Clipboard('#payload_div')
    p_div.addEventListener("click",function(){
      if ($spoiler.data('spoiler-state') == 'revealed') {
        clearTimeout(myTimeOut);
        p_div.dispatchEvent(new Event('switchBlur'));
      } else {
        if (document.queryCommandSupported("copy")){
          alert("Password will be saved to your Clipboard!");
        } else {
          alert("After closing this press CTRL+v to copy the Password to your Clipboard!");
        }
    }
    });
    

    if ((cLink = document.getElementById("copyLink")) != null){
      cLink.addEventListener("click", function(){
        if ($spoiler.data('spoiler-state') == 'shrouded') {
          p_div.dispatchEvent(new Event('switchBlur'))
        
          myTimeOut = setTimeout(function(){
            if ($spoiler.data('spoiler-state') == 'revealed') {
              p_div.dispatchEvent(new Event('switchBlur'))
            }
          },10000)
      }
      })
    }

   }


   
   
   
})();

