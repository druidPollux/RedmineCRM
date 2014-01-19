function jsZenEdit(textarea, title, placeholder) {
  if (!document.createElement) { return; }
  
  if (!textarea) { return; }
  
  if ((typeof(document["selection"]) == "undefined")
  && (typeof(textarea["setSelectionRange"]) == "undefined")) {
    return;
  }
  this.textarea = textarea
  this.textarea.setAttribute('placeholder', placeholder);
  this.editor = this.textarea.parentNode

  var button = document.createElement('button');
  button.setAttribute('type','button');
  button.tabIndex = 200;
  button.className = "jstb_zenedit";
  button.title = title || "Zen";

  var button_theme = document.createElement('button');
  button_theme.setAttribute('type','button');
  button_theme.tabIndex = 200;
  button_theme.className = "jstb_zenedit theme";
  button_theme.title = title || "Zen";

  document.onkeydown = function(evt) {
      evt = evt || window.event;
      if (evt.keyCode == 27) {
          $('.jstEditor.zen').removeClass('zen');
          $('html.zen').removeClass('zen');
      }
  };

  button.onclick = function() { 
    try { 
      $(this).parent('.jstEditor').toggleClass('zen'); 
      $(textarea).removeAttr("style")
      $('html').toggleClass('zen');
      $(textarea).focus();
    } catch (e) {} 
    return false; 
  };

  button_theme.onclick = function() { 
    try { 
      $(this).parent('.jstEditor').toggleClass('dark-theme'); 
      $(textarea).focus();
    } catch (e) {} 
    return false; 
  };  

  this.editor.appendChild(button);
  this.editor.appendChild(button_theme);
}
