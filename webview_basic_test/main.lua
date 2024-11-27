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