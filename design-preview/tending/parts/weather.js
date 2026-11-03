/* WordFlora weather demo. Canvas rain (<=60 drops, 30 fps cap) + gentle lightning flash.
   Cost: one path per layer, no per-drop gradients, colour cached on theme change, paused when the tab is hidden. */
(function(){
'use strict';
var W=390,H=844,FPS=30,STEP=1000/FPS;
// Intensity per day: drops, thunder on/off. Thunder from day 4.
var LEVELS={1:{n:12,t:0,name:'drizzle'},2:{n:20,t:0,name:'light drizzle'},3:{n:32,t:0,name:'light rain'},
 4:{n:42,t:1,name:'rain + far thunder'},5:{n:50,t:1,name:'steady rain + thunder'},6:{n:56,t:1,name:'heavier rain + thunder'},7:{n:60,t:1,name:'heavier rain + thunder'}};
// Depth layers: far -> near. Speed px/s, length (= speed/30 so streaks join at 30 fps), width, alpha, ground band (far lands higher).
var LAYERS=[{sp:520,len:17,w:.8,a:.30,g:[560,640],share:.45},{sp:760,len:25,w:1.2,a:.45,g:[640,740],share:.35},{sp:1050,len:35,w:1.8,a:.62,g:[740,830],share:.20}];
var SLANT=.18; // dx per dy, slight wind
var CLOUD_Y=220; // drops are born under the cloud body
var cv=document.getElementById('rain'),cx=cv.getContext('2d'),root=document.documentElement;
var flashEl=document.querySelector('.flash'),boltEl=document.querySelector('.bolt'),phone=document.querySelector('.phone'),label=document.getElementById('lvl');
var drops=[],splashes=[],splCap=18,day=4,last=0,raf=0,thunderTimer=0,lastFlash=-1e9,forceReduced=false,col='70,110,150';
function dpr(){return Math.min(window.devicePixelRatio||1,2)}
function size(){var d=dpr();cv.width=W*d;cv.height=H*d;cx.setTransform(d,0,0,d,0,0);cx.lineCap='round'}
function rnd(a,b){return a+Math.random()*(b-a)}
function reduced(){return forceReduced||(window.matchMedia&&matchMedia('(prefers-reduced-motion: reduce)').matches)}
function readColour(){col=getComputedStyle(root).getPropertyValue('--drop').trim()||'70,110,150'}
function mk(L,fresh){var l=LAYERS[L];return{L:L,x:rnd(20,W-20),y:fresh?CLOUD_Y-rnd(0,60):rnd(CLOUD_Y,l.g[0]),gy:rnd(l.g[0],l.g[1])}}
function build(){drops=[];var n=LEVELS[day].n,used=0;LAYERS.forEach(function(l,i){var c=i<LAYERS.length-1?Math.round(n*l.share):n-used;used+=c;for(var k=0;k<c;k++)drops.push(mk(i,false))});splCap=Math.round(4+n*.5)}
function frame(t){
 raf=0;if(document.hidden)return;
 raf=requestAnimationFrame(frame);
 if(!last){last=t;return}
 var dt=t-last;if(dt<STEP-1)return;last=t;var s=Math.min(dt,100)/1000;
 cx.clearRect(0,0,W,H);var paths=LAYERS.map(function(){return new Path2D()});
 for(var i=0;i<drops.length;i++){var d=drops[i],l=LAYERS[d.L];
  d.y+=l.sp*s;d.x+=l.sp*s*SLANT;
  if(d.y>=d.gy){if(splashes.length<splCap)splashes.push({x:d.x,y:d.gy,a:0,L:d.L});drops[i]=mk(d.L,true);continue}
  if(d.y<CLOUD_Y)continue;
  var top=Math.max(CLOUD_Y,d.y-l.len);paths[d.L].moveTo(d.x,d.y);paths[d.L].lineTo(d.x-(d.y-top)*SLANT,top)}
 LAYERS.forEach(function(l,i){cx.strokeStyle='rgba('+col+','+l.a+')';cx.lineWidth=l.w;cx.stroke(paths[i])});
 for(var j=splashes.length-1;j>=0;j--){var p=splashes[j];p.a+=s/.4;if(p.a>=1){splashes.splice(j,1);continue}
  var r=2+p.a*(5+p.L*3),al=(1-p.a)*(.2+p.L*.12);
  cx.strokeStyle='rgba('+col+','+al+')';cx.lineWidth=.8+p.L*.3;cx.beginPath();cx.ellipse(p.x,p.y,r,r*.35,0,0,6.283);cx.stroke();
  if(p.a<.5){cx.fillStyle='rgba('+col+','+al+')';cx.fillRect(p.x-r*.6,p.y-p.a*10,1.2,1.2);cx.fillRect(p.x+r*.6,p.y-p.a*8,1.2,1.2)}}
}
function run(){if(!raf&&!reduced()&&!document.hidden){last=0;raf=requestAnimationFrame(frame)}}
function halt(){cancelAnimationFrame(raf);raf=0;last=0}
// Lightning: single soft flash, never faster than 1 per 8 s (spec: 8-15 s). Manual button still waits 1.4 s so a flash is never cut off.
function flash(force){
 if(reduced()||!LEVELS[day].t)return;
 var now=performance.now();if(now-lastFlash<(force?1400:8000))return;lastFlash=now;
 [flashEl,boltEl].forEach(function(e){e.classList.remove('on');void e.getBoundingClientRect();e.classList.add('on')});
 var delay=rnd(300,500); // haptic/sound lag after flash
 document.dispatchEvent(new CustomEvent('wf-thunder',{detail:{delayMs:delay}}));
 var ev=document.getElementById('evt');if(ev){ev.textContent='flash -> rumble + haptic in '+Math.round(delay)+' ms'}
}
function schedule(){clearTimeout(thunderTimer);if(!LEVELS[day].t||reduced())return;thunderTimer=setTimeout(function(){flash(false);schedule()},rnd(8000,15000))}
function apply(){
 var r=reduced();phone.classList.toggle('reduced',r);label.textContent='Day '+day+': '+LEVELS[day].name+' ('+LEVELS[day].n+' drops'+(LEVELS[day].t?', thunder 8-15 s':', no thunder')+')';
 halt();clearTimeout(thunderTimer);cx.clearRect(0,0,W,H);
 if(r){[flashEl,boltEl].forEach(function(e){e.classList.remove('on')});return}
 build();splashes=[];run();schedule();
}
document.getElementById('day').addEventListener('change',function(e){day=+e.target.value;apply()});
document.getElementById('dark').addEventListener('click',function(){var d=root.dataset.theme==='dark';root.dataset.theme=d?'light':'dark'});
document.getElementById('rm').addEventListener('click',function(){forceReduced=!forceReduced;apply()});
document.getElementById('now').addEventListener('click',function(){flash(true)});
document.addEventListener('visibilitychange',function(){document.hidden?halt():run()});
new MutationObserver(readColour).observe(root,{attributes:true,attributeFilter:['data-theme']});
if(window.matchMedia)matchMedia('(prefers-reduced-motion: reduce)').addEventListener('change',apply);
readColour();size();apply();
})();
