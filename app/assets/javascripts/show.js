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

   if (document.getElementById("copyLink") != null) {
    new Clipboard('#copyLink');
   } 
})();