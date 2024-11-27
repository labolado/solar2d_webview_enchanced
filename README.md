# solar2d_webview_enchanced
An enhanced WebView for Solar2D

这个项目主要包括两部分
## Solar2d WebView 扩展API
1 我们扩展了WebView的API，增加了一些新的方法，并且增加了一些新的事件，使得WebView的功能更加强大。具体可以参考docs/webview_api.md.我们增加的API包括：
- registerCallback: 注册一个可以从JavaScript调用的Lua函数
- on: 监听从JavaScript发送的事件
- send: 向JavaScript发送事件
- injectJS: 向WebView注入JavaScript代码

主要特性:
- 双向通信: Lua和JavaScript之间可以方便地相互调用和传递数据
- 类型转换: 自动处理Lua和JavaScript之间的数据类型转换
- 事件机制: 提供了基于事件的通信方式
- 代码注入: 支持动态注入JavaScript代码到WebView

NativeBridge API:
- callNative: 调用已注册的Lua回调函数
- sendToLua: 向Lua发送事件
- on: 监听来自Lua的事件
2 提供了示例，展示了如何使用新的WebView API，具体可以参考 webview_basic_test 和 webview_advanced_test 两个例子。

##为了更方便的使用WebView，我们提供了一个新的模块webview_enchanced，具体可以参考docs/webview_enchanced_api.md.
这个模块主要提供了以下功能：
- 更简单的API，使得使用WebView更加方便
- 重写了XmlHttpRequest，这样可以方便的在Solar2d中使用XmlHttpRequest
  