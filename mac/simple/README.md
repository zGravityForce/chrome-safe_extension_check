# 项目名称: Chrome Safe Extension Scanner


## 使用方法

1. 直接 run `sudo bash RunScanChromeExtensions.sh`，脚本将自动运行并生成包含各个 Chrome 插件权限信息及风险等级的 CSV 文件。

## 权限查询及其含义
- `<all_urls>`: 允许插件访问所有网站的权限。可能导致插件获取所有网页的数据，包括敏感信息，如登录凭证和个人数据。
- `tabs`: 允许插件访问浏览器的标签页信息，读取标签页的内容。可能导致用户的浏览历史和活动被监视。
- `storage`: 允许插件在浏览器存储数据。虽然这对许多插件来说是必需的，但可能会存储和读取敏感数据。
- `webRequest`: 允许插件拦截和修改网络请求。可能被用来进行中间人攻击，篡改数据或窃取信息。
- `webRequestBlocking`: 允许插件拦截和修改网络请求，并阻塞请求直到插件完成处理。潜在风险与 `webRequest` 相同。
- `cookies`: 允许插件读取和修改浏览器的 cookie 数据。Cookie 中可能包含用户的会话信息和其他敏感数据。
- `background`: 允许插件在后台运行，监控用户的活动，甚至在用户关闭浏览器时继续运行。
- `activeTab`: 允许插件访问当前激活的标签页的信息。可能导致插件读取用户当前正在访问的网页的数据信息。
- `clipboardRead`: 允许插件读取剪贴板数据。可能导致用户复制的敏感数据被窃取。
- `clipboardWrite`: 允许插件写入剪贴板数据。可能导致用户复制的敏感数据被篡改。
- `management`: 允许插件管理其他已安装的扩展。可能被用来禁用安全扩展，启用恶意扩展。
- `nativeMessaging`: 允许插件与本地应用程序通信。可能导致本地系统被攻击，特别是如果本地应用程序存在安全漏洞。

PS: 请阅读 [Chrome Permissions List](https://developer.chrome.com/docs/extensions/reference/permissions-list?hl=zh-cn) 了解更多权限信息。
