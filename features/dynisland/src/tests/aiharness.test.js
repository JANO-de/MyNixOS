const fs=require('fs'),vm=require('vm'),assert=require('assert');
let src=fs.readFileSync(require('path').join(__dirname,'../services/aiharness.js'),'utf8').replace(/^\.pragma library.*$/m,'');
const ctx={console};vm.createContext(ctx);vm.runInContext(src,ctx);
const H=ctx;
let n=0;const ok=(c,m)=>{n++;assert.ok(c,m)};
// thinkMode
ok(H.thinkMode('claude-sonnet-4-6')==='adaptive');
ok(H.thinkMode('claude-opus-4-5')==='budget');
ok(H.thinkMode('claude-haiku-4-5')==='budget');
ok(H.thinkMode('claude-sonnet-4-20250514')==='budget','date suffix');
ok(H.thinkMode('claude-3-7-sonnet-latest')==='budget');
ok(H.thinkMode('claude-3-5-haiku')==='off');
ok(H.thinkMode('claude-opus-5-5')==='adaptive');
ok(H.thinkMode('qwen3:8b')==='off');
ok(H.thinkMode('x',{thinking:'off'})==='off');
// custom tool
const def={name:'weather',url:'https://api.x.com/v1/{city}/now',query:{units:'{units}',key:'k'},params:{city:{type:'string',required:true},units:{type:'string',enum:['m','i']}}};
let c=H.buildHttpCall(def,{city:'São Paulo',units:'m'});
ok(c.url==='https://api.x.com/v1/S%C3%A3o%20Paulo/now?units=m&key=k',c.url);
c=H.buildHttpCall(def,{city:'a'});ok(c.url==='https://api.x.com/v1/a/now?key=k',c.url);
c=H.buildHttpCall({url:'https://h/{id}',method:'POST'},{id:5,name:'z'});ok(c.url==='https://h/5'&&c.body==='{"name":"z"}'&&c.headers['Content-Type']);
c=H.buildHttpCall({url:'https://h',method:'POST',body:{a:'{n}',b:'x{n}'}},{n:3});ok(c.body==='{"a":3,"b":"x3"}',c.body);
const tl=H.allTools([def,{name:'p',url:'u',method:'POST'}],['todo_write']);
ok(tl.find(t=>t.name==='weather').perm==='safe'&&tl.find(t=>t.name==='p').perm==='exec'&&!tl.find(t=>t.name==='todo_write'));
ok(H.needsApproval({perm:'exec',name:'bash'},'ask',[])===true);
ok(H.needsApproval({perm:'edit',name:'x'},'edits',[])===false);
ok(H.needsApproval({perm:'exec',name:'bash'},'ask',['bash'])===false);
// repairHistory
let msgs=[H.userMsg('hi'),{role:'assistant',blocks:[{type:'tool_use',id:'a',name:'bash',input:{}}]},H.userMsg('next')];
let r=H.repairHistory(msgs);
ok(r[2].blocks[0].type==='tool_result'&&r[2].blocks[0].tool_use_id==='a'&&r[2].blocks.length===2);
msgs=[H.userMsg('hi'),{role:'assistant',blocks:[{type:'tool_use',id:'a',name:'bash',input:{}}]}];
r=H.repairHistory(msgs);ok(r.length===3&&r[2].blocks[0].is_error);
// anthropic stream
const L=[
'event: message_start','data: {"type":"message_start","message":{"model":"m","usage":{"input_tokens":12,"cache_read_input_tokens":100,"cache_creation_input_tokens":5,"output_tokens":1}}}',
'data: {"type":"content_block_start","index":0,"content_block":{"type":"thinking","thinking":""}}',
'data: {"type":"content_block_delta","index":0,"delta":{"type":"thinking_delta","thinking":"hmm "}}',
'data: {"type":"content_block_delta","index":0,"delta":{"type":"signature_delta","signature":"SIG"}}',
'data: {"type":"content_block_stop","index":0}',
'data: {"type":"content_block_start","index":1,"content_block":{"type":"text","text":""}}',
'data: {"type":"content_block_delta","index":1,"delta":{"type":"text_delta","text":"Hello"}}',
'data: {"type":"content_block_stop","index":1}',
'data: {"type":"content_block_start","index":2,"content_block":{"type":"tool_use","id":"tu1","name":"bash","input":{}}}',
'data: {"type":"content_block_delta","index":2,"delta":{"type":"input_json_delta","partial_json":"{\\"command\\":"}}',
'data: {"type":"content_block_delta","index":2,"delta":{"type":"input_json_delta","partial_json":"\\"ls\\"}"}}',
'data: {"type":"content_block_stop","index":2}',
'data: {"type":"message_delta","delta":{"stop_reason":"tool_use"},"usage":{"output_tokens":40}}',
'data: {"type":"message_stop"}'];
let s=H.newAnthropicStream();L.forEach(l=>s.feed(l));let f=s.finish();
ok(f.blocks.length===3&&f.blocks[0].signature==='SIG'&&f.blocks[1].text==='Hello'&&f.blocks[2].input.command==='ls');
ok(f.usage.in===12&&f.usage.cr===100&&f.usage.cw===5&&f.usage.out===40&&f.stop==='tool_use'&&!f.error);
ok(H.ctxTokens(f.usage)===117);
// error body
s=H.newAnthropicStream();s.feed('{"type":"error","error":{"type":"invalid_request_error","message":"bad key"}}');f=s.finish();ok(f.error==='bad key');
// cut-off tool
s=H.newAnthropicStream();s.feed('data: {"type":"content_block_start","index":0,"content_block":{"type":"tool_use","id":"x","name":"bash","input":{}}}');f=s.finish();ok(f.blocks.length===0);
// openai stream w/ think tags + tool call
const O=[
'data: {"choices":[{"delta":{"content":"<think>plan "}}]}','data: {"choices":[{"delta":{"content":"it</think>Sure. "}}]}',
'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"id":"c1","function":{"name":"bash","arguments":"{\\"comm"}}]}}]}',
'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"function":{"arguments":"and\\":\\"pwd\\"}"}}]}}]}',
'data: {"choices":[{"delta":{},"finish_reason":"tool_calls"}]}',
'data: {"choices":[],"usage":{"prompt_tokens":50,"completion_tokens":9,"prompt_tokens_details":{"cached_tokens":20}}}','data: [DONE]'];
s=H.newOpenAIStream();O.forEach(l=>s.feed(l));f=s.finish();
ok(f.blocks[0].type==='reasoning'&&f.blocks[0].text==='plan it'&&f.blocks[1].text==='Sure. '&&f.blocks[2].input.command==='pwd',JSON.stringify(f.blocks));
ok(f.usage.in===30&&f.usage.cr===20&&f.usage.out===9&&f.stop==='tool_use');
// live think display
let lb=H.liveBlocks([{type:'text',text:'<think>abc'}],false);ok(lb[0].type==='reasoning'&&lb[0]._open&&lb.length===1);
ok(H.splitThink('abc</think>ans').think==='abc');
// xml
s=H.newOpenAIStream();['data: {"choices":[{"delta":{"content":"ok <tool_call>{\\"name\\":\\"bash\\",\\"arguments\\":{\\"command\\":\\"ls\\"}}</tool_call>"}}]}'].forEach(l=>s.feed(l));
f=s.finish({xml:true});ok(f.blocks[0].text==='ok'&&f.blocks[1].type==='tool_use'&&f.blocks[1].input.command==='ls'&&f.stop==='tool_use'&&f.estimated);
lb=H.liveBlocks([{type:'text',text:'hi <tool_call>{"na'}],true);ok(lb[0].text==='hi ');
// requests
const prov={kind:'anthropic',baseUrl:'https://api.anthropic.com',models:[{id:'claude-sonnet-4-6'}]};
const mdl=H.resolveModel(prov,'claude-sonnet-4-6');
const hist=[H.userMsg('hello'),{role:'assistant',blocks:f0=[{type:'thinking',thinking:'t',signature:'S'},{type:'reasoning',text:'zzz'},{type:'tool_use',id:'t1',name:'bash',input:{command:'ls'}}]},{role:'user',blocks:[{type:'text',text:'extra'},{type:'tool_result',tool_use_id:'t1',content:'out'}]}];
let q=H.buildRequest({provider:prov,model:mdl,system:'SYS',messages:hist,tools:H.allTools([],[]),level:'medium',mcp:[{name:'m1',url:'https://m/mcp',token:'T'}],cache:true,xml:false});
ok(q.body.thinking.type==='adaptive'&&q.body.mcp_servers[0].authorization_token==='T'&&q.beta[0]==='mcp-client-2025-11-20');
ok(q.body.tools[q.body.tools.length-1].type==='mcp_toolset'&&q.body.system[0].cache_control);
ok(q.body.messages[1].content.length===2&&q.body.messages[2].content[0].type==='tool_result'&&q.body.messages[2].content[1].cache_control);
const mdl2=H.resolveModel({kind:'anthropic',models:[]},'claude-opus-4-5');
q=H.buildRequest({provider:prov,model:mdl2,system:'S',messages:[H.userMsg('x')],tools:[],level:'high',mcp:[],cache:true,xml:false});
ok(q.body.thinking.budget_tokens===20000&&q.body.max_tokens>=24096&&!q.body.tools);
// openai request
const op={kind:'openai',baseUrl:'http://localhost:11434/v1',models:['qwen3:8b'],local:true};
const om=H.resolveModel(op,'qwen3:8b');ok(om.reasoning==='native'&&om.local&&om.pricing===null);
q=H.buildRequest({provider:op,model:om,system:'SYS',messages:hist,tools:H.allTools([],[]),level:'off',mcp:[],cache:true,xml:false});
const mm=q.body.messages;ok(mm[0].role==='system'&&mm[2].tool_calls[0].function.arguments==='{"command":"ls"}'&&mm[3].role==='tool'&&mm[4].role==='user');
// xml request
q=H.buildRequest({provider:op,model:om,system:'SYS',messages:hist,tools:H.allTools([],[]),level:'off',mcp:[],cache:true,xml:true});
ok(!q.body.tools&&q.body.messages[2].content.indexOf('<tool_call>')>=0&&q.body.messages[3].content.indexOf('<tool_result')>=0,JSON.stringify(q.body.messages));
// rate / cost
const rl=H.parseRate('HTTP/2 200\r\nanthropic-ratelimit-requests-limit: 50\r\nanthropic-ratelimit-requests-remaining: 49\r\nanthropic-ratelimit-tokens-limit: 40000\r\nanthropic-ratelimit-tokens-remaining: 39000\r\nanthropic-ratelimit-tokens-reset: 2026-01-01T00:00:00Z\r\n');
ok(rl.length===2&&rl[1].remaining===39000&&rl[1].limit===40000&&rl[0].label==='requests');
const rl2=H.parseRate('x-ratelimit-limit-requests: 60\nx-ratelimit-remaining-requests: 59\nx-ratelimit-reset-tokens: 1s');ok(rl2.length===2);
ok(H.statusOfHeaders('HTTP/2 429 \r\nx: y')===429&&H.retryAfter('Retry-After: 12\r\n')===12);
ok(Math.abs(H.costOf({in:1e6,out:1e6,cr:0,cw:0},{in:3,out:15})-18)<1e-9);
ok(H.costOf({in:1,out:1,cr:0,cw:0},null)===null);
// prompt
const sp=H.buildSystem({env:{cwd:'/x',date:'d'},user:'U',memory:'M',provider:'p',model:'m',xmlTools:H.allTools([],[]),thinkTags:true});
ok(sp.indexOf('<think>')>0&&sp.indexOf('Tool calling protocol')>0&&sp.indexOf('Working directory: /x')>0);
console.log('all',n,'checks passed');
// ---- part 2: scripts + helpers
const cp=require('child_process');
const run=(script,args,env)=>{const r=cp.spawnSync('bash',['-c',H.RUNNER,'bash',script].concat(args),{env:Object.assign({},process.env,env||{}),encoding:'utf8'});return H.splitExit(r.stdout)};
fs.writeFileSync('/tmp/h1.txt','a\nb\nc\nd\n');fs.writeFileSync('/tmp/h2.html','<html><head><style>x{}</style><script>var a=1;</script></head><body><h1>Hi &amp; bye</h1><p>text</p></body></html>');
let o=run(H.SH_BASH,['/tmp','5','echo hi; echo err >&2; exit 3']);ok(o.out.indexOf('hi')===0&&o.out.indexOf('err')>0&&o.code===3,JSON.stringify(o));
o=run(H.SH_BASH,['/tmp','1','sleep 3']);ok(o.code===124,JSON.stringify(o));
o=run(H.SH_READ,['/tmp/h1.txt','2','3']);ok(o.code===0&&/^\s+2\tb\n\s+3\tc\n\.\.\. \(1 more/.test(o.out),JSON.stringify(o));
o=run(H.SH_READ,['/tmp/nope','1','9']);ok(o.code===1&&/No such file/.test(o.out));
o=run(H.SH_LIST,['/tmp']);ok(o.code===0&&o.out.indexOf('h1.txt')>0);
o=run(H.SH_LIST,['/nodir']);ok(o.code===1);
o=run(H.SH_MKPARENT,['/tmp/zz/y/f.txt']);ok(o.code===0&&fs.existsSync('/tmp/zz/y'));
o=run(H.SH_FETCH,['file:///tmp/h2.html','20000']);ok(o.code===0&&/Hi & bye/.test(o.out)&&!/var a/.test(o.out)&&!/<h1>/.test(o.out),JSON.stringify(o));
o=run(H.SH_FETCH,['file:///tmp/h1.txt','3']);ok(o.out==='a\nb','head -c: '+JSON.stringify(o.out));
o=run(H.SH_HTTP,['GET','file:///tmp/h1.txt','Authorization: Bearer %s','X-A: 1'],{AI_KEYCMD:'echo k1'});ok(o.code===0&&/a\nb\nc\nd/.test(o.out),JSON.stringify(o));
// http script with a header & key against local netcat-less check: use curl -v impossible; just ensure no crash with body
o=run(H.SH_HTTP,['POST','file:///tmp/h1.txt','','Y: 2'],{AI_BODY:'{"a":1}'});ok(o.code===0||o.code===3||o.code===25,JSON.stringify(o));
// chat script against file url
fs.writeFileSync('/tmp/body.json','{}');
let rr=cp.spawnSync('bash',['-c',H.SH_CHAT,'bash','file:///tmp/h1.txt','/tmp/body.json','/tmp/hdr.txt','x-api-key: %s'],{env:Object.assign({},process.env,{AI_KEY:'abc'}),encoding:'utf8'});
ok(/^a\nb/.test(rr.stdout),JSON.stringify(rr.stdout));
// helpers
ok(H.resolvePath('~/x','/w','/h')==='/h/x'&&H.resolvePath('y/z','/w/','/h')==='/w/y/z'&&H.resolvePath('/a','/w','/h')==='/a'&&H.resolvePath('','/w','/h')==='/w');
let e=H.applyEdit('foo bar foo','foo','X',false);ok(!e.ok&&/2 times/.test(e.error));
e=H.applyEdit('foo bar foo','foo','X',true);ok(e.ok&&e.text==='X bar X'&&e.count===2);
e=H.applyEdit('a $& b','$&','$$',false);ok(e.ok&&e.text==='a $$ b',e.text);
e=H.applyEdit('abc','zzz','x',false);ok(!e.ok);
// rows
const rows=H.displayRows([H.userMsg('q'),{role:'assistant',blocks:[{type:'thinking',thinking:'T',signature:'s'},{type:'text',text:'A'},{type:'tool_use',id:'1',name:'bash',input:{command:'ls'}}],usage:{in:1,out:2,cr:0,cw:0}},{role:'user',blocks:[{type:'tool_result',tool_use_id:'1',content:'files\n[exit 0]'}]},{role:'assistant',blocks:[{type:'text',text:'done'}]}]);
ok(rows.length===3&&rows[1].blocks[2].done&&rows[1].blocks[2].result.indexOf('files')===0&&rows[1].blocks[0].type==='reasoning');
const ld=H.liveDisplay([{type:'text',text:'<think>x'},{type:'tool_use',id:'q',name:'bash',input:{}}],false);ok(ld[0].open&&ld[1].type==='tool');
console.log('part2 ok, total',n);
o=run(H.SH_HTTP,['POST','file:///tmp/h1.txt','','Y: 2'],{AI_HASBODY:'1',AI_BODY:'{"a":1}'});ok(/\[HTTP/.test(o.out),JSON.stringify(o));
let sh=H.splitHttp('{"a":1}\n[HTTP 200]');ok(sh.status===200&&sh.body==='{"a":1}');
ok(H.parseModelList('{"data":[{"id":"a"},{"id":"b"}]}').join()==='a,b'&&H.parseModelList('{"models":[{"name":"q:1"}]}')[0]==='q:1'&&H.parseModelList('x').length===0);
q=H.buildRequest({provider:{kind:'openai',streamUsage:false},model:om,system:'S',messages:[H.userMsg('x')],tools:[],level:'off',mcp:[],cache:true,xml:false});ok(!q.body.stream_options);
console.log('part3 ok',n);
