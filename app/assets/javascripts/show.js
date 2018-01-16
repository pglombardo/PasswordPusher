//CSP-Fix
document.getElementById("url").addEventListener("focus",function(){
    $(this).focus(); $(this).select();
  });

  document.getElementById("url").addEventListener("click",function(){
    $(this).select();
  });
  