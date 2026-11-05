/* Chosen direction: B (tool tiles), revised after the critic round. Steals A's scene, Now/Next and pots shelf, and C's jar-on-a-shelf. */
document.head.insertAdjacentHTML('beforeend',`<style>
.hdr{border-radius:22px;overflow:hidden;border:1.5px solid color-mix(in srgb,var(--sh-ic) 30%,transparent);background:var(--bd-bg);box-shadow:0 1px 2px var(--shadow-c)}
.hdr .scene{border:0;border-radius:0;box-shadow:none}
.ptsbar{display:flex;align-items:center;gap:10px;padding:10px 12px 12px 16px;border-top:1.5px solid color-mix(in srgb,var(--bd-ic) 25%,transparent)}
.ptsbar .t{flex:1;min-width:0}.ptsbar b{display:block;font-size:1.0625em;font-weight:800}.ptsbar span{font-size:.875em;color:var(--txt2)}
.playb{display:inline-flex;align-items:center;gap:6px;border:0;border-radius:999px;min-height:44px;padding:6px 16px;background:var(--vi-bg);color:var(--text);font:inherit;font-weight:800;font-size:.9375em;box-shadow:inset 0 0 0 1.5px color-mix(in srgb,var(--vi-ic) 55%,transparent);white-space:nowrap}
.playb img{width:22px;height:22px}
.ax .ptsbar{flex-wrap:wrap}.ax .playb{width:100%;justify-content:center}
.tg2{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.tile2{display:flex;flex-direction:column;align-items:center;text-align:center;gap:4px;padding:12px 8px 12px;border-radius:20px;background:var(--tb);border:1.5px solid color-mix(in srgb,var(--ti) 30%,transparent);box-shadow:0 1px 2px rgba(0,0,0,.05)}
.tile2 .art{width:66px;height:66px;border-radius:50%;background:color-mix(in srgb,var(--surface) 72%,transparent);display:grid;place-items:center;margin-bottom:2px}
.tile2 .art img{width:58px;height:62px}
.tile2 h3{margin:0;font-size:1em;font-weight:800;line-height:1.2}
.tile2 .pips i{width:11px;height:11px;box-shadow:inset 0 0 0 2px var(--ti)}.tile2 .pips i.on{box-shadow:none}
.ax .tile2 .pips i,.sheet2 .pips i{width:15px;height:15px}
.tile2 .eff{font-size:.8125em;font-weight:700;line-height:1.25}
.tile2 .rdy{margin-top:4px;display:inline-flex;align-items:center;gap:4px;font-size:.75em;font-weight:800;background:var(--accent);color:var(--accent-ink);padding:3px 10px;border-radius:999px}
.tile2 .rdy svg{width:11px;height:11px}
.tile2.soon{background:color-mix(in srgb,var(--tb) 45%,var(--lockfill));border:1.5px dashed color-mix(in srgb,var(--text) 60%,var(--lockfill))}
.tile2.soon .art{background:transparent;box-shadow:inset 0 0 0 2px color-mix(in srgb,var(--text) 35%,transparent)}
.sil{filter:brightness(0);opacity:.38}
[data-theme=dark] .sil{filter:brightness(0) invert(1);opacity:.5}
.tile2.soon .eff{font-weight:600;color:var(--txt2)}
.ax .tg2{grid-template-columns:1fr}
.ax .tile2{flex-direction:row;flex-wrap:wrap;text-align:left;align-items:center;gap:6px 12px;padding:14px}
.ax .tile2 .art{flex:none}.ax .tile2 .tx{flex:1;min-width:0;display:flex;flex-direction:column;gap:4px;align-items:flex-start}
.tile2 .tx{display:contents}.ax .tile2 .tx{display:flex}
.sheet2{background:color-mix(in srgb,var(--tb) 55%,var(--surface))}
.sheet2 .top{background:var(--tb);border:1.5px solid color-mix(in srgb,var(--ti) 30%,transparent)}
.sheet2 .rows p{font-weight:700}
.sheet2 .bar{height:10px;border-radius:5px}
.sheet2 .of{font-size:.875em}
.potsheet .top{background:var(--surface)}
.rmtag{position:absolute;top:58px;left:14px;z-index:8;font-size:11px;font-weight:800;padding:2px 8px;border-radius:999px;background:var(--text);color:var(--bg)}
.rm .bfly{display:none}
</style>`);

const BF=`../../brand/v4/svg/visitors/monarch-sticker.svg`;
const T2=[
 {id:'can',name:'Watering can',tier:2,tint:'lv',does:['Waters 1 plant per tap','Waters 2 plants per tap','Waters 3 plants per tap'],quiet:'Waters your plants'},
 {id:'trowel',name:'Trowel',tier:1,tint:'sh',does:['Small soil boost','Bigger soil boost','Biggest soil boost'],quiet:'Adds soil for growing'},
 {id:'net',name:'Butterfly net',tier:1,tint:'vi',does:['Small catch circle','Bigger catch circle','Biggest catch circle'],quiet:'Catches visitors gently'},
 {id:'mister',name:'Mister',tier:1,tint:'gd',does:['Mist every 4 hours','Mist every 3 hours','Mist every 2 hours'],quiet:'Mists your plants'},
 {id:'shears',name:'Shears',tier:0,tint:'bl',does:['A trim helps a bit','A trim helps more','A trim helps lots'],find:'Find at garden level 2',quietFind:'Comes as your garden grows'},
 {id:'lamp',name:'Sun lamp',tier:0,tint:'bd',does:['Sunshine helps a bit','Sunshine helps more','Sunshine helps lots'],find:'Find at garden level 3',quietFind:'Comes as your garden grows'},
];
const pipsQ=t=>pips(t);
function header2(o={}){
 const bar=o.quiet?`<div class="ptsbar" style="background:var(--gd-bg)"><div class="t"><b>Quiet Garden is on</b><span>Your tools are ready to use.</span></div></div>`
  :`<div class="ptsbar"><div class="t"><b>${PTS} shed points</b><span>Earn more in the butterfly game.</span></div><button class="playb" aria-label="Play the butterfly game"><img src="${BF}" alt="">Play</button></div>`;
 return `<div class="hdr"><div class="scene">${sceneSVG(!o.quiet)}</div>${bar}</div>`}
function tile2(t,o={}){
 if(!t.tier)return `<div class="tile2 soon t-${t.tint}" role="button" aria-label="${t.name}. ${o.quiet?t.quietFind:t.find}."><span class="art"><img class="sil" src="${toolImg(t.id,1,true)}" alt=""></span><span class="tx"><h3>${t.name}</h3><span class="eff">${o.quiet?t.quietFind:t.find}</span></span></div>`;
 const c=cost(t.tier+1),ready=!o.quiet&&c&&PTS>=c;
 return `<div class="tile2 t-${t.tint}" role="button" aria-label="${t.name}. Tier ${t.tier} of 3. ${o.quiet?t.quiet:t.does[t.tier-1]}.${ready?' Upgrade ready.':''}"><span class="art"><img src="${toolImg(t.id,t.tier)}" alt=""></span><span class="tx"><h3>${t.name}</h3>${pips(t.tier,false)}<span class="eff">${o.quiet?t.quiet:t.does[t.tier-1]}</span>${ready?`<span class="rdy">${UP}Upgrade ready</span>`:''}</span></div>`}
const scr2=(o={})=>`${header2(o)}<div class="sec">Tools<small>Tap a tool to see what it does.</small></div><div class="tg2">${T2.map(t=>tile2(t,o)).join('')}</div>${shelf(o)}`;
function sheet2(t,o={}){const c=cost(t.tier+1);
 const act=o.quiet?'':!c?`<p class="full" style="color:var(--text)">All three tiers. Great tool!</p>`:PTS>=c?`<button class="pbtn">Upgrade for ${c} shed points</button>`
  :`<div class="next" style="margin:0"><span class="bar"><i style="width:${PTS/c*100}%"></i></span><span class="of">${PTS} of ${c} points</span></div><p style="margin:8px 0 0;font-size:.875em;color:var(--txt2)">Earn more in the butterfly game.</p>`;
 return `<div class="dim"></div><div class="sheet sheet2 t-${t.tint}"><div class="grab"></div><div class="top"><span class="art"><img src="${toolImg(t.id,t.tier)}" alt=""></span><div><h3>${t.name}</h3>${pips(t.tier)}</div></div>
 <div class="rows"><p><span>Now</span>${o.quiet?t.quiet:t.does[t.tier-1]}</p>${o.quiet||!c?'':`<p><span>Next</span>${t.does[t.tier]}</p>`}</div>${act}</div>`}
function potSheet(p,line,sub){return `<div class="dim"></div><div class="sheet potsheet t-bd"><div class="grab"></div><div class="top" style="background:var(--bd-bg)"><span class="art" style="background:var(--surface)">${potSVG16(p,64,sub?'full':'ghost')}</span><div><h3>${p.name}</h3><span style="font-size:.875em;color:var(--txt2)">${sub||'A pot to earn'}</span></div></div><div class="rows"><p style="font-weight:600">${line}</p></div><button class="pbtn">OK</button></div>`}
const cele2=`<div class="dim"></div><div class="cele t-sh"><div class="ring"><img src="${toolImg('trowel',2)}" alt=""></div><h3>Your trowel got better!</h3>${pips(2)}<p>Now it gives a bigger soil boost.</p><button class="pbtn">Yay!</button></div>`;

const potsQ=T2.length;
document.getElementById('verdict').innerHTML=`<p class="sub">Critic review of the nine frames above (rendered PNGs, light and dark).</p><ul>
<li><b>Ranking:</b> B first (charm at a glance, matches the Home v2 tiles, big tap targets), C second (most ownable, but hard to read and the points line sits away from the jar), A third (clearest for each tool, but it reads most like a list, and the scene takes height without doing anything).</li>
<li><b>Winner: B</b>, with C's jar on a shelf and A's Now/Next, pots shelf and footer folded in.</li>
<li><b>Fixes taken:</b> a bigger scene with the jar on the shed shelf; a real 44pt "Play" pill for the butterfly game; "Ready" moved out of the art and into the tile text as "Upgrade ready"; the effect text darker and shorter ("Mist every 4 hours"); pip rings 2pt; tools to find now softly tinted silhouettes, not grey dashed boxes ("Find at garden level 2"); the sheet warmed to the tool's tint, with the "44 of 120" bar when you are short; Quiet Garden spelled out with no numbers; Dewdrop now says "Visit 7 days"; "On Daisy" now says "Used by Daisy"; Quiet shelf title is "Your pot shelf".</li>
<li><b>Contrast found:</b> the tool silhouettes in dark mode were too faint. They now use an inverted silhouette at 50%: light about 3.4:1 and dark about 4.3:1 against the tile. No banned words in any frame.</li></ul>`;
document.getElementById('picksub').innerHTML='Direction B, revised. A wooden shed scene with the seed jar on its shelf and a points bar under it, two-column tool tiles in the Home v2 colours, then sixteen pots on four planks. Tap a tool or a pot for a warm sheet. Frames: light, dark, tools to find, pots (light and dark), tool sheet (short of points), upgrade moment, a Plus pot tapped, a pot to earn tapped, Quiet Garden (top and pots), large text, Reduce Motion.';
const PP=(html,o={})=>phone(wrap(html,o.scroll),{title:'Garden Shed',tag:'proposed',...o});
document.getElementById('rowP').innerHTML=[
 fig('p-light','Light','Scene with the jar on the shelf, points bar with a Play pill, colour tiles. "Upgrade ready" shows when you have enough points.',PP(scr2())),
 fig('p-dark','Dark','Same, dark set. Wood, fills and icons all switch.',PP(scr2(),{theme:'dark'})),
 fig('p-find','Tools to find','Scrolled. Shears and the sun lamp are soft silhouettes in their own tint, with where to find them. No lock.',PP(scr2(),{scroll:'tg2'})),
 fig('p-pots','Pots shelf','Four planks of four. Earned: colour and a green check. To earn: soft silhouette and the goal. Plus: colour and a Plus pill, no price.',PP(scr2(),{scroll:'pots'})),
 fig('p-pots-dark','Pots shelf, dark','',PP(scr2(),{scroll:'pots',theme:'dark'})),
 fig('p-sheet','Tool sheet, short of points','Tapped the can. Now and Next, then a bar ("44 of 120 points") and where to earn more. No grey button that cannot be tapped.',PP(scr2(),{over:sheet2(T2[0])})),
 fig('p-up','Upgrade moment','After "Upgrade for 30": the new art, pips fill, one line on what changed, one button. Reduce Motion: a fade.',PP(scr2(),{over:cele2})),
 fig('p-plus','Plus pot tapped','Gentle, no price and no buy button: "Moonlit is part of WordFlora Plus. A grown-up can find Plus in Settings."',PP(scr2(),{scroll:'pots',over:potSheet(POTS16.find(p=>p.id==='moonlit'),'Moonlit is part of WordFlora Plus. A grown-up can find Plus in Settings.','Part of WordFlora Plus')})),
 fig('p-earn','Pot to earn tapped','Positive goal plus progress in words.',PP(scr2(),{scroll:'pots',over:potSheet(POTS16.find(p=>p.id==='mint'),'Grow 15 plants to earn this pot. You have grown 12 so far!')})),
 fig('p-quiet','Quiet Garden','No points, prices or numbers. The jar leaves the shelf; the bar says your tools are ready. Tiles show pips and what the tool does.',PP(scr2({quiet:true}))),
 fig('p-quiet-pots','Quiet Garden, pots','"Your pot shelf", and to-earn pots say "Comes as you grow".',PP(scr2({quiet:true}),{scroll:'pots'})),
 fig('p-ax','Large text (AX sizes)','Tiles become one column, art to the left. The points bar stacks, with a full-width Play. Pots: two per plank.',PP(scr2({ax:true}),{ax:true})),
 fig('p-rm','Reduce Motion','The lamp does not sway, the glow does not pulse, and the butterfly at the door is hidden. The upgrade card fades in.',PP(scr2())+'').replace('class="phone','class="phone rm'),
].join('');
/* AX shelf: pots at 2 per plank are drawn by shelf({ax:true}) */
