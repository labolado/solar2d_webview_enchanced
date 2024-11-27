local json = require("json")
local WebViewEnhanced = require("webview_enhanced")

print("\n[WebView Test Suite]")
print("===================")
print("Starting test suite initialization...")

-- Create WebView for testing
local webView = WebViewEnhanced.createWebView({
    rewriteXHR = true,
    x = display.contentCenterX,
    y = display.contentCenterY,
    width = display.actualContentWidth,
    height = display.actualContentHeight
})

print("[Init] WebView created successfully")

-- Set XHR handler
webView:setXHRHandler(function(request)
    print("\n[XHR Handler] ================")
    print("[XHR Handler] Received request:")
    print(json.prettify(request))
    
    -- Simulate different response scenarios
    if request.url:match("^https://api%.example%.com/data") then
        -- GET request test
        return {
            status = 200,
            statusText = "OK",
            headers = {
                ["Content-Type"] = "application/json"
            },
            body = json.encode({
                message = "GET request successful",
                timestamp = os.time(),
                received = request
            })
        }
    elseif request.url:match("^https://api%.example%.com/create") then
        -- POST request test
        return {
            status = 201,
            statusText = "Created",
            headers = {
                ["Content-Type"] = "application/json"
            },
            body = json.encode({
                message = "Resource created",
                timestamp = os.time(),
                received = request
            })
        }
    elseif request.url:match("^https://api%.example%.com/headers") then
        -- Custom headers test
        return {
            status = 200,
            statusText = "OK",
            headers = request.headers,
            body = json.encode({
                message = "Headers received",
                headers = request.headers
            })
        }
    elseif request.url:match("^https://api%.example%.com/async") then
        -- Async request test
        timer.performWithDelay(1000, function()
            return {
                status = 200,
                statusText = "OK",
                body = json.encode({
                    message = "Async request completed",
                    async = request.async
                })
            }
        end)
    elseif request.url:match("^https://api%.example%.com/sync") then
        -- Sync request test
        return {
            status = 200,
            statusText = "OK",
            body = json.encode({
                message = "Sync request completed",
                async = request.async
            })
        }
    elseif request.url:match("^https://invalid%-url%.example") then
        -- Error test
        return {
            status = 404,
            statusText = "Not Found",
            body = "Resource not found"
        }
    end
    
    -- Default response
    return {
        status = 400,
        statusText = "Bad Request",
        body = "Invalid request URL"
    }
end)

-- Add URL request listener for NativeBridge initialization
webView:addEventListener("urlRequest", function(event)
    print("\n[URL Event] ================")
    print("[URL Event] Type:", event.type)
    if event.type == "loaded" then
        print("[URL Event] Page loaded successfully")
        print("[URL Event] URL:", event.url)
        -- Inject NativeBridge ready check
        webView:injectJS([[
            if(window.onNativeBridgeReady) {
                console.log("Executing onNativeBridgeReady");
                onNativeBridgeReady();
            }
        ]])
        print("[URL Event] NativeBridge initialization code injected")
    elseif event.type == "failed" then
        print("[URL Event] Page load failed")
        print("[URL Event] Error:", event.errorMessage)
        print("[URL Event] URL:", event.url)
    end
    print("[URL Event] ================")
end)

-- NativeBridge API Tests
webView:registerCallback("testNativeBridge", function(data)
    print("\n[NativeBridge Test] ================")
    print("[NativeBridge Test] Called with data:")
    print(json.prettify(data))
    
    local response = {
        message = "Response from Lua NativeBridge test",
        timestamp = os.time(),
        received = data
    }
    
    print("[NativeBridge Test] Sending response:")
    print(json.prettify(response))
    print("[NativeBridge Test] ================")
    return response
end)

-- Core Methods Tests
webView:registerCallback("testCoreCallback", function(data)
    print("\n[Core Methods Test] ================")
    print("[Core Methods Test] Testing callback with data:")
    print(json.prettify(data))
    
    local response = {
        message = "Response from core methods test",
        timestamp = os.time(),
        received = data
    }
    
    print("[Core Methods Test] Sending response:")
    print(json.prettify(response))
    print("[Core Methods Test] ================")
    return response
end)

-- Event Handling Tests
webView:on("testEvent", function(data)
    print("\n[Event Test] ================")
    print("[Event Test] Received event data:")
    print(json.prettify(data))

    -- Add a small delay to simulate processing
    timer.performWithDelay(500, function()
        local response = {
            message = "Event received and processed",
            timestamp = os.time(),
            originalData = data
        }
        
        print("[Event Test] Sending response:")
        print(json.prettify(response))
        
        -- Inject console.log for JavaScript side visibility
        webView:injectJS(string.format([[
            console.log("[Event Test] Lua sending response:", %s);
        ]], json.encode(response)))
        
        webView:send("eventResponse", response)
    end)
    
    print("[Event Test] ================")
end)

-- Add handler for test core event
webView:on("testCoreEvent", function(data)
    print("\n[Core Event Test] ================")
    print("[Core Event Test] Received event data:")
    print(json.prettify(data))

    -- Inject console log
    webView:injectJS(string.format([[
        console.log("[Core Event Test] Processing event in Lua:", %s);
    ]], json.encode(data)))

    local response = {
        message = "Core event received and processed",
        timestamp = os.time(),
        originalData = data
    }
    
    print("[Core Event Test] Sending response:")
    print(json.prettify(response))
    
    -- Inject console log before sending response
    webView:injectJS(string.format([[
        console.log("[Core Event Test] Lua sending response:", %s);
    ]], json.encode(response)))
    
    webView:send("eventResponse", response)
    print("[Core Event Test] ================")
end)

-- Basic Communication Test
webView:registerCallback("getDeviceInfo", function()
    print("\n[Basic Communication Test] ================")
    print("[Basic Communication Test] getDeviceInfo called")
    
    local info = {
        platform = system.getInfo("platform"),
        version = system.getInfo("architectureInfo"),
        language = system.getPreference("locale", "language"),
        deviceModel = system.getInfo("model"),
        timestamp = os.time()
    }
    
    print("[Basic Communication Test] Sending device info:")
    print(json.prettify(info))
    print("[Basic Communication Test] ================")
    
    return info
end)

-- Data Type Conversion Tests
webView:registerCallback("testLuaTypes", function()
    print("\n[Type Test] Testing Lua to JS conversion")
    
    local testData = {
        -- Basic types
        number = 42,
        float = 3.14,
        string = "Hello",
        empty = "",
        boolean = true,
        null = nil,
        
        -- Complex types
        array = {1, 2, 3},
        object = {key = "value"},
        nested = {
            array = {1, 2, 3},
            object = {a = true}
        }
    }
    
    print("[Type Test] Sending data:", json.prettify(testData))
    return testData
end)

webView:registerCallback("testJSTypes", function(data)
    print("\n[Type Test] ================")
    print("[Type Test] Received data from JavaScript")
    
    -- Log received JavaScript types as Lua types
    print("[Type Test] Converted types in Lua:")
    local function inspectValue(value, indent)
        indent = indent or ""
        if type(value) == "table" then
            print(indent .. "table:")
            for k, v in pairs(value) do
                print(indent .. "  " .. tostring(k) .. ":", type(v))
                if type(v) == "table" then
                    inspectValue(v, indent .. "    ")
                end
            end
        else
            print(indent .. type(value) .. ":", value)
        end
    end
    
    inspectValue(data)
    print("[Type Test] ================")
    
    -- Return type information
    return {
        receivedTypes = {
            number = type(data.number),
            integer = type(data.integer),
            float = type(data.float),
            string = type(data.string),
            boolean = type(data.boolean),
            array = type(data.array),
            object = type(data.object),
            null = data.null == nil and "nil" or type(data.null),
            undefined = data.undefined == nil and "nil" or type(data.undefined)
        },
        arrayLength = data.array and #data.array or 0,
        objectKeys = data.object and table.concat(
            (function()
                local keys = {}
                for k in pairs(data.object) do
                    table.insert(keys, k)
                end
                return keys
            end)(),
            ", "
        ) or ""
    }
end)

webView:registerCallback("testEdgeCases", function(data)
    print("\n[Type Test] ================")
    print("[Type Test] Testing edge cases")
    print("[Type Test] Received edge case data:")
    print(json.prettify(data))
    
    -- Test array conversion
    local sparseArrayTest = {
        type = type(data.sparseArray),
        isSequential = #data.sparseArray == 3,
        content = data.sparseArray
    }
    print("[Type Test] Sparse array test:", json.prettify(sparseArrayTest))
    
    -- Test complex object conversion
    local deepNestedTest = {
        arrayDepth = #data.deepNested.array,
        objectExists = data.deepNested.object ~= nil,
        content = data.deepNested
    }
    print("[Type Test] Deep nested test:", json.prettify(deepNestedTest))
    
    local response = {
        sparseArrayTest = sparseArrayTest,
        deepNestedTest = deepNestedTest,
        dateObjectType = type(data.dateObject),
        functionType = type(data["function"])
    }
    
    print("[Type Test] Sending response:")
    print(json.prettify(response))
    print("[Type Test] ================")
    return response
end)

-- Update the requestTestEvent handler
webView:on("requestTestEvent", function(data)
    print("\n[Send Test] ================")
    print("[Send Test] Received request:")
    print(json.prettify(data))

    -- Add a small delay to simulate processing
    timer.performWithDelay(500, function()
        local response = {
            message = "Response to send test",
            timestamp = os.time(),
            originalData = data,
            status = "success"
        }
        
        print("[Send Test] Sending response:")
        print(json.prettify(response))
        
        -- Inject console log before sending response
        webView:injectJS(string.format([[
            console.log("[Send Test] Lua sending response:", %s);
        ]], json.encode(response)))
        
        webView:send("testEvent", response)
    end)
    
    print("[Send Test] ================")
end)

-- Test URL request events
webView:registerCallback("testLoadEvent", function()
    print("\n[URL Event Test] ================")
    print("[URL Event Test] Testing load event")
    
    -- Create a test WebView and load a valid page
    local testView = native.newWebView(0, 0, 100, 100)
    testView:request("about:blank")
    
    -- Remove test view after delay
    timer.performWithDelay(1000, function()
        testView:removeSelf()
    end)
    
    print("[URL Event Test] Test initiated")
    print("[URL Event Test] ================")
    return { success = true }
end)

webView:registerCallback("testFailEvent", function()
    print("\n[URL Event Test] ================")
    print("[URL Event Test] Testing fail event")
    
    -- Create a test WebView and try to load an invalid URL
    local testView = native.newWebView(0, 0, 100, 100)
    testView:request("invalid://url")
    
    -- Remove test view after delay
    timer.performWithDelay(1000, function()
        testView:removeSelf()
    end)
    
    print("[URL Event Test] Test initiated")
    print("[URL Event Test] ================")
    return { success = true }
end)

-- Update the injection test handler
webView:registerCallback("testInjection", function()
    print("\n[Injection Test] ================")
    print("[Injection Test] Starting injection")
    
    local js = [[
        (function() {
            console.log("[Injection Test] Executing injected code");
            
            var target = document.getElementById("injectionTarget");
            if (target) {
                // Update content with timestamp
                target.innerHTML = "Content updated by injection at: " + new Date().toLocaleTimeString();
                target.style.backgroundColor = "#" + Math.floor(Math.random()*16777215).toString(16);
                
                // Send result back to Lua
                NativeBridge.sendToLua("injectionComplete", {
                    success: true,
                    time: new Date().toLocaleTimeString(),
                    message: "Injection completed successfully"
                });
            } else {
                console.error("[Injection Test] Target element not found");
                NativeBridge.sendToLua("injectionComplete", {
                    success: false,
                    error: "Target element not found"
                });
            }
        })();
    ]]
    
    print("[Injection Test] Injecting JavaScript code")
    webView:injectJS(js)
    
    print("[Injection Test] ================")
    return { success = true }
end)

-- Update the triggerTestEvent handler in main.lua
webView:on("triggerTestEvent", function(data)
    print("\n[Event Listener Test] ================")
    print("[Event Listener Test] Received trigger request:")
    print(json.prettify(data))
    
    -- Send response immediately
    local response = {
        message = "Response to event listener test",
        timestamp = os.time(),
        originalData = data,
        status = "success"
    }
    
    print("[Event Listener Test] Sending response:")
    print(json.prettify(response))
    
    -- Send response back to JavaScript
    webView:send("testResponse", response)
    print("[Event Listener Test] ================")
end)

-- Enhanced Features Tests
webView:registerCallback("testEvaluateJS", function()
    print("\n[Enhanced Test] Testing evaluateJS")
    
    webView:evaluateJS([[
        const target = document.getElementById('evaluateTarget');
        target.textContent = 'Updated by evaluateJS at: ' + new Date().toLocaleTimeString();
        target.style.backgroundColor = '#' + Math.floor(Math.random()*16777215).toString(16);
        
        NativeBridge.sendToLua('scriptResult', {
            target: 'evaluate',
            success: true,
            time: new Date().toLocaleTimeString(),
            message: 'evaluateJS executed successfully'
        });
    ]])
    
    return { success = true }
end)

webView:registerCallback("testGlobalScript", function()
    print("\n[Enhanced Test] Testing addGlobalScript")
    
    webView:addGlobalScript([[
        const target = document.getElementById('globalTarget');
        if (target) {
            target.textContent = 'Updated by global script at: ' + new Date().toLocaleTimeString();
            target.style.backgroundColor = '#' + Math.floor(Math.random()*16777215).toString(16);
            
            NativeBridge.sendToLua('scriptResult', {
                target: 'global',
                success: true,
                time: new Date().toLocaleTimeString(),
                message: 'Global script executed'
            });
        }
    ]])
    
    return { success = true }
end)

-- Load the test suite
print("\n[Init] Loading test suite...")
webView:request("index.html", system.ResourceDirectory)
print("[Init] Test suite initialization complete")
print("===================\n")

-- 在现有代码后添加 Google 自动化测试入口
webView:registerCallback("testGoogleAutomation", function()
    print("\n[Google Test] Starting Google automation test")
    
    -- 创建新的 WebView 用于测试
    local testView = WebViewEnhanced.createWebView({
        x = display.contentCenterX,
        y = display.contentCenterY,
        width = display.actualContentWidth,
        height = display.actualContentHeight
    })
    
    -- 创建一个容器组
    local closeGroup = display.newGroup()

    -- Create rounded rectangle background for close button
    local closeBg = display.newRoundedRect(
        closeGroup,
        display.contentWidth - 60,
        40,
        100,
        40,
        8
    )
    closeBg:setFillColor(0.8, 0, 0, 0.9)

    -- Add text label
    local closeText = display.newText({
        parent = closeGroup,
        text = "BACK",
        x = display.contentWidth - 60,
        y = 40,
        font = native.systemFont,
        fontSize = 18
    })
    closeText:setFillColor(1, 1, 1)

    -- Add tap event
    closeGroup:addEventListener("tap", function()
        closeGroup:removeSelf()
        testView:removeSelf()
    end)

    -- Add touch feedback
    closeGroup:addEventListener("touch", function(event)
        if event.phase == "began" then
            closeBg:setFillColor(0.6, 0, 0, 0.9)
        elseif event.phase == "ended" or event.phase == "cancelled" then
            closeBg:setFillColor(0.8, 0, 0, 0.9)
        end
        return true
    end)
    
    -- Inject Matrix animation style
    testView:addGlobalScript([[
        (function(){
            const style = document.createElement('style');
            style.textContent = `
                /* Prevent scrollbar */
                body {
                    margin: 0;
                    overflow: hidden;
                }
                
                /* Matrix canvas - bottom layer */
                #matrix-canvas {
                    position: fixed;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    pointer-events: none;
                    z-index: -2;
                }
                
                /* Semi-transparent overlay - middle layer */
                .matrix-overlay {
                    position: fixed;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    background: rgba(0, 0, 0, 0.3);
                    pointer-events: none;
                    z-index: -1;
                }

                /* Ensure page content stays on top */
                body > *:not(#matrix-canvas):not(.matrix-overlay) {
                    position: relative;
                    z-index: 1;
                }

                /* Adjust Google search input style */
                input[name="q"] {
                    background-color: rgba(255, 255, 255, 0.95) !important;
                }
            `;
            document.head.appendChild(style);
            
            // Create Matrix canvas - bottom layer
            const canvas = document.createElement('canvas');
            canvas.id = 'matrix-canvas';
            document.body.insertBefore(canvas, document.body.firstChild);
            
            // Create overlay - middle layer
            const overlay = document.createElement('div');
            overlay.className = 'matrix-overlay';
            document.body.insertBefore(overlay, document.body.firstChild.nextSibling);
            
            const ctx = canvas.getContext('2d');
            
            // Set canvas size to window size
            function resizeCanvas() {
                canvas.width = window.innerWidth;
                canvas.height = window.innerHeight;
            }
            resizeCanvas();
            window.addEventListener('resize', resizeCanvas);
            
            // Matrix effect configuration
            const config = {
                fontSize: 14,
                chars: '日ﾊﾐﾋｰｳｼﾅﾓﾆｻﾜﾂｵﾘｱﾎﾃﾏｹﾒｴｶｷﾑﾕﾗｾﾈｽﾀﾇﾍｦｲｸｺｿﾁﾄﾉﾌﾔﾖﾙﾚﾛﾝ',
                color: '#0F0',
                speed: 1.2,
                density: 0.8
            };
            
            // Create rain drops
            const columns = Math.floor(canvas.width / config.fontSize);
            const drops = Array(Math.floor(columns * config.density)).fill(0).map(() => ({
                x: Math.random() * canvas.width,
                y: Math.random() * -canvas.height,
                speed: Math.random() * 0.5 + config.speed
            }));
            
            // Drawing function
            function draw() {
                // Create fade out effect
                ctx.fillStyle = 'rgba(0, 0, 0, 0.05)';
                ctx.fillRect(0, 0, canvas.width, canvas.height);
                
                // Set text style
                ctx.fillStyle = config.color;
                ctx.font = config.fontSize + 'px monospace';
                
                // Update and draw each rain drop
                drops.forEach(drop => {
                    // Randomly select character
                    const char = config.chars[Math.floor(Math.random() * config.chars.length)];
                    
                    // Draw character
                    ctx.fillText(char, drop.x, drop.y);
                    
                    // Update position
                    drop.y += drop.speed * config.fontSize;
                    
                    // If it goes off the bottom of the screen, reset to the top
                    if (drop.y > canvas.height) {
                        drop.y = -config.fontSize;
                        drop.x = Math.random() * canvas.width;
                        drop.speed = Math.random() * 0.5 + config.speed;
                    }
                });
                
                requestAnimationFrame(draw);
            }
            
            // Start animation
            requestAnimationFrame(draw);
        })();
    ]])
    
    -- Listen for page load completion
    testView:addEventListener("urlRequest", function(event)
        if event.type == "loaded" then
            -- Wait for DOM to fully load
            timer.performWithDelay(1000, function()
                -- Perform search operation
                testView:evaluateJS([[
                    (function(){
                        // Check if we're on the main Google search page
                        const isMainPage = window.location.pathname === '/' || 
                                         window.location.pathname === '/search' && !window.location.search;
                        
                        if(isMainPage) {
                            // Only perform search on the main page
                            const searchInput = document.querySelector('input[name="q"]');
                            if(searchInput) {
                                searchInput.value = 'labo lado';
                                const form = searchInput.closest('form');
                                if(form) form.submit();
                            }
                        }
                        // Do nothing if we're already on the search results page
                    })();
                ]])
            end)
        end
    end)
    
    -- Load Google
    testView:request("https://www.google.com")
    
    return { success = true }
end) 