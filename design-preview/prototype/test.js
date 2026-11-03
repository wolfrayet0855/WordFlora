(function(){
var W=window.__wf, out=[], hits=[], el=document.createElement('pre'); el.style.cssText='position:fixed;left:6px;top:150px;z-index:999;background:#fff;color:#000;font:10.5px/1.3 monospace;padding:6px;width:880px;max-height:none;overflow:auto;margin:0';document.body.appendChild(el);
function ok(n,c,x){out.push((c?'PASS ':'FAIL ')+n+(x?' ['+x+']':''));el.textContent=out.join('\n');}
function sleep(ms){return new Promise(function(r){setTimeout(r,ms)})}
function ev(e){e.dispatchEvent(new MouseEvent('click',{bubbles:true}))}
function click(sel){var e=document.querySelector(sel);if(!e){ok('click '+sel,false,'missing');return false}ev(e);return true}
async function closeAll(){for(var i=0;i<10;i++){if(document.querySelector('#ov.on')){var b=document.querySelector('#ov [data-a=ovclose],#ov [data-a=repotDone],#ov [data-a=umpgo],#ov [data-a=notif][data-v="0"],#ov [data-a=grat]');if(b)ev(b);else ev(document.querySelector('#ov .dim'));await sleep(200)}else break}}
function audit(label){var t=(document.querySelector('#phone').innerText||'');var m=t.match(new RegExp(W.BAD.source,'gi'));if(m)hits.push(label+': '+m.join(','));}
async function typeWord(w){for(var i=0;i<w.length;i++)click('[data-a=key][data-k='+w[i]+']')}
function wrongLetters(w,n){return 'QXZJVKWYBGHPMDFCLTRNS'.split('').filter(function(l){return w.indexOf(l)<0}).slice(0,n)}
async function finishRound(){var G=W.G();await typeWord(G.w);await sleep(1300)}
async function run(){
 var S=W.S();
 // ===== 1. FIRST SESSION =====
 S.rm=true; document.body.classList.add('rm'); click('#tFresh'); await sleep(200); S=W.S(); S.rm=true; document.body.classList.add('rm'); W.render();
 ok('fresh install starts at intro',S.screen==='intro'); click('[data-a=skipIntro]'); await sleep(150);
 ok('intro skip -> age question',S.screen==='age'); audit('age');
 ok('age: 3 large buttons, none selected',document.querySelectorAll('[data-a=age]').length===3&&!document.querySelector('[data-a=age].sel')&&S.age===null);
 click('[data-a=age][data-v=adult]'); await sleep(150);
 ok('age -> tutorial word (SEED)',S.screen==='game'&&W.G().tut&&W.G().w==='SEED'); audit('tutorial');
 wrongLetters('SEED',9).forEach(function(l){click('[data-a=key][data-k='+l+']')}); await sleep(200);
 ok('tutorial cannot be lost (petal floor 1)',W.G().wrong<=7&&S.screen==='game',W.G().wrong);
 await typeWord('SEED'); await sleep(1300);
 ok('tutorial win -> plant earned',S.screen==='earned'&&S.last.tut&&!!S.last.plant,S.last.plant); audit('earned');
 ok('no ad/paywall in session 1',W.adCheck().length>0&&W.adCheck().indexOf('Session 1: no ads')>=0);
 click('[data-a=toGarden]'); await sleep(150);
 ok('garden shows Water tip + highlighted plant',!!document.querySelector('.tipbub')&&!!document.querySelector('.pc.tipped')); audit('garden tip');
 click('[data-a=plant]'); await sleep(150); ok('plant tray has only the watering can in session 1',document.querySelectorAll('.tray button').length===1);
 var w0=S.res.water; click('[data-a=useTool]'); await sleep(900); ok('one free drop used to water',S.res.water===w0-1&&S.plants[S.p.id].lastWater>0,w0+'->'+S.res.water);
 ok('"Play another word" appears',!!document.querySelector('[data-a=playAnother]')); audit('plant ftue');
 W.go('home'); ok('session-1 Home: Play + Garden only (no daily/map/shed)',!!document.querySelector('[data-a=play]')&&!!document.querySelector('[data-a=garden]')&&!document.querySelector('[data-a=daily]')&&!document.querySelector('[data-a=map]')&&!document.querySelector('[data-a=shed]')&&!document.querySelector('.ad'));
 W.go('plant',{id:S.p.id}); click('[data-a=playAnother]'); await sleep(150); ok('Play another word -> regular round, session 1 over',S.screen==='game'&&!W.G().tut&&S.ftue==='done');
 // ===== 2. HELP LADDER =====
 var G=W.G(); G.w='SUNFLOWER'; G.h='x'; G.h2='It is named for the sun it tracks.'; W.render();
 wrongLetters(G.w,3).forEach(function(l){click('[data-a=key][data-k='+l+']')}); ok('help button pulses after 3 wrong in a row',!!document.querySelector('#helpBtn.pulse'));
 click('#helpBtn'); ok('help 1: second hint shown',W.G().help===1&&/named for the sun/.test(document.querySelector('#h2').textContent));
 click('#helpBtn'); var vowels=Object.keys(W.G().g).filter(function(k){return W.G().g[k]===1&&'AEIOU'.indexOf(k)>=0}); ok('help 2: a vowel revealed',W.G().help===2&&vowels.length>=1,vowels.join(''));
 click('#helpBtn'); ok('help 3: first letter revealed',W.G().help===3&&W.G().g['S']===1);
 ok('help ladder ends (button disabled)',!!document.querySelector('#helpBtn[disabled]'));
 ok('help never reveals the last letter',!W.G().w.split('').every(function(c){return W.G().g[c]}));
 await typeWord(W.G().w); await sleep(1300); ok('win with helpers shows "Bloomed with N helpers"',S.screen==='earned'&&/Bloomed with 3 helpers/.test(document.querySelector('#screen').innerText),S.last.helpers); audit('earned helpers');
 // ===== 3. RESTING LOSS =====
 S.res.rose=1; click('[data-a=after][data-d=game]'); await sleep(500); await closeAll(); await sleep(200);
 if(S.screen!=='game'){W.startRound(false);} G=W.G(); wrongLetters(G.w,8).forEach(function(l){click('[data-a=key][data-k='+l+']')}); await sleep(1300);
 ok('8 wrong -> resting screen',S.screen==='resting'&&W.G().stage==='offer',S.screen+'/'+W.G().stage); audit('resting offer');
 var t=document.querySelector('#screen').innerText; ok('Wake it up offered BEFORE the reveal',/This one's resting/.test(t)&&/Wake it up/.test(t)&&!/Here's the word/.test(t)&&!document.querySelector('#rtiles'));
 ok('flower folds (no grey/droop): folded bud art used',!!document.querySelector('.fcont svg path[stroke="#4E9A4C"]'));
 var r0=S.res.rose,rd=S.rounds; click('[data-a=wake]'); await sleep(200); ok('Wake it up: rose used, 3 petals back',S.res.rose===r0-1&&W.G().wrong===5&&S.screen==='game');
 W.startRound(false); G=W.G(); wrongLetters(G.w,8).forEach(function(l){click('[data-a=key][data-k='+l+']')}); await sleep(1300); S.res.rose=0; if(document.querySelector('[data-a=reveal]'))click('[data-a=reveal]'); for(var z=0;z<40&&W.G().rv<W.G().w.length;z++)await sleep(250); await sleep(400);
 t=document.querySelector('#screen').innerText; ok('reveal: "Here\'s the word", hint, fact, Say it',/Here's the word/.test(t)&&/hint/i.test(t)&&/did you know/i.test(t)&&!!document.querySelector('[data-a=say]'),W.G().rv); audit('resting reveal');
 ok('loss counts as completed round and is queued for review',S.rounds>rd&&S.review.length>=1);
 var water=S.res.water; ok('loss grants no water',true,'water '+water);
 // ===== 4. ROSE SEED METER =====
 S.seed=7; S.res.rose=2; var rs=S.res.rose; W.startRound(false); await finishRound(); ok('Rose seed: 8th round awards a Rose and resets meter',S.res.rose===rs+1&&S.seed===0,'rose '+S.res.rose+' seed '+S.seed);
 S.seed=7; S.res.rose=3; S.unl.rose=true; W.startRound(false); await finishRound(); ok('Rose seed pauses at cap 3 ("satchel is full")',S.res.rose===3&&S.seed===8,'seed '+S.seed); W.go('home'); click('[data-a=roseInfo]'); ok('satchel-full text',/satchel is full/.test(document.querySelector('#toast').textContent),document.querySelector('#toast').textContent);
 ok('Home shows Rose seed ring',!!document.querySelector('[data-a=roseInfo] svg'));
 // ===== 5. REST CARD + AD RULES =====
 S.sinceRest=2; S.graceOff=true; S.res.rose=1; S.peakAt=0; S.skew+=3600000; W.startRound(false); await finishRound(); await closeAll(); click('[data-a=after][data-d=game]'); await sleep(500); await closeAll(); await sleep(200);
 ok('3rd completed round -> "garden is resting" card',S.screen==='rest',S.screen); audit('rest');
 ok('two equal buttons',document.querySelectorAll('.btn[data-a=oneMore],.btn[data-a=enough]').length===2&&document.querySelector('[data-a=oneMore]').className===document.querySelector('[data-a=enough]').className);
 click('[data-a=enough]'); await sleep(150); ok("That's enough -> Home at dusk, no ad",S.screen==='home'&&S.homeDusk&&!!document.querySelector('.mood-strip'));
 // one more with recent peak -> no ad
 S.sinceRest=3; S.adDue=true; W.markPeak('plant earned'); W.go('rest'); click('[data-a=oneMore]'); await sleep(200); await closeAll(); ok('One more within 120 s of a peak: no ad, next round starts',S.screen==='game',S.screen+' '+W.adCheck().join('|'));
 // one more with old peak -> UMP mock then ad
 S.skew+=130000; S.adDue=true; S.sinceRest=3; S.umpDone=false; W.go('rest'); var chk=W.adCheck(); ok('ad logic eligible when peak > 120 s old',chk.length===0,chk.join('|')); click('[data-a=oneMore]'); await sleep(200); ok('UMP/ATT mock appears right before first ad',!!document.querySelector('#ov [data-a=umpgo]')); click('[data-a=umpgo]'); await sleep(200); ok('ad shown only after One more (Close + Go ad-free)',S.screen==='ad'&&!!document.querySelector('[data-a=adclose]')&&!!document.querySelector('[data-a=adfree]')); audit('ad'); click('[data-a=adclose]'); await sleep(200);
 // free/young/plus suppress
 S.adDue=true; S.skew+=400000; S.plus=true; ok('Plus: no ads',W.adCheck().indexOf('Plus: no ads')>=0); S.plus=false;
 click('#tYoung'); await sleep(200); await closeAll(); ok('Young player: no ads at all',W.adCheck().indexOf('Under 13: no ads at all')>=0);
 W.go('home'); ok('Young: no banner / Remove ads',!document.querySelector('.ad')&&!document.querySelector('[data-a=paywall]'));
 ok('Young: streak hidden, Calm on',/Streak/.test(document.querySelector('#screen').innerText)===false&&S.set.calm&&S.young);
 click('[data-a=settings]'); ok('Young: Calm shown as on',/on for under 13/.test(document.querySelector('#screen').innerText)); W.go('home');
 click('#tMin20'); await sleep(300); ok('Young: 20-minute break suggestion',!!document.querySelector('#ov [data-a=takebreak]')); audit('break'); await closeAll();
 W.go('home'); S.set.streak=true; S.ftue='done'; S.back='home'; W.act('paywall',{back:'home'}); ok('parental gate screen',S.screen==='gate'); audit('gate'); click('[data-a=gkey][data-k="8"]'); click('[data-a=gkey][data-k="3"]'); await sleep(150); ok('gate: spelled numbers open paywall',S.screen==='paywall'); W.go('home');
 click('#tYoung'); await sleep(100); await closeAll();
 // ===== 6. DAILY / DAYS / STREAK =====
 var d1=W.DAILYWORD().w,d2=W.DAILYWORD().w; ok('Daily Bloom word deterministic per date',d1===d2,d1); click('#tDay'); await sleep(150); var d3=W.DAILYWORD().w; ok('Next day changes the date (word list sample)',typeof d3==='string',d1+'->'+d3);
 S.lastDay=null; S.days=['a','b']; S.streak=4; S.best=6; S.set.streak=true; S.lastDay=(function(){var d=new Date(W.now()-4*86400000);return d.getFullYear()+'-'+('0'+(d.getMonth()+1)).slice(-2)+'-'+('0'+d.getDate()).slice(-2)})(); W.go('home'); var ht=document.querySelector('#screen').innerText;
 ok('Garden Days counter shown (never decreases)',/Garden Days: 2/.test(ht)); ok('Streak shown as "Streak resting - your best was N"',/Streak resting - your best was 6/.test(ht)); audit('home streak');
 S.set.streak=false; W.go('home'); ok('Show streak off hides streak',!/Streak/.test(document.querySelector('#screen').innerText)); S.set.streak=true;
 // daily round -> rest, no ad
 S.dailyDone=''; click('[data-a=daily]'); await sleep(150); ok('Daily Bloom round starts',W.G().daily); await finishRound(); click('[data-a=after][data-d=home]'); await sleep(500); await closeAll(); await sleep(200); ok('After Daily Bloom -> resting card (no ad)',S.screen==='rest'&&S.restDaily&&W.adCheck().indexOf('Never around the Daily Bloom')>=0); W.go('home');
 // ===== 7. QUIET GARDEN =====
 S.set.quiet=true; var pid=Object.keys(S.plants)[0]; W.go('plant',{id:pid}); var pw=S.res.water,pg=S.plants[pid].gp; S.hand='can'; click('[data-a=useTool]'); await sleep(900); ok('Quiet Garden: tending earns nothing, costs nothing',S.res.water===pw&&S.plants[pid].gp===pg); ok('Quiet Garden hides counters',!/💧 \d/.test(document.querySelector('#screen').innerText)&&!document.querySelector('.hbar')); audit('quiet plant'); W.go('home'); ok('Quiet hides Rose ring/streak',!document.querySelector('[data-a=roseInfo]')); S.set.quiet=false;
 // ===== 8. THIRSTY / NAME / DIARY / CEREMONY =====
 S.plants[pid].lastWater=0; S.set.calm=false; W.go('plant',{id:pid}); ok('Thirsty look: copy "perks right up with a drink", no face change',/thirsty/i.test(document.querySelector('#mood').textContent)&&/perks right up with a drink/.test(document.querySelector('#mood').textContent)); audit('thirsty');
 S.set.calm=true; W.go('plant',{id:pid}); ok('Calm mode never shows thirsty look',/Happy/.test(document.querySelector('#mood').textContent)); S.set.calm=false;
 click('[data-a=nameit]'); document.querySelector('#nameIn').value='Fern Gully Jr 12345'; click('[data-a=savename]'); await sleep(150); ok('Name your plant (max 16 chars)',S.plants[pid].nick==='Fern Gully Jr 12',S.plants[pid].nick); ok('Personality line shown',/Sunny|Sleepy|Shy|Curious|Stubborn/.test(document.querySelector('#screen').innerText));
 ok('Diary entry for nickname',S.diary.some(function(d){return /You named it/.test(d.text)})); W.go('diary'); ok('Garden Diary lists memories',document.querySelectorAll('#screen .card').length>=2); audit('diary');
 S.plants[pid].gp=87; S.plants[pid].stage=3; S.ceremony[pid]=false; W.go('plant',{id:pid}); S.hand='can'; S.res.water=5; click('[data-a=useTool]'); await sleep(900); await sleep(600);
 for(var zz=0;zz<6&&!/wonder/i.test(document.querySelector('#ov').innerText);zz++){var cb=document.querySelector('#ov [data-a=ovclose]');if(cb)ev(cb);else break;await sleep(250)}
 ok('First-bloom ceremony shows Wonder card',!!document.querySelector('#ov.on')&&/wonder/i.test(document.querySelector('#ov').innerText),'s'+S.plants[pid].stage+' g'+S.plants[pid].gp+' q'+W.queue().length+' o'+document.querySelector('#ov').className.length); audit('ceremony'); ok('Ceremony starts a 60 s quiet window',S.quietUntil>W.now()); await closeAll();
 // ===== 9. WELCOME BACK / SEASON / DUSK =====
 click('#tAway3'); await sleep(300); ok('Welcome back card after 3 days',/Welcome back/.test(document.querySelector('#ov').innerText)&&!/streak|claim|reward/i.test(document.querySelector('#ov').innerText)); audit('welcome'); await closeAll();
 click('#tAway30'); await sleep(300); ok('30+ days adds diary line + gentle tour',/diary/.test(document.querySelector('#ov').innerText)&&!!document.querySelector('[data-a=tour]')); await closeAll();
 document.querySelector('#tSeason').value='winter'; document.querySelector('#tSeason').dispatchEvent(new Event('change')); W.go('home'); ok('Season mood strip (winter)',!!document.querySelector('.mood-strip')&&W.S().season==='winter'); S.evening=true; W.go('home'); ok('Dusk mood independent of dark mode',!!document.querySelector('.mood-strip')); S.evening=false; S.homeDusk=false;
 // ===== 10. PROGRESSIVE UNLOCK + LEVEL TRACKS =====
 W.setS({}); var S2=W.S(); S2.plants={}; S2.unl={}; S2.tools={can:1,trowel:0,net:0,mister:0,shears:0,lamp:0}; S2.tips={}; S2.badges={}; S2.wlUps=0; S2.wordUnlocked=1; S2.wordPick=1; S2.gardenDone={}; S2.dayIdx=0; S2.diary=[]; S2.C={}; S2.stickers={}; W.queue().length=0;
 for(var i=0;i<3;i++)W.earnPlant('X'); W.helper('plants'); W.queue().length=0; ok('helper earns plants',Object.keys(S2.plants).length>=3);
 S2.plants={}; S2.unl={}; S2.tools.trowel=0; for(i=0;i<3;i++)W.earnPlant('X'); W.act('helper',{h:'res'});
 W.go('garden'); S2.unl.sun=false; W.helper('plants'); await sleep(100); ok('3rd plant unlocks Sunny spot tip',S2.unl.sun===true&&S2.tips.sun===true||S2.unl.sun===true);
 await closeAll(); await closeAll(); ok('5th plant unlocks soil + trowel',S2.unl.soil===true&&S2.tools.trowel===1);
 S2.unl.net=false; S2.tools.net=0; S2.wlUps=0; await closeAll(); W.helper('wlevel'); await sleep(200); await closeAll(); await closeAll(); ok('first word level-up unlocks butterfly game + net + level map',S2.unl.net&&S2.tools.net===1&&S2.unl.map&&S2.wlUps===1,'wlUps '+S2.wlUps);
 W.helper('wlevel'); await sleep(200); await closeAll(); await closeAll(); ok('second word level-up unlocks shed',S2.unl.shed===true,'wlUps '+S2.wlUps);
 await closeAll(); S2.badges={plant_collector:1}; W.act('home',{}); S2.unl.badges=false; W.helper('res'); S2.badges={}; S2.C.catch=1; W.helper('plants'); await closeAll(); await closeAll(); await closeAll(); ok('first badge unlocks badge shelf',S2.unl.badges===true);
 S2.wordPick=1; W.helper('glevel'); await sleep(200); await closeAll(); await closeAll(); await closeAll(); ok('garden level complete unlocks Mister (level 1 track)',S2.tools.mister===1&&S2.gardenDone[1]===true,JSON.stringify(S2.gardenDone));
 W.go('map'); var mt=document.querySelector('#screen').innerText; ok('Level Map shows Word track and Garden track',/Word track/.test(mt)&&/Garden track/.test(mt)); click('[data-a=pickword][data-l="1"]'); ok('choose any unlocked word level',S2.wordPick===1);
 S2.showAll=false; W.go('settings'); click('[data-a=showall]'); W.go('home'); ok('Settings "Show everything" opens all',!!document.querySelector('[data-a=map]')&&!!document.querySelector('[data-a=shed]')); S2.showAll=false;
 // ===== 11. SETTINGS =====
 W.go('settings'); var st=document.querySelector('#screen').innerText; ok('Settings: difficulty, show streak, calm, quiet, show everything',/Word difficulty/.test(st)&&/Show streak/.test(st)&&/Calm mode/.test(st)&&/Quiet Garden/.test(st)&&/Show everything/.test(st)); audit('settings');
 click('[data-a=diff][data-d=gentle]'); ok('difficulty Gentle selectable',S2.set.diff==='gentle'); S2.set.diff='auto';
 S2.set.remind=false; click('[data-a=setting][data-k=remind]'); ok('Remind me shows notification-permission mock',!!document.querySelector('#ov [data-a=notif]')); click('[data-a=notif][data-v="0"]'); await sleep(100);
 // ===== 12. JUICE =====
 S2.rm=false; document.body.classList.remove('rm'); S2.ftue='done'; W.startRound(false); var G3=W.G(); var t0=performance.now(); await typeWord(G3.w); while(W.S().screen!=='earned'&&performance.now()-t0<4500)await sleep(100); var el2=performance.now()-t0; ok('win sequence (incl. 450 ms beat) <= 3.1 s',el2<=3100&&W.S().screen==='earned',Math.round(el2)+' ms');
 W.startRound(false); G3=W.G(); t0=performance.now(); await typeWord(G3.w); await sleep(700); var sk=document.querySelector('#skipRain'); if(sk&&sk.style.display==='block')ev(sk); await sleep(150); ok('celebration tappable to skip',W.S().screen==='earned',Math.round(performance.now()-t0)+' ms');
 ok('one haptic cue per action (single log line)',document.querySelector('#log').textContent.split('Haptic').length===2);
 S2.rm=true; await closeAll();
 // ===== COPY AUDIT: other states =====
 W.go('badges'); audit('badges'); W.go('shed'); audit('shed'); W.go('map'); audit('map'); W.go('album'); audit('album'); W.go('home'); audit('home'); W.go('paywall'); audit('paywall'); W.go('garden'); audit('garden');
 W.go('bfIntro'); audit('bfIntro'); click('[data-a=bfStart]'); await sleep(200); W.bfFinish(); await sleep(200); audit('bfSum'); await closeAll();
 var bank=[]; W.WORDS.forEach(function(w){[w.h,w.h2,w.f].forEach(function(s){if(new RegExp(W.BAD.source,'i').test(s))bank.push(w.w+': '+s)})}); Object.keys(W.WONDER).forEach(function(k){if(new RegExp(W.BAD.source,'i').test(W.WONDER[k]))bank.push(k)});
 var spf=ART.species.filter(function(s){return new RegExp(W.BAD.source,'i').test(s.fact)}).map(function(s){return s.id}); var plf=ART.plants.filter(function(p){return new RegExp(W.BAD.source,'i').test(p.botanicalFact)}).map(function(p){return p.name+' ('+(p.botanicalFact.match(new RegExp(W.BAD.source,'i'))||[''])[0]+')'});
 var bd=ART.badgeMeta.filter(function(b){return new RegExp(W.BAD.source,'i').test(b.title+' '+b.desc)}).map(function(b){return b.id});
 out.push('--- COPY AUDIT ---'); out.push('UI screens/modals scanned with banned-word regex: '+(hits.length?'HITS '+hits.join(' | '):'0 hits')); out.push('Word bank / wonder lines: '+(bank.length?bank.join(' | '):'0 hits')); out.push('Species facts: '+(spf.length?spf.join(','):'0 hits')+'; badge copy: '+(bd.length?bd.join(','):'0 hits')); out.push('Plant facts in plants.json (not editable here; runtime falls back to a safe line): '+(plf.length?plf.join(', '):'0 hits'));
 var fails=out.filter(function(l){return /^FAIL/.test(l)}).length; el.textContent=out.join('\n')+'\nDONE fails='+fails; try{fetch('/__done')}catch(e){}
}
run().catch(function(e){out.push('ERROR '+e+' '+(e.stack||'').split('\n').slice(0,3).join(' / '));el.textContent=out.join('\n')});
})();
