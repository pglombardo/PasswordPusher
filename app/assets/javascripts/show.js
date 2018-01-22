//CSP-Fix
document.getElementById("url").addEventListener("focus",function(){
    $(this).focus(); $(this).select();
  });

  document.getElementById("url").addEventListener("click",function(){
    $(this).select();
  });

(function(){
   if (document.getElementById("copyButton") != NULL) {
    new Clipboard('#copyButton');
   } 

   if (document.getElementById("copyLink") != NULL) {
    new Clipboard('#copyLink');
   } 
})();