# WebView API Documentation

## Table of Contents
- [WebView API Documentation](#webview-api-documentation)
  - [Table of Contents](#table-of-contents)
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