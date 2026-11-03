(function(){
var W=window.__wf, out=[], el=document.createElement('pre'); el.style.cssText='position:fixed;left:6px;top:60px;z-index:999;background:#fff;color:#000;font:11px/1.35 monospace;padding:8px;width:420px;max-height:90vh;overflow:auto;margin:0';document.body.appendChild(el);
function ok(n,c,x){out.push((c?'PASS ':'FAIL ')+n+(x?' ['+x+']':''));el.textContent=out.join('\n');}
async function closeAll(){for(var i=0;i<8;i++){if(document.querySelector('#ov.on')){var b=document.querySelector('#ov [data-a=ovclose],#ov [data-a=repotDone]');if(b)b.dispatchEvent(new MouseEvent('click',{bubbles:true}));else document.querySelector('#ov .dim').dispatchEvent(new MouseEvent('click',{bubbles:true}));await sleep(250)}}}
function sleep(ms){return new Promise(function(r){setTimeout(r,ms)})}
function click(sel){var e=document.querySelector(sel);if(!e){ok('click '+sel,false,'missing');return false}e.dispatchEvent(new MouseEvent('click',{bubbles:true}));return true}
async function typeWord(w){for(var i=0;i<w.length;i++){click('[data-a=key][data-k='+w[i]+']')}}
async function run(){
 var S=W.S(); S.rm=true; document.body.classList.add('rm');
 W.go('home'); ok('home renders',!!document.querySelector('[data-a=play]'));
 // round 1: SUNFLOWER hero
 click('[data-a=play]'); var G=W.G(); ok('round1 word is SUNFLOWER',G.w==='SUNFLOWER',G.w);
 click('[data-a=key][data-k=Z]'); ok('wrong letter counts',W.G().wrong===1);
 await typeWord('SUNFLOWER'); await sleep(1500);
 ok('win -> plant earned screen',W.S().screen==='earned',W.S().screen);
 ok('Sunflower in garden',!!W.S().plants.plant_sunflower);
 ok('wins counter',W.S().C.wins===1);
 // next round, die and revive
 click('[data-a=after][data-d=game]'); await sleep(200); G=W.G(); ok('next round started',W.S().screen==='game');
 var wrongs='QXZJVKWYBGHPMD'.split('').filter(function(l){return G.w.indexOf(l)<0}).slice(0,8);
 wrongs.forEach(function(l){click('[data-a=key][data-k='+l+']')}); await sleep(1200);
 ok('8 wrong -> dead screen',W.S().screen==='dead',W.S().screen);
 var rose=W.S().res.rose; click('[data-a=revive]'); ok('revive uses rose and restores 3 petals',W.S().res.rose===rose-1&&W.G().wrong===5,'wrong='+W.G().wrong);
 await typeWord(W.G().w); await sleep(1500); ok('win after revive',W.S().screen==='earned');
 ok('revive badge counter',W.S().C.revive===1);
 click('[data-a=after][data-d=game]'); await sleep(600); await closeAll(); await sleep(300);
 // third round completion -> ad (modal may block)
 var cnt=0; while(W.S().screen==='game'&&cnt<2){await closeAll(); await typeWord(W.G().w);await sleep(1500); if(W.S().screen==='earned'){click('[data-a=after][data-d=game]');await sleep(600);await closeAll();await sleep(300);} cnt++;}
 // dismiss any modal
 for(var k=0;k<4;k++){ if(document.querySelector('#ov.on')){click('[data-a=ovclose]');await sleep(300)} }
 ok('rounds completed >=3',W.S().rounds>=3,'rounds='+W.S().rounds);
 ok('ad moment after 3rd round (screen ad or game after close)',W.S().screen==='ad'||W.S().sinceAd===0,W.S().screen+' sinceAd='+W.S().sinceAd);
 if(W.S().screen==='ad'){ ok('ad has Close and Go ad-free',!!document.querySelector('[data-a=adclose]')&&!!document.querySelector('[data-a=adfree]')); click('[data-a=adfree]'); await sleep(200); ok('Go ad-free opens paywall',W.S().screen==='paywall'); click('[data-a=subscribe]'); await sleep(200); ok('subscribe sets Plus (no purchase)',W.S().plus===true&&W.S().screen==='settings'); }
 W.go('home'); await sleep(100);
 // garden + plant tend
 click('[data-a=garden]'); ok('garden grid',document.querySelectorAll('.pc').length===10);
 click('[data-a=plant]'); ok('plant detail',W.S().screen==='plant'); var id=W.S().p.id, gp0=W.S().plants[id].gp, w0=W.S().res.water;
 click('[data-a=useTool]'); await sleep(1000); ok('water: counters update',W.S().res.water===w0-1&&W.S().plants[id].gp===gp0+4,'water '+w0+'->'+W.S().res.water+' gp '+gp0+'->'+W.S().plants[id].gp);
 click('[data-a=hand][data-t=trowel]'); click('[data-a=useTool]'); await sleep(1000); ok('feed with trowel +12 gp',W.S().plants[id].gp>=gp0+16,'gp='+W.S().plants[id].gp);
 // repot
 click('[data-a=repot]'); ok('repot screen with 4 soils',document.querySelectorAll('.soil').length===4); click('[data-a=soil][data-s=sandy]'); await sleep(100); ok('repot modal',!!document.querySelector('#ov.on')); click('[data-a=repotDone]'); await sleep(200);
 // unlock + prune/mist/sun
 W.act('settings',{}); W.act('helper',{h:'tools'}); W.act('helper',{h:'res'}); W.act('plants',{});
 W.go('plant',{id:id});
 click('[data-a=hand][data-t=mister]'); click('[data-a=useTool]'); await sleep(900); ok('mist counter',W.S().C.mist===1);
 click('[data-a=hand][data-t=lamp]'); click('[data-a=useTool]'); await sleep(900); ok('sun counter',W.S().C.sun===1);
 click('[data-a=prune]'); await sleep(200); ok('prune minigame opens',!!document.querySelector('.tip')); for(var t=0;t<3;t++) click('.tip'); await sleep(900); ok('prune counted',W.S().C.prune===1);
 for(var k2=0;k2<4;k2++){ if(document.querySelector('#ov.on')){click('[data-a=ovclose]');await sleep(300)} }
 // stage change
 var st=W.S().plants[id].stage; for(var q=0;q<12;q++){ W.go('plant',{id:id}); W.act('hand',{t:'trowel'}); click('[data-a=useTool]'); await sleep(450);} ok('growth stage changed',W.S().plants[id].stage>st,'stage '+st+'->'+W.S().plants[id].stage);
 for(var k3=0;k3<6;k3++){ if(document.querySelector('#ov.on')){click('[data-a=ovclose]');await sleep(300)} }
 // butterfly
 W.go('bfIntro'); click('[data-a=bfStart]'); await sleep(300); ok('net game running',W.S().screen==='bf'&&W.BF().list.length>0,'visitors='+W.BF().list.length);
 var v=W.BF().list[0]; W.BF().catchV(v); await sleep(100); ok('catch records sticker',Object.keys(W.S().stickers).length>=1);
 W.bfFinish(); await sleep(200); ok('summary screen, always rewards',W.S().screen==='bfSum'&&W.S().lastBF.rw.water>=1,'rw='+JSON.stringify(W.S().lastBF.rw));
 for(var k4=0;k4<6;k4++){ if(document.querySelector('#ov.on')){click('[data-a=ovclose]');await sleep(300)} }
 W.go('album'); ok('album renders 12 cells',document.querySelectorAll('.album .c').length===12);
 W.go('badges'); ok('badge shelf earned some',Object.keys(W.S().badges).length>=1,Object.keys(W.S().badges).join(','));
 W.go('map'); ok('level map 5 levels',document.querySelectorAll('[data-a=viewmap]').length===5);
 W.go('shed'); ok('shed renders tools',document.querySelectorAll('.tcard').length===6);
 W.go('settings'); ok('settings renders',!!document.querySelector('[data-a=rm]'));
 // extra: motion path, evening, plus toggle
 S.rm=false; document.body.classList.remove('rm'); W.go('plant',{id:id}); W.act('hand',{t:'can'}); var g0=W.S().plants[id].gp; click('[data-a=useTool]'); await sleep(300); ok('tool animation class applied (non-RM)',!!document.querySelector('#stage.pour'));
 await sleep(2600); ok('animated use still updates counters',W.S().plants[id].gp>g0);
 W.go('home'); click('#tFree'); await sleep(100); ok('Free shows Remove ads',!!document.querySelector('[data-a=paywall]'));
 click('#tPlus'); await sleep(100); ok('Plus hides ad banner',!document.querySelector('.ad'));
 S.evening=true; W.go('bfIntro'); click('[data-a=bfStart]'); await sleep(300); var ids=W.BF().list.map(function(v){return v.id}); ok('evening pool only night species',ids.every(function(i){return i==='firefly'||i==='luna'}),ids.join(','));
 W.bfFinish(); await sleep(100); S.evening=false; W.go('bfIntro'); click('[data-a=bfStart]'); await sleep(300); ids=W.BF().list.map(function(v){return v.id}); ok('day pool has no night species',ids.every(function(i){return i!=='firefly'&&i!=='luna'}),ids.join(',')); W.bfFinish();
 click('#tTheme'); await sleep(50); ok('theme toggle sets data-theme',!!document.documentElement.getAttribute('data-theme'));
 el.textContent=out.join('\n')+'\nDONE';
}
run().catch(function(e){out.push('ERROR '+e+' '+(e.stack||'').split('\n')[1]);el.textContent=out.join('\n')});
})();
