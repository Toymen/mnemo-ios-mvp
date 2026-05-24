#if os(iOS)
import SwiftUI
import WebKit

struct MermaidView: UIViewRepresentable {
    let markdown: String
    @Binding var contentHeight: CGFloat
    var onDiagramValidated: ((Bool) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator($contentHeight)
    }

    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = preferences
        // Register both handlers up-front so JS can always reach them
        config.userContentController.add(context.coordinator, name: "heightChanged")
        config.userContentController.add(context.coordinator, name: "diagramValidated")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.isOpaque = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.onDiagramValidated = onDiagramValidated
        webView.loadHTMLString(buildHTML(markdown), baseURL: nil)
    }

    private func buildHTML(_ markdown: String) -> String {
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

                function reportValidation(ok){
                    const h=document.documentElement.scrollHeight;
                    window.webkit.messageHandlers.heightChanged.postMessage(h);
                    window.webkit.messageHandlers.diagramValidated.postMessage(ok);
                }

                mermaid.run().then(()=>{
                    // A successful render produces <svg> elements with non-zero dimensions
                    const svgs=document.querySelectorAll('.mermaid svg');
                    const valid=svgs.length>0&&Array.from(svgs).some(svg=>{
                        const w=parseFloat(svg.getAttribute('width')||'0');
                        const bw=svg.getBoundingClientRect().width;
                        return w>10||bw>10;
                    });
                    reportValidation(valid);
                }).catch(()=>reportValidation(false));
            </script>
        </body>
        </html>
        """
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        @Binding var contentHeight: CGFloat
        var onDiagramValidated: ((Bool) -> Void)?

        init(_ binding: Binding<CGFloat>) {
            self._contentHeight = binding
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Fallback: read height once DOM is ready (before Mermaid finishes)
            webView.evaluateJavaScript("document.documentElement.scrollHeight") { result, _ in
                guard let h = result as? CGFloat, h > 0 else { return }
                DispatchQueue.main.async { self.contentHeight = h }
            }
        }

        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            switch message.name {
            case "heightChanged":
                let h: CGFloat
                if let d = message.body as? Double { h = CGFloat(d) }
                else if let i = message.body as? Int { h = CGFloat(i) }
                else { return }
                if h > 0 { DispatchQueue.main.async { self.contentHeight = h } }

            case "diagramValidated":
                let isValid = (message.body as? Bool) ?? false
                DispatchQueue.main.async { self.onDiagramValidated?(isValid) }

            default:
                break
            }
        }
    }
}
#endif
