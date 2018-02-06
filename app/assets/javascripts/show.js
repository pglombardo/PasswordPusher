//CSP-Fix
//= require_tree ./show


if (document.getElementById("url") != null) {
  document.getElementById("url").addEventListener("focus",function(){
     $(this).focus(); $(this).select();
   });

  document.getElementById("url").addEventListener("click",function(){
    $(this).select();
  });
}

  if (document.getElementById("copyButton") != null) {
  new Clipboard('#copyButton');
  } 


  var myTimeOut;
  
  if ((p_div = document.getElementById("below_spoiler") )!= null) {
    const myTooltip = new Tooltip(p_div, {
      placement: 'top',
      delay: {show: 500, hide: 1000},
      trigger: 'manual',
      title: function(){if (document.queryCommandSupported("copy")){
          return "Password is saved to your Clipboard!";
       } else {
         return "Press CTRL+v to copy the Password to your Clipboard!";
       }}
    });
  $spoiler = $($('spoiler, .spoiler'))
  new Clipboard('#payload_div')
  p_div.addEventListener("click",function(){
    if ($spoiler.data('spoiler-state') == 'revealed') {
      clearTimeout(myTimeOut);
      p_div.dispatchEvent(new Event('switchBlur'));
    } else {
      
      myTooltip.show();
      //myTooltip.hide();
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


   
   
   


