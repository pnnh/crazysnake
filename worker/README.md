
因为Godot Web导出后生成的index.side.wasm文件过大达到了30M，远超Cloudflare Worker大小限制，也不利于网页访问。所以需要先在dist目录下执行以下命令手动进行以下压缩：

brotli -Z index.side.wasm -o index.side.wasm.br

之后记得执行rm index.side.wasm删除原始文件避免上传的文件过大导致部署失败。

然后通过Cloudflare Worker 文件来进行路由拦截，返回经过手动压缩过的版本，并正确设置响应头文件。详情参考_worker.js文件中的注释说明。

将该目录下的文件拷贝到 dist 导出目录下，并执行 npx wrangler deploy来部署到Cloudflare Workers。

