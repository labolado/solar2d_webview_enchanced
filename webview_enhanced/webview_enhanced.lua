--[[
WebView Enhanced Module
======================

A module that extends Solar2d's WebView with additional features.

Usage:
------
local WebViewEnhanced = require("webview_enhanced")

-- Create enhanced WebView
local webView = WebViewEnhanced.createWebView({
    x = display.contentCenterX,
    y = display.contentCenterY,
    width = display.actualContentWidth,
    height = display.actualContentHeight,
    rewriteXHR = false  -- Enable XHR rewriting if needed
})

Features:
---------
1. Script Management
   - evaluateJS: Execute JavaScript with error handling
   - addGlobalScript: Add scripts that run on every page load
   
2. XMLHttpRequest Rewriting (optional)
   - Intercept and handle XHR requests in Lua
   - Enable by setting rewriteXHR = true

Examples:
---------
-- Execute JavaScript
webView:evaluateJS([=[
    document.body.style.backgroundColor = 'red';
]=])

-- Add global script
webView:addGlobalScript([=[
    console.log('Page loaded at:', new Date());
]=])

-- Handle XHR requests
webView:setXHRHandler(function(request)
    return {
        status = 200,
        statusText = "OK",
        body = "Response from Lua"
    }
end)

For more details, see docs/webview_enhanced_api.md
]]

local json = require("json")
local M = {}

-- WebView extension methods
local WebViewExtension = {
    -- Evaluates JavaScript code with error handling
    -- @param script: JavaScript code to execute
    evaluateJS = function(self, script)
        local wrappedScript = string.format([[
            (function() {
                try {
                    %s
                } catch(e) {
                    console.error('[evaluateJS] Error:', e.message);
                }
            })();
        ]], script)

        -- Execute immediately if WebView is loaded, otherwise queue the script
        if self._isLoaded then
            self:injectJS(wrappedScript)
        else
            self._scriptQueue = self._scriptQueue or {}
            table.insert(self._scriptQueue, wrappedScript)
        end
    end,

    -- Adds a script that will be executed on every page load
    -- @param script: JavaScript code to execute on each page load
    addGlobalScript = function(self, script)
        local wrappedScript = string.format([[
            (function() {
                try {
                    %s
                } catch(e) {
                    console.error('[GlobalScript] Error:', e.message);
                }
            })();
        ]], script)

        -- Store script in global scripts array
        self._globalScripts = self._globalScripts or {}
        table.insert(self._globalScripts, wrappedScript)
        
        -- Execute immediately if WebView is already loaded
        if self._isLoaded then
            self:injectJS(wrappedScript)
        end
    end,

    -- Sets handler for XMLHttpRequest operations
    -- @param handler: Function to handle XHR requests
    setXHRHandler = function(self, handler)
        self._xhrHandler = handler
        
        -- Only inject code if XHR rewriting is enabled
        if not self._xhrEnabled then
            print("Warning: XHR rewriting is not enabled. Please create WebView with rewriteXHR=true")
            return
        end
        
        -- Inject XHR rewriting code
        self:addGlobalScript([[
            (function() {
                // Store original XMLHttpRequest
                const OriginalXHR = window.XMLHttpRequest;
                
                // Create custom XMLHttpRequest implementation
                function CustomXHR() {
                    this.readyState = 0;
                    this.status = 0;
                    this.statusText = '';
                    this.response = null;
                    this.responseText = '';
                    this.responseType = '';
                    this.timeout = 0;
                    this.withCredentials = false;
                    
                    this.onreadystatechange = null;
                    this.onerror = null;
                    this.onload = null;
                    this.onabort = null;
                    this.ontimeout = null;
                    
                    this._headers = {};
                    this._requestId = Date.now() + Math.random().toString(36);
                }
                
                CustomXHR.prototype.open = function(method, url, async = true) {
                    this._method = method;
                    this._url = url;
                    this._async = async;
                    this.readyState = 1;
                    if (this.onreadystatechange) this.onreadystatechange();
                };
                
                CustomXHR.prototype.setRequestHeader = function(name, value) {
                    this._headers[name] = value;
                };
                
                CustomXHR.prototype.send = function(body) {
                    const xhr = this;
                    
                    // Prepare request data
                    const request = {
                        id: this._requestId,
                        method: this._method,
                        url: this._url,
                        headers: this._headers,
                        body: body,
                        async: this._async
                    };
                    
                    // Send to Lua handler
                    NativeBridge.callNative('_handleXHR', request).then(response => {
                        // Update XHR state
                        xhr.readyState = 4;
                        xhr.status = response.status;
                        xhr.statusText = response.statusText;
                        xhr.responseText = response.body;
                        xhr.response = response.body;
                        
                        // Trigger events
                        if (xhr.onreadystatechange) xhr.onreadystatechange();
                        if (xhr.onload) xhr.onload();
                    }).catch(error => {
                        if (xhr.onerror) xhr.onerror(error);
                    });
                };
                
                CustomXHR.prototype.abort = function() {
                    this.readyState = 0;
                    if (this.onabort) this.onabort();
                };
                
                // Replace global XMLHttpRequest
                window.XMLHttpRequest = CustomXHR;
            })();
        ]])
    end,

    -- Internal method: Handle XHR requests
    -- @param request: XHR request object from JavaScript
    -- @return: Response object with status, statusText, and body
    _handleXHR = function(self, request)
        if not self._xhrHandler then
            return {
                status = 500,
                statusText = "No XHR handler set",
                body = "XMLHttpRequest handler not configured"
            }
        end
        
        -- Call user-defined handler
        local success, response = pcall(self._xhrHandler, request)
        if not success then
            return {
                status = 500,
                statusText = "Internal Error",
                body = "XHR handler error: " .. tostring(response)
            }
        end
        
        return response
    end
}

-- Creates an enhanced WebView with additional features
-- @param options: Table with x, y, width, height, and rewriteXHR options
-- @return: Enhanced WebView instance
function M.createWebView(options)
    options = options or {}
    -- XHR rewriting disabled by default
    options.rewriteXHR = options.rewriteXHR or false
    
    local webView = native.newWebView(
        options.x or display.contentCenterX,
        options.y or display.contentCenterY,
        options.width or display.actualContentWidth,
        options.height or display.actualContentHeight
    )
    
    -- Add extension methods
    for k, v in pairs(WebViewExtension) do
        webView[k] = v
    end
    
    -- Initialize state
    webView._scriptQueue = {}
    webView._globalScripts = {}
    webView._isLoaded = false
    webView._xhrEnabled = options.rewriteXHR
    
    -- Register XHR handler callback
    if options.rewriteXHR then
        webView:registerCallback("_handleXHR", function(request)
            return webView:_handleXHR(request)
        end)
    end
    
    -- Handle page load events
    webView:addEventListener("urlRequest", function(event)
        if event.url then
            webView._isLoaded = false
        end
        
        if event.type == "loaded" then
            -- Execute global scripts
            for _, script in ipairs(webView._globalScripts) do
                webView:injectJS(script)
            end
            
            -- Execute queued scripts
            for _, script in ipairs(webView._scriptQueue) do
                webView:injectJS(script)
            end
            webView._scriptQueue = {}
            
            webView._isLoaded = true
        end
    end)

    return webView
end

return M