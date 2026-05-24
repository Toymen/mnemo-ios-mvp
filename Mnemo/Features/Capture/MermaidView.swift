#if os(iOS)
import SwiftUI
import WebKit

struct MermaidView: UIViewRepresentable {
    let markdown: String
    @Binding var contentHeight: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator($contentHeight)
    }

    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = preferences
        config.userContentController.add(context.coordinator, name: "heightChanged")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.isOpaque = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(buildHTML(markdown), baseURL: nil)
    }

    private func buildHTML(_ markdown: String) -> String {
        // JSON-encode to safely inject arbitrary markdown into JS
        let escaped = (try? String(data: JSONEncoder().encode(markdown), encoding: .utf8)) ?? "\"\""
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">
            <style>
                *{box-sizing:border-box}
                body{font-family:-apple-system,BlinkMacSystemFont,'Helvetica Neue',sans-serif;
                     font-size:15px;line-height:1.6;padding:12px 16px;margin:0;
                     color:#1c1c1e;background:transparent}
                @media(prefers-color-scheme:dark){body{color:#f2f2f7}}
                blockquote{border-left:3px solid #007aff;margin:8px 0;padding:4px 12px;
                           color:#636366;font-style:italic}
                @media(prefers-color-scheme:dark){blockquote{color:#98989d}}
                pre{background:#f2f2f7;border-radius:8px;padding:12px;overflow-x:auto;font-size:13px}
                @media(prefers-color-scheme:dark){pre{background:#2c2c2e}}
                code{font-family:'SF Mono',Menlo,monospace;font-size:13px}
                h1{font-size:18px;margin-top:0}
                h2{font-size:15px}
                .mermaid{text-align:center;margin:12px 0;overflow-x:auto}
                svg{max-width:100%;height:auto}
                p{margin:6px 0}
            </style>
        </head>
        <body>
            <div id="content"></div>
            <script src="https://cdn.jsdelivr.net/npm/marked@9/marked.min.js"></script>
            <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
            <script>
                const dark=window.matchMedia('(prefers-color-scheme:dark)').matches;
                mermaid.initialize({startOnLoad:false,theme:dark?'dark':'default',securityLevel:'loose'});
                const renderer=new marked.Renderer();
                renderer.code=function(code,lang){
                    if(lang==='mermaid')return'<div class="mermaid">'+code+'</div>';
                    return'<pre><code>'+code+'</code></pre>';
                };
                marked.use({renderer});
                document.getElementById('content').innerHTML=marked.parse(\(escaped));
                mermaid.run().finally(()=>{
                    const h=document.documentElement.scrollHeight;
                    window.webkit.messageHandlers.heightChanged.postMessage(h);
                });
            </script>
        </body>
        </html>
        """
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        @Binding var contentHeight: CGFloat

        init(_ binding: Binding<CGFloat>) {
            self._contentHeight = binding
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.documentElement.scrollHeight") { result, _ in
                guard let h = result as? CGFloat, h > 0 else { return }
                DispatchQueue.main.async { self.contentHeight = h }
            }
        }

        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "heightChanged" else { return }
            let h: CGFloat
            if let d = message.body as? Double { h = CGFloat(d) }
            else if let i = message.body as? Int { h = CGFloat(i) }
            else { return }
            guard h > 0 else { return }
            DispatchQueue.main.async { self.contentHeight = h }
        }
    }
}
#endif
