$(function(){
    var spacing = 0,
        shouldAnimate = $.browser.webkit || $.browser.mozilla, //$("html").hasClass("csstransitions"),
        isAnimating = false;
    
    var _scrollbarWidth = null;
    var scrollbarWidth = function() {
        if (_scrollbarWidth != null)
            return _scrollbarWidth;
        
        var body = $("body"),
            initialValue = body.css("overflow-y");
        
        // Has Scrollbar
        body.css("overflow-y", "scroll");
        withScrollbar = $('body').innerWidth();
        
        // Does not have
        body.css("overflow-y", "hidden")
        withoutScrollbar = $('body').innerWidth()
        
        // Reset to initial
        body.css("overflow-y", initialValue);
        
        _scrollbarWidth = withoutScrollbar - withScrollbar;
        
        return _scrollbarWidth;
    };
    
    var scaleDifference = function(small, large) {
        return small.width() / large.width();
    };
    
    var positionDifference = function(small, large) {
        var smallOffset = small.offset(),
            largeOffset = large.offset();
        
        // Adjust for any borders
        //smallOffset.top += parseInt(small.css("border-top-width"));
        //smallOffset.left += parseInt(small.css("border-left-width"));
        
        var delta = {
            "top": Math.round(smallOffset.top) - Math.round(largeOffset.top),
            "left": Math.round(smallOffset.left) - Math.round(largeOffset.left)
        }
        
        return delta;
    };
    
    $("a.zoom").each(function(){
        var el = $(this),
            imageSrc = el.attr("href");
        
        var container = $("<div></div>").addClass("zoom-container");
        $("body").append(container);
        
        var overlay = $("<div></div>").addClass("overlay");
        container.append(overlay);
        
        var originalImage = $("img", el);
        
        // Can't use clone
        var copiedOriginalImage = $("<img />");
        copiedOriginalImage
            .addClass("copy")
            .attr("width", originalImage.attr("width"))
            //.attr("height", originalImage.attr("height"))
            .attr("src", originalImage.attr("src"));
            
        container.append(copiedOriginalImage)
        
        // Pre-load image
        var img = new Image();
        
        $(img).load(function(){
            container.append(img);
            
            var _img = $(this);
            _img.addClass("large");
            _img.data("maxSize", $(el).attr("maxSize"));
        });
        
        img.src = imageSrc;
        
        // Click
        el.click(function(event){
            event.preventDefault();
        });
        
        // Use mouse down so it feels faster
        el.mousedown(function(event){
            event.preventDefault();
            
            container.click(closeZoomedImage);
            container.children().click(closeZoomedImage);
            
            enableScrolling(false);
            
            var originalImage = $("img", el),
                copyImage = $("img.copy", container),
                largeImage = $("img.large", container);
            
            container.show()
            layoutCurrentZoomedImage();
            
            if (shouldAnimate) {
                
                if (isAnimating)
                    return;
                    
                isAnimating = true;
                
                // Scale difference
                var scaleCSS = "scale(" + scaleDifference(copyImage, largeImage) + ")";
                
                // Calculate this early
                var smallToLargeScale = scaleDifference(largeImage, copyImage);
                
                // Required for Opera bug
                //copyImage.css("opacity", 0);
                
                // Position difference
                var delta = positionDifference(originalImage, copyImage);
                copyImage.css("-webkit-transform", "translate3d(" + delta.left + "px, " + delta.top + "px, 0px) ");
                largeImage.css("-webkit-transform", "translate3d(" + delta.left + "px, " + delta.top + "px, 0px) " + scaleCSS);
                
                copyImage.css("-moz-transform", "translate(" + delta.left + "px, " + delta.top + "px) ");
                largeImage.css("-moz-transform", "translate(" + delta.left + "px, " + delta.top + "px) " + scaleCSS);
                
                copyImage.css("-o-transform", "translate(" + delta.left + "px, " + delta.top + "px) ");
                largeImage.css("-o-transform", "translate(" + delta.left + "px, " + delta.top + "px) " + scaleCSS);
                
                largeImage.data("small-version", originalImage);
                
                setTimeout(function(){
                    
                    // Required for Opera bug
                    //copyImage.css("opacity", 1.0);
                    
                    // Animation end callback
                    var animationEnd = function() {
                        largeImage.removeClass("animating");
                        copyImage.removeClass("animating");
                        isAnimating = false;
                        
                        copyImage.hide();
                    };
                    
                    $("img.large", container).one("webkitTransitionEnd", animationEnd);
                    $("img.large", container).one("transitionend", animationEnd);
                    $("img.large", container).one("oTransitionEnd", animationEnd);
                    
                    largeImage.addClass("animating");
                    copyImage.addClass("animating");
                    container.addClass("shown");
                    
                    // Remove the translate, and scale the small image
                    copyImage.css("-webkit-transform", "scale(" + smallToLargeScale + ")");
                    copyImage.css("-moz-transform", "scale(" + smallToLargeScale + ")");
                    copyImage.css("-o-transform", "scale(" + smallToLargeScale + ")");
                    
                    // Reset the translate and scale on the large image
                    largeImage.css("-webkit-transform", "scale(1.0)");
                    largeImage.css("-moz-transform", "scale(1.0)");
                    largeImage.css("-o-transform", "scale(1.0)");
                    
                
                }, 0);
                
            } else {
                container.addClass("shown");
            }
        });
    });
    
    var currentContainer = function() {
        return $("div.zoom-container").filter(":visible");
    };
    
    var enableScrolling = function(shouldEnable) {
        var currentScrollbarWidth = scrollbarWidth();

        if ($.browser.msie) {
            $("html").css("overflow", shouldEnable ? "auto" : "hidden");
        }
        $("body").css("overflow", shouldEnable ? "auto" : "hidden");
        $("body").css("margin-right", shouldEnable ? "auto" : currentScrollbarWidth);
    }
    
    var closeZoomedImage = function() {
        
        var container = currentContainer(),
            largeImage = $("img.large", container),
            copyImage = $("img.copy", container),
            originalImage = largeImage.data("small-version");
        
        if (shouldAnimate) {
            
            if (isAnimating)
                return;
                
            isAnimating = true;
        
            copyImage.show();
            
            // Create a copy of the image at its small size,
            // for use in figuring out how much we should move it
            // while animating.
            var originalImageFrame = $("<div></div>")
            originalImageFrame.css({
                "width": originalImage.width(),
                "height": originalImage.height(),
                "position": "absolute",
                "top": "50%",
                "left": "50%",
                "margin-top": -(originalImage.height() / 2),
                "margin-left": -(originalImage.width() / 2),
                "opacity": 0.0
            });
            container.append(originalImageFrame);
            
            
            var smallToLargeScale = scaleDifference(largeImage, copyImage);
            copyImage.css("-webkit-transform", "scale(" + smallToLargeScale + ")");
            copyImage.css("-moz-transform", "scale(" + smallToLargeScale + ")");
            copyImage.css("-o-transform", "scale(" + smallToLargeScale + ")");

            var positionDelta = positionDifference(originalImage, originalImageFrame);
            
            // Remove helper element
            originalImageFrame.remove();
        
            // Run animation
            copyImage.addClass("animating");
            largeImage.addClass("animating");
            container.removeClass("shown");

            // Scale down
            var scale = scaleDifference(originalImage, largeImage);
            
            setTimeout(function(){
                largeImage.css("-webkit-transform", "translate3d(" + positionDelta.left + "px, " + positionDelta.top + "px, 0px) scale(" + scale + ")");
                largeImage.css("-moz-transform", "translate(" + positionDelta.left + "px, " + positionDelta.top + "px) scale(" + scale + ")");
                largeImage.css("-o-transform", "translate(" + positionDelta.left + "px, " + positionDelta.top + "px) scale(" + scale + ")");
                
                copyImage.css("-webkit-transform", "translate3d(" + positionDelta.left + "px, " + positionDelta.top + "px, 0px)");
                copyImage.css("-moz-transform", "translate(" + positionDelta.left + "px, " + positionDelta.top + "px)");
                copyImage.css("-o-transform", "translate(" + positionDelta.left + "px, " + positionDelta.top + "px)");
                
                // Animation end callback
                var animationEnd = function() {
                    container.hide();
                    
                    largeImage.removeClass("animating");
                    copyImage.removeClass("animating");
                    
                    largeImage.css("-webkit-transform", "none");
                    largeImage.css("-moz-transform", "none");
                    largeImage.css("-o-transform", "none");
                    
                    copyImage.css("-webkit-transform", "none");
                    copyImage.css("-moz-transform", "none");
                    copyImage.css("-o-transform", "none");
                    
                    isAnimating = false;
                    
                    enableScrolling(true);
                };
                
                $("img.large", container).one("webkitTransitionEnd", animationEnd);
                $("img.large", container).one("transitionend", animationEnd);
                $("img.large", container).one("oTransitionEnd", animationEnd);
            }, 0);
            
        } else {
            enableScrolling(true);
            container.removeClass("shown");
            container.hide();
        }
    };
    
    var layoutCurrentZoomedImage = function() {
        var container = currentContainer();
        
        if (!container.length)
            return;
        
        var large = $("img.large", container),
            _window = $(window),
            windowSize = {
                "width": _window.width(),
                "height": _window.height()
            }
            
        var maxSize = large.data("maxSize").split("x"),
            imgMaxSize = {
                "width": maxSize[0],
                "height": maxSize[1]
            },
            widthDimension = imgMaxSize.width / imgMaxSize.height;
        
        // Set proposed width
        large.width(windowSize.width - (2 * spacing));
        
        // Make sure the image doesnt become higher than the window
        if (large.height() > windowSize.height) {
            large.width(widthDimension * windowSize.height);
        }
        
        // Make sure the width doesn't exceed maxSize
        if (large.width() > imgMaxSize.width)
            large.width(imgMaxSize.width);
            
        // Make sure the height doesn't exceed maxSize
        if (large.height() > imgMaxSize.height)
            large.height(imgMaxSize.height);
        
        var center = [large, $("img.copy", container)];
        for (var i = 0; i < center.length; i++) {
            center[i].css("margin-top", -(center[i].height() / 2));
            center[i].css("margin-left", -(center[i].width() / 2));
        }
        //img.css("margin-left", spacing);
        
        container.css("top", $(window).scrollTop());
        container.height(windowSize.height);
        
    };
    
    $(window).resize(layoutCurrentZoomedImage);
});
