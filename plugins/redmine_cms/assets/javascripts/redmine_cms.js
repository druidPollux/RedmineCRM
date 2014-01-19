    function isFullScreen(cm) {
      return /\bCodeMirror-fullscreen\b/.test(cm.getWrapperElement().className);
    }
    function winHeight() {
      return window.innerHeight || (document.documentElement || document.body).clientHeight;
    }

    function setWordWrap(cm)  {
      cm.setOption("lineWrapping", !cm.options.lineWrapping) 
    }


    function setFullScreen(cm, full) {
      var wrap = cm.getWrapperElement();
      if (full) {
        wrap.className += " CodeMirror-fullscreen";
        wrap.style.height = winHeight() + "px";
        document.documentElement.style.overflow = "hidden";
      } else {
        wrap.className = wrap.className.replace(" CodeMirror-fullscreen", "");
        wrap.style.height = "";
        document.documentElement.style.overflow = "";
      }
      cm.refresh();
    }
    CodeMirror.on(window, "resize", function() {
      var showing = document.body.getElementsByClassName("CodeMirror-fullscreen")[0];
      if (!showing) return;
      showing.CodeMirror.getWrapperElement().style.height = winHeight() + "px";
    });

  CodeMirror.defineMode("liquid", function(config, parserConfig) {
    var liquidOverlay = {
      token: function(stream, state) {
        var ch;
        if (stream.match("{{")) {
          while ((ch = stream.next()) != null)
            if (ch == "}" && stream.next() == "}") break;
          stream.eat("}");
          return "liquid";
        }
        while (stream.next() != null && !stream.match("{{", false)) {}
        return null;
      }
    };
    return CodeMirror.overlayMode(CodeMirror.getMode(config, parserConfig.backdrop || "text/html"), liquidOverlay);
  });

  CodeMirror.defineMode("liquid1", function(config, parserConfig) {
    var liquid1Overlay = {
      token: function(stream, state) {
        var ch;
        if (stream.match("{%")) {
          while ((ch = stream.next()) != null)
            if (ch == "%" && stream.next() == "}") break;
          stream.eat("}");
          return "liquid";
        }
        while (stream.next() != null && !stream.match("{%", false)) {}
        return null;
      }
    };
    return CodeMirror.overlayMode(CodeMirror.getMode(config, parserConfig.backdrop || "liquid"), liquid1Overlay);
  });

