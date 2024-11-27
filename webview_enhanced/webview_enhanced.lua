local json = require("json")
local M = {}

local WebViewExtension = {
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

        if self._isLoaded then
            self:injectJS(wrappedScript)
        else
            self._scriptQueue = self._scriptQueue or {}
            table.insert(self._scriptQueue, wrappedScript)
        end
    end,

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

        self._globalScripts = self._globalScripts or {}
        table.insert(self._globalScripts, wrappedScript)
        
        if self._isLoaded then
            self:injectJS(wrappedScript)
        end
    end,

    setXHRHandler = function(self, handler)
        self._xhrHandler = handler
        
        -- 只有启用了 XHR 重写时才注入代码
        if not self._xhrEnabled then
            print("Warning: XHR rewriting is not enabled. Please create WebView with rewriteXHR=true")
            return
        end
        
        -- 注入 XHR 重写代码
        self:addGlobalScript([[
            (function() {
                // 保存原始 XMLHttpRequest
                const OriginalXHR = window.XMLHttpRequest;
                
                // 创建新的 XMLHttpRequest
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
                    
                    // 准备请求数据
                    const request = {
                        id: this._requestId,
                        method: this._method,
                        url: this._url,
                        headers: this._headers,
                        body: body,
                        async: this._async
                    };
                    
                    // 发送到 Lua
                    NativeBridge.callNative('_handleXHR', request).then(response => {
                        // 更新状态
                        xhr.readyState = 4;
                        xhr.status = response.status;
                        xhr.statusText = response.statusText;
                        xhr.responseText = response.body;
                        xhr.response = response.body;
                        
                        // 触发事件
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
                
                // 替换全局 XMLHttpRequest
                window.XMLHttpRequest = CustomXHR;
            })();
        ]])
    end,

    -- 内部方法：处理 XHR 请求
    _handleXHR = function(self, request)
        if not self._xhrHandler then
            return {
                status = 500,
                statusText = "No XHR handler set",
                body = "XMLHttpRequest handler not configured"
            }
        end
        
        -- 调用用户设置的处理器
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

function M.createWebView(options)
    options = options or {}
    -- 默认不启用 XHR 重写
    options.rewriteXHR = options.rewriteXHR or false
    
    local webView = native.newWebView(
        options.x or display.contentCenterX,
        options.y or display.contentCenterY,
        options.width or display.actualContentWidth,
        options.height or display.actualContentHeight
    )
    
    -- 添加扩展方法
    for k, v in pairs(WebViewExtension) do
        webView[k] = v
    end
    
    -- 初始化状态
    webView._scriptQueue = {}
    webView._globalScripts = {}
    webView._isLoaded = false
    webView._xhrEnabled = options.rewriteXHR
    
    -- 注册 XHR 处理回调
    if options.rewriteXHR then
        webView:registerCallback("_handleXHR", function(request)
            return webView:_handleXHR(request)
        end)
    end
    
    -- 处理页面加载事件
    webView:addEventListener("urlRequest", function(event)
        if event.url then
            webView._isLoaded = false
        end
        
        if event.type == "loaded" then
            -- 执行全局脚本
            for _, script in ipairs(webView._globalScripts) do
                webView:injectJS(script)
            end
            
            -- 执行队列中的脚本
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