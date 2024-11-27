# solar2d_webview_enhanced
An enhanced WebView for Solar2D

This project consists of two main parts:

## Solar2d WebView Extended API
We've extended the WebView API ([labolado/corona](https://github.com/labolado/corona)) with new methods and events to make it more powerful. For detailed documentation, see [docs/webview_api.md](docs/webview_api.md).

Note: The project (https://github.com/labolado/corona) provides two Solar2D builds:
1. Solar2D 202x.xxxx.b3.vx build:
   - Includes Box2D 3.0 physics engine
2. Solar2D 202x.xxxx.vx build:
   - Matches official Solar2D release

Choose the appropriate build based on your project's requirements.

Added APIs include:
- registerCallback: Register Lua functions that can be called from JavaScript
- on: Listen for events sent from JavaScript
- send: Send events to JavaScript
- injectJS: Inject JavaScript code into WebView

Key Features:
- Two-way Communication: Easy data exchange between Lua and JavaScript
- Type Conversion: Automatic data type conversion between Lua and JavaScript
- Event System: Event-based communication mechanism
- Code Injection: Dynamic JavaScript code injection support

NativeBridge API:
- callNative: Call registered Lua callbacks
- sendToLua: Send events to Lua
- on: Listen for events from Lua

Examples demonstrating the usage of the new WebView API can be found in webview_basic_test and webview_advanced_test.

## WebView Enhanced Module
We provide an enhanced module (webview_enhanced) for easier WebView usage. For detailed documentation, see [docs/webview_enhanced_api.md](docs/webview_enhanced_api.md).

Key Features:
1. Enhanced Script Management
   - evaluateJS: Execute JavaScript code immediately with automatic error handling
   - addGlobalScript: Add scripts that execute on every page load
   - Automatic script queue management

2. XMLHttpRequest Rewriting (Optional)
   - Handle all XMLHttpRequest operations in Lua
   - Maintain standard XMLHttpRequest interface
   - Support both synchronous and asynchronous requests
   - Complete request and response control

Usage Example:
```lua
local WebViewEnhanced = require("webview_enhanced")

-- Create enhanced WebView (XHR rewriting optional)
local webView = WebViewEnhanced.createWebView({
    rewriteXHR = true  -- defaults to false
})

-- Execute JavaScript code
webView:evaluateJS("document.body.style.backgroundColor = 'red'")

-- Add global script
webView:addGlobalScript([[
    console.log('Page loaded at:', new Date().toLocaleTimeString());
]])

-- Handle XMLHttpRequest operations (when enabled)
webView:setXHRHandler(function(request)
    return {
        status = 200,
        statusText = "OK",
        body = "Response from Lua"
    }
end)
```

Complete examples and test cases can be found in the project.
  