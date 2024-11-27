# WebView API Documentation

## Table of Contents

### Base WebView API
- [WebView API Documentation](#webview-api-documentation)
  - [Table of Contents](#table-of-contents)
    - [Base WebView API](#base-webview-api)
    - [Enhanced WebView API](#enhanced-webview-api)
  - [Core Methods](#core-methods)
    - [registerCallback](#registercallback)
    - [on](#on)
    - [send](#send)
    - [injectJS](#injectjs)
  - [NativeBridge API](#nativebridge-api)
    - [Initialization](#initialization)
    - [callNative](#callnative)
    - [sendToLua](#sendtolua)
    - [on](#on-1)
  - [Data Type Conversion](#data-type-conversion)
    - [Lua to JavaScript](#lua-to-javascript)
    - [JavaScript to Lua](#javascript-to-lua)
  - [Complete Example](#complete-example)
    - [Lua Code](#lua-code)
    - [HTML Code](#html-code)
- [WebView Enhanced API Documentation](#webview-enhanced-api-documentation)
  - [Enhanced Methods](#enhanced-methods)
    - [evaluateJS](#evaluatejs)
    - [addGlobalScript](#addglobalscript)
  - [Creating Enhanced WebView](#creating-enhanced-webview)
  - [Complete Example](#complete-example-1)
  - [Best Practices](#best-practices)
  - [Important Notes](#important-notes)

### Enhanced WebView API
1. [Enhanced Methods](#enhanced-methods)
   - [evaluateJS](#evaluatejs)
   - [addGlobalScript](#addglobalscript)
2. [Creating Enhanced WebView](#creating-enhanced-webview)
3. [Complete Example (Enhanced)](#complete-example-1)
4. [Best Practices](#best-practices)
5. [Important Notes](#important-notes)

---

[保持原有文档的所有内容，从 Core Methods 开始...]

## Core Methods

### registerCallback
Register a callback function that can be called from JavaScript.

```lua
webView:registerCallback("methodName", function(data)
    -- data: JavaScript data automatically converted to Lua types
    print("Received data:", json.prettify(data))
    
    -- Return value will be converted to JavaScript types
    return {
        message = "Response from Lua",
        timestamp = os.time(),
        received = data
    }
end)
```

### on
Listen for events sent from JavaScript.

```lua
webView:on("eventName", function(data)
    -- data: Event data from JavaScript
    print("Received event:", json.prettify(data))
    
    -- Send response back
    webView:send("responseEvent", {
        message = "Event processed",
        timestamp = os.time(),
        originalData = data
    })
end)
```

### send
Send events to JavaScript.

```lua
webView:send("eventName", {
    message = "Event from Lua",
    timestamp = os.time()
})
```

### injectJS
Inject JavaScript code into WebView.

```lua
webView:injectJS([[
    // Injected code can access DOM
    var target = document.getElementById("targetId");
    if (target) {
        target.innerHTML = "Updated by injection";
        target.style.backgroundColor = "#" + Math.floor(Math.random()*16777215).toString(16);
    }
    
    // Can use NativeBridge
    NativeBridge.sendToLua("injectionComplete", {
        success: true,
        time: new Date().toLocaleTimeString()
    });
]])
```

Important Notes:
1. Must inject after NativeBridge is ready (in onNativeBridgeReady)
2. Check for DOM element existence
3. Handle multiple executions
4. Avoid global namespace pollution

Best Practice:
```javascript
window.onNativeBridgeReady = function() {
    // Safe to inject JavaScript here
    webView:injectJS([[
        // Your injection code
    ]]);
};
```

## NativeBridge API

### Initialization
```javascript
window.onNativeBridgeReady = function() {
    // NativeBridge is ready
    console.log("NativeBridge ready");
    initializeFeatures();
};
```

### callNative
Call registered Lua callbacks.

```javascript
// Call Lua function
NativeBridge.callNative("methodName", {
    message: "Test message",
    timestamp: Date.now()
}).then(result => {
    console.log("Response from Lua:", result);
}).catch(error => {
    console.error("Error:", error);
});
```

### sendToLua
Send events to Lua.

```javascript
// Send event to Lua
NativeBridge.sendToLua("eventName", {
    message: "Event from JS",
    timestamp: Date.now()
});
```

### on
Listen for events from Lua.

```javascript
// Listen for Lua events
NativeBridge.on("eventName", function(data) {
    console.log("Received from Lua:", data);
});
```

## Data Type Conversion

### Lua to JavaScript
| Lua Type | JavaScript Type | Notes |
|----------|----------------|-------|
| number | number | Both integers and floats preserved |
| string | string | Including empty strings and Unicode |
| boolean | boolean | Direct true/false mapping |
| table (array) | Array | Sequential tables become arrays |
| table (object) | Object | Hash tables become objects |
| nil | undefined | nil becomes undefined |

### JavaScript to Lua
| JavaScript Type | Lua Type | Notes |
|----------------|----------|-------|
| number | number | Both integers and floats preserved |
| string | string | Including empty strings and Unicode |
| boolean | boolean | Direct mapping |
| Array | table | Becomes table with numeric keys |
| Object | table | Becomes hash table |
| null/undefined | nil | Both become nil |
| Date | string | Becomes ISO date string |
| Function | nil | Functions not preserved |

Edge Cases:
1. Sparse arrays preserve gaps: `[1,,3]` → `{1, nil, 3}`
2. Deep nesting is supported for both objects and arrays
3. Complex types (Function, Symbol) become nil
4. Date objects are converted to strings

## Complete Example

### Lua Code
```lua
local json = require("json")

local webView = native.newWebView(
    display.contentCenterX,
    display.contentCenterY,
    display.actualContentWidth,
    display.actualContentHeight
)

webView:registerCallback("getDeviceInfo", function()
    return {
        platform = system.getInfo("platform"),
        version = system.getInfo("architectureInfo"),
        language = system.getPreference("locale", "language"),
        deviceModel = system.getInfo("model")
    }
end)

webView:registerCallback("consoleLog", function(data)
    print("[JS]", data.message)
end)

webView:on("buttonClicked", function(data)
    webView:send("buttonResponse", {message = "Received click for button " .. data.buttonId})
end)

local function injectJS()
    webView:injectJS[[
    function updateDeviceInfo() {
        NativeBridge.callNative("getDeviceInfo").then(info => {
            document.getElementById("deviceInfo").innerHTML = 
                `Platform: ${info.platform}<br>
                 Version: ${info.version}<br>
                 Language: ${info.language}<br>
                 Model: ${info.deviceModel}`;
        });
    }

    ["updateButton", "greetButton"].forEach(id => {
        document.getElementById(id).addEventListener('click', () => {
            if(id === "updateButton") updateDeviceInfo();
            NativeBridge.sendToLua("buttonClicked", {buttonId: id.replace("Button", "")});
        });
    });

    NativeBridge.on("buttonResponse", data => {
        document.getElementById("response").textContent = data.message;
    });
    ]]
end

webView:request("index.html", system.ResourceDirectory)
webView:addEventListener("urlRequest", function(event)
    if event.type == "loaded" then injectJS() end
end)
```

### HTML Code
```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
     <script>
        window.onNativeBridgeReady = function() {
            console.log("NativeBridge is ready!");
            updateDeviceInfo();  
        }
    </script>
</head>
<body>
    <div id="deviceInfo"></div>
    <button id="updateButton">Update Info</button>
    <button id="greetButton">Greet</button>
    <div id="response"></div>
</body>
</html>
```
# WebView Enhanced API Documentation

WebView Enhanced extends the base WebView functionality with enhanced script management capabilities.

## Enhanced Methods

### evaluateJS
Immediately executes JavaScript code with automatic error handling and script queuing support.

```lua
webView:evaluateJS([[
    // JavaScript code to execute
    document.body.style.backgroundColor = 'lightblue';
    console.log('Background color changed');
]])
```

Features:
- Automatic error handling wrapper
- Scripts are queued if WebView is not loaded
- Uses IIFE to avoid global namespace pollution

### addGlobalScript
Adds a script that will be executed on every page load.

```lua
webView:addGlobalScript([[
    // This script will run on every page load
    console.log('Global script executed');
    document.body.classList.add('enhanced-view');
]])
```

Features:
- Scripts are permanently stored and auto-executed after each page load
- Automatic error handling wrapper
- Uses IIFE to avoid global namespace pollution
- Executes immediately if WebView is already loaded

## Creating Enhanced WebView

Use the WebViewEnhanced module to create a WebView with enhanced capabilities:

```lua
local WebViewEnhanced = require("webview_enhanced")

local webView = WebViewEnhanced.createWebView({
    x = display.contentCenterX,
    y = display.contentCenterY,
    width = display.actualContentWidth,
    height = display.actualContentHeight
})
```

## Complete Example

```lua
local WebViewEnhanced = require("webview_enhanced")

-- Create enhanced WebView
local webView = WebViewEnhanced.createWebView()

-- Add global script
webView:addGlobalScript([[
    console.log('Page loaded at:', new Date().toLocaleTimeString());
    document.body.classList.add('enhanced-view');
]])

-- Register callback for user interaction
webView:registerCallback("updateTheme", function(data)
    webView:evaluateJS(string.format([[
        document.body.style.backgroundColor = '%s';
        document.body.style.color = '%s';
    ]], data.background, data.textColor))
    return { success = true }
end)

-- Load page
webView:request("index.html", system.ResourceDirectory)
```

## Best Practices

1. Script Execution Timing
```lua
-- Not recommended: Execute before page load
webView:evaluateJS("document.body.style.backgroundColor = 'red'")

-- Recommended: Execute after NativeBridge is ready
webView:addGlobalScript([[
    window.onNativeBridgeReady = function() {
        document.body.style.backgroundColor = 'red';
    };
]])
```

2. Error Handling
```lua
-- evaluateJS and addGlobalScript include automatic error handling
webView:evaluateJS([[
    // Errors won't affect other code execution
    nonexistentFunction();
    console.log('This will still execute');
]])
```

3. Avoiding Global Pollution
```lua
-- Recommended: Use IIFE pattern
webView:addGlobalScript([[
    (function() {
        var privateVar = 'hidden';
        window.publicAPI = {
            doSomething: function() {
                console.log(privateVar);
            }
        };
    })();
]])
```

4. Script Queue Management
```lua
-- Scripts are executed in order
webView:evaluateJS("console.log('First')")
webView:evaluateJS("console.log('Second')")
webView:evaluateJS("console.log('Third')")
```

## Important Notes

1. evaluateJS and addGlobalScript handle errors automatically, no need for extra try-catch
2. Global scripts execute on every page load, avoid redundant operations
3. Use evaluateJS for conditional script execution
4. Scripts added before page load are queued and executed in order

### XMLHttpRequest Rewriting

Enable and handle XMLHttpRequest operations in WebView. This feature is disabled by default.

```lua
-- Create WebView with XMLHttpRequest rewriting enabled
local webView = WebViewEnhanced.createWebView({
    rewriteXHR = true
})

-- Set handler for XMLHttpRequest operations
webView:setXHRHandler(function(request)
    -- request: {
    --     id = "unique_request_id",
    --     method = "GET/POST/...",
    --     url = "request_url",
    --     headers = { header_key = header_value },
    --     body = "request_body",
    --     async = true/false
    -- }
    
    -- Must return a response object:
    return {
        status = 200,
        statusText = "OK",
        headers = {
            ["Content-Type"] = "application/json"
        },
        body = "response_body"
    }
end)
```

Example with different response scenarios:
```lua
webView:setXHRHandler(function(request)
    -- Handle GET request
    if request.method == "GET" then
        return {
            status = 200,
            statusText = "OK",
            headers = {
                ["Content-Type"] = "application/json"
            },
            body = json.encode({
                message = "GET request handled",
                url = request.url
            })
        }
    end
    
    -- Handle POST request
    if request.method == "POST" then
        return {
            status = 201,
            statusText = "Created",
            body = json.encode({
                message = "Resource created",
                data = json.decode(request.body)
            })
        }
    end
    
    -- Handle error case
    return {
        status = 400,
        statusText = "Bad Request",
        body = "Invalid request method"
    }
end)
```

The rewritten XMLHttpRequest maintains the standard XMLHttpRequest interface in JavaScript:
```javascript
// JavaScript code remains unchanged
const xhr = new XMLHttpRequest();
xhr.open("GET", "https://api.example.com/data");
xhr.onreadystatechange = function() {
    if (xhr.readyState === 4) {
        console.log(xhr.status, xhr.responseText);
    }
};
xhr.send();
```

Important Notes:
1. XMLHttpRequest rewriting is disabled by default
2. All XMLHttpRequest operations will be handled by the Lua handler when enabled
3. The handler must return a response object with required fields
4. Supports both synchronous and asynchronous requests
5. Maintains standard XMLHttpRequest behavior in JavaScript