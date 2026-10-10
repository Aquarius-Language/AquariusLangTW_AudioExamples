import {createServer as 建立伺服器} from 'node:http';
import {readFile as 讀取檔案} from 'node:fs/promises';
import 路徑 from 'node:path';
import {fileURLToPath as 網址轉路徑} from 'node:url';
const 根目錄=路徑.join(路徑.dirname(網址轉路徑(import.meta.url)),'web');
const 伺服器=建立伺服器(async(請求,回應)=>{
  try{
    const 網址路徑=decodeURIComponent(new URL(請求.url,'http://localhost').pathname);
    const 檔案=路徑.resolve(根目錄,'.'+網址路徑+(網址路徑.endsWith('/')?'index.html':''));
    if(!檔案.startsWith(根目錄+路徑.sep))throw new Error('無法讀取此路徑');
    回應.setHeader('Content-Type',({'.html':'text/html; charset=utf-8','.mjs':'text/javascript','.json':'application/json','.wasm':'application/wasm'})[路徑.extname(檔案)]??'application/octet-stream');
    回應.end(await 讀取檔案(檔案));
  }catch{回應.statusCode=404;回應.end('找不到檔案');}
});
伺服器.listen(0,'127.0.0.1',()=>console.log(`星泉聲音工坊：http://127.0.0.1:${伺服器.address().port}/`));
