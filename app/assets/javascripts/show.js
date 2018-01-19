//CSP-Fix
document.getElementById("url").addEventListener("focus",function(){
    $(this).focus(); $(this).select();
  });

  document.getElementById("url").addEventListener("click",function(){
    $(this).select();
  });

document.getElementById("copyPass").addEventListener("click",function(){
    console.log("I work");
    var copyText = document.getElementById("payload spoiler");
    copyText.select();
    document.execCommand("Copy");
    alert("Password was copied to clipboard!");
    return false;
  });
  
(function(){
    new Clipboard('#copyButton');
})();