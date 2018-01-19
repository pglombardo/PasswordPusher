//CSP-Fix
document.getElementById("url").addEventListener("focus",function(){
    $(this).focus(); $(this).select();
  });

  document.getElementById("url").addEventListener("click",function(){
    $(this).select();
  });

  document.getElementById("copyPass").addEventListener("click",function(){
    var copyText = document.getElementById("payload_spoiler").textContent;
    copyText.select();
    document.execCommand("Copy");
    alert("Password was copied to clipboard!");
    return false;
  });
  
(function(){
    new Clipboard('#copyButton');
})();