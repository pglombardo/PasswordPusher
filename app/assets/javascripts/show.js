//CSP-Fix
document.getElementById("url").addEventListener("focus",function(){
    $(this).focus(); $(this).select();
  });

  document.getElementById("url").addEventListener("click",function(){
    $(this).select();
  });

document.getElementById("copyPass").addEventListener("click",function(){
    var copyText = document.getElementById("payload_spoiler");
    var div = document.body.createTextRange();
    div.moveToElementText(copyText);
    div.select();
    document.execCommand("Copy");
    alert("Password was copied to clipboard!");
    document.body.removeChild(div);
    return false;
  });
  
(function(){
    new Clipboard('#copyButton');
})();