/* Shared helpers for the Shed / Visitors / Butterfly game mockups.
   URL params: ?theme=light|dark (page), ?only=<frame id> (one phone, for screenshots). */
(function(){
 const q=new URLSearchParams(location.search);const t=q.get('theme');
 if(t==='dark'||t==='light')document.documentElement.setAttribute('data-theme',t);
 if(q.get('only'))document.documentElement.classList.add('only');
})();
const Q=new URLSearchParams(location.search);
const ART='../brand/v4/svg/';
const vis=(id,f)=>`${ART}visitors/${id}-${f}.svg`;
const tool=(id,t,mono)=>`${ART}tools/${id}-t${Math.max(1,t)}-${mono?'mono':'color'}.svg`;

/* VisitorCatalog.all (WordFlora/Rules/Butterfly.swift:15). fact:null = the app ships no fact yet. */
const VISITORS=[
 {id:'monarch',name:'Monarch',rarity:'uncommon',fact:'Monarch butterflies can migrate up to 3,000 miles.'},
 {id:'swallowtail',name:'Swallowtail',rarity:'uncommon',fact:'Swallowtail hindwing tails may trick predators into pecking the wings, not the body.'},
 {id:'cabbagewhite',name:'Cabbage White',rarity:'common',fact:'Cabbage whites began in Eurasia and now live on many continents, spread by people.'},
 {id:'paintedlady',name:'Painted Lady',rarity:'common',fact:null},
 {id:'honeybee',name:'Honeybee',rarity:'common',fact:null},
 {id:'bumblebee',name:'Bumblebee',rarity:'common',fact:null},
 {id:'ladybug',name:'Ladybug',rarity:'common',fact:null},
 {id:'dragonfly',name:'Dragonfly',rarity:'uncommon',fact:'Dragonfly ancestors zoomed through the sky about 300 million years ago, before dinosaurs.'},
 {id:'morpho',name:'Blue Morpho',rarity:'rare',fact:null},
 {id:'hummingbird',name:'Hummingbird',rarity:'rare',fact:"A hummingbird's wings flap about 50 times a second."},
 {id:'firefly',name:'Firefly',rarity:'uncommon',night:true,fact:null},
 {id:'luna',name:'Luna Moth',rarity:'rare',night:true,fact:null},
];
const V=id=>VISITORS.find(v=>v.id===id);
const RARITY_WORD={common:'Often seen',uncommon:'Sometimes seen',rare:'Rare visitor'};

const IC={
 back:'<svg viewBox="0 0 13 21"><path d="M11 2L2.5 10.5 11 19" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></svg>',
 star:'<svg viewBox="0 0 24 24"><path fill="currentColor" d="M12 2l2.9 6.6 7.1.6-5.4 4.7 1.6 7L12 17.3 5.8 21l1.6-7L2 9.2l7.1-.6z"/></svg>',
 drop:'<svg viewBox="0 0 24 24"><path fill="currentColor" d="M12 2s7 7.6 7 12.5A7 7 0 0 1 5 14.5C5 9.6 12 2 12 2z"/></svg>',
 box:'<svg viewBox="0 0 24 24"><path fill="currentColor" d="M3 7l9-4 9 4v10l-9 4-9-4zm9 2l6.5-2.9L12 3.2 5.5 6.1z"/></svg>',
 book:'<svg viewBox="0 0 24 24"><path fill="currentColor" d="M5 3h11a3 3 0 0 1 3 3v15H7a2 2 0 0 1-2-2zm2 14v2h10v-2z"/></svg>',
 ck:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.5l4.5 4.5L19 7"/></svg>',
 sprout:'<svg viewBox="0 0 24 24"><path fill="currentColor" d="M12 13C12 8 8 6 4 6c0 4 3 7 8 7Zm0-2c0-4 3-6 8-6 0 4-3 6-8 6Zm-1-1h2v11h-2z"/></svg>',
 moon:'<svg viewBox="0 0 24 24"><path fill="currentColor" d="M14.5 2.5A9.5 9.5 0 1 0 21.5 15 7.5 7.5 0 0 1 14.5 2.5z"/></svg>',
 leaf:'<svg viewBox="0 0 24 24"><path fill="currentColor" d="M20 3C9 3 4 8 4 15c0 1.5.3 2.7.8 3.7C3.7 19.8 3 21 3 21h2c.4-.6 1-1.3 1.7-1.8 1 .5 2.2.8 3.3.8 8 0 11-6 10-16z"/></svg>',
 heart:'<svg viewBox="0 0 24 24"><path fill="currentColor" d="M12 21s-8-5.3-8-11a4.5 4.5 0 0 1 8-2.8A4.5 4.5 0 0 1 20 10c0 5.7-8 11-8 11z"/></svg>',
};

/* A 393 x 852 iPhone. o: {theme, ax, title, back, right, tag:'now'|'proposed', bodyStyle, raw (no nav)} */
function phone(inner,o={}){
 const tag=o.tag?`<span class="tagc tagp ${o.tag==='proposed'?'tag-prop':'tag-now'}">${o.tag==='proposed'?'Proposed':'App today'}</span>`:'';
 const nav=o.raw?'':`<div class="nav">${o.back!==false?`<span class="back">${IC.back}${o.back||'Home'}</span>`:''}<span>${o.title||''}</span>${o.right?`<span class="right">${o.right}</span>`:''}</div>`;
 return `<div class="phone${o.ax?' ax':''}" data-theme="${o.theme||'light'}" ${o.id?`id="${o.id}"`:''}><div class="sb"><span>9:41</span><i></i><b>100%</b></div>${tag}${nav}${o.raw?inner:`<div class="body" style="${o.bodyStyle||''}">${inner}</div>`}${o.over||''}<div class="home"></div></div>`;
}
/* A captioned frame. Use ?only=<id> to screenshot one. */
function fig(id,cap,small,html){
 const pick=Q.get('only')===id?' pick':'';
 return `<div class="fig${pick}" data-id="${id}">${html}<p class="cap">${cap}${small?`<small>${small}</small>`:''}</p></div>`;
}
function themeButton(el){
 const b=document.querySelector(el);if(!b)return;
 const sync=()=>b.textContent=document.documentElement.dataset.theme==='dark'?'Page: light':'Page: dark';
 b.onclick=()=>{wfToggle();sync()};sync();
}
const WM=`<img class="wm lt" src="../logo/final/wordmark.svg" alt="WordFlora"><img class="wm dk" src="../logo/final/wordmark-dark.svg" alt="WordFlora">`;

/* Pots (PotCatalog.swift / ../pots/pots.json). Same drawing as ../pots/index.html potSVG. */
const POTS=[{"id":"plainBlue","name":"Plain blue","body":"#5B8FD0","rim":"#7AA6DE","shade":"#4677B3","decoration":{"kind":"none","colors":[]},"unlock":{"kind":"free","value":0},"a11y":"Plain blue pot"},{"id":"terracotta","name":"Terracotta","body":"#C8734A","rim":"#DD8C63","shade":"#A85A36","decoration":{"kind":"rings","colors":["#7E3F22"]},"unlock":{"kind":"plants","value":1},"a11y":"Terracotta pot with two rings"},{"id":"sageGlaze","name":"Sage glaze","body":"#8FB08C","rim":"#B4CCB1","shade":"#76996F","decoration":{"kind":"drip","colors":["#E2EFDE"]},"unlock":{"kind":"plants","value":10},"a11y":"Sage green pot with a drippy glaze"},{"id":"sunflower","name":"Sunflower","body":"#F2C230","rim":"#F8D95F","shade":"#D9A514","decoration":{"kind":"flower","colors":["#E07F2A","#6B4528"]},"unlock":{"kind":"level","value":3},"a11y":"Yellow pot with a big flower"},{"id":"starlight","name":"Starlight","body":"#2F6670","rim":"#5A98A2","shade":"#224C54","decoration":{"kind":"stars","colors":["#FFE27A","#FFFFFF"]},"unlock":{"kind":"level","value":5},"a11y":"Deep teal pot with twinkly stars"},{"id":"rosePink","name":"Rose pink","body":"#E8869F","rim":"#F2A9BC","shade":"#CC6683","decoration":{"kind":"hearts","colors":["#FFE9EF"]},"unlock":{"kind":"plants","value":25},"a11y":"Pink pot with hearts"},{"id":"mint","name":"Mint","body":"#7CCFA8","rim":"#A8E5C8","shade":"#5BB38A","decoration":{"kind":"dots","colors":["#FFFFFF"]},"unlock":{"kind":"plants","value":50},"a11y":"Mint green pot with white dots"},{"id":"honeyStripe","name":"Honey stripe","body":"#E39B2E","rim":"#F2BC5E","shade":"#C47F18","decoration":{"kind":"stripes","colors":["#FFF0C2"]},"unlock":{"kind":"plus","value":0},"a11y":"Honey pot with up and down stripes"},{"id":"moonlit","name":"Moonlit","body":"#3B4A80","rim":"#7383C4","shade":"#2A3560","decoration":{"kind":"moon","colors":["#F6E08A","#F6E08A"]},"unlock":{"kind":"plus","value":0},"a11y":"Night blue pot with a moon and tiny stars"},{"id":"meadow","name":"Meadow","body":"#F3E6BF","rim":"#5E9E45","shade":"#D6C38E","decoration":{"kind":"flowerBand","colors":["#6FA552","#FFFFFF","#F6A6BE","#F2B632"]},"unlock":{"kind":"plus","value":0},"a11y":"Cream pot with a band of grass and tiny flowers"}];
const STAR='M0 -7 Q1 -1.5 7 0 Q1 1.5 0 7 Q-1 1.5 -7 0 Q-1 -1.5 0 -7Z';
const HEART='M0 5 C-8 -1 -8 -8 -3 -8 C-1 -8 0 -6 0 -6 C0 -6 1 -8 3 -8 C8 -8 8 -1 0 5Z';
const BODY='M18 20 H102 L92 88 Q91 96 82 96 H38 Q29 96 28 88Z';
let _uid=0;
function potSVG(p,size,mode='full'){
 const id='pc'+(_uid++);const g=mode==='ghost';
 const B=g?'var(--soft)':p.body,R=g?'var(--soft)':p.rim,S=g?'var(--softink)':p.shade;
 const C=(i)=>g?'var(--softink)':p.decoration.colors[i];
 const h=size*100/120;let d='';const k=p.decoration.kind;
 if(k==='rings')d=`<rect x="18" y="38" width="84" height="7" fill="${C(0)}"/><rect x="18" y="52" width="84" height="7" fill="${C(0)}" opacity=".7"/>`;
 if(k==='drip')d=`<rect x="18" y="20" width="84" height="10" fill="${C(0)}"/>`+[[26,12],[40,20],[54,10],[68,22],[82,14],[94,9]].map(([x,hh])=>`<rect x="${x-4}" y="26" width="8" height="${hh}" rx="4" fill="${C(0)}"/>`).join('');
 if(k==='flower')d=`<g transform="translate(60 58)" fill="${C(0)}">${[0,45,90,135,180,225,270,315].map(a=>`<ellipse cx="0" cy="-10" rx="4.5" ry="9" transform="rotate(${a})"/>`).join('')}<circle r="7" fill="${C(1)}"/></g>`;
 if(k==='stars')d=[[38,46,1.25,0],[80,52,1,0],[60,74,1.4,0],[88,76,.7,1],[34,72,.7,1]].map(([x,y,s,c])=>`<path d="${STAR}" transform="translate(${x} ${y}) scale(${s})" fill="${C(c)}"/>`).join('');
 if(k==='hearts')d=[[40,46,1.1],[80,46,1.1],[60,70,1.5]].map(([x,y,s])=>`<path d="${HEART}" transform="translate(${x} ${y}) scale(${s})" fill="${C(0)}"/>`).join('');
 if(k==='dots')d=`<g fill="${C(0)}" opacity=".85">`+[[34,36],[56,34],[78,36],[96,40],[44,52],[66,52],[86,56],[38,70],[58,72],[78,74],[50,88],[70,88]].map(([x,y])=>`<circle cx="${x}" cy="${y}" r="4.5"/>`).join('')+'</g>';
 if(k==='stripes')d=[22,42,62,82,102].map(x=>`<rect x="${x-4.5}" y="20" width="9" height="80" fill="${C(0)}"/>`).join('');
 if(k==='moon')d=`<path fill="${C(0)}" d="M54.62 41.06A15 15 0 1 0 69.68 62.15A13 13 0 0 1 54.62 41.06Z"/>`+[[84,42],[82,78]].map(([x,y])=>`<path d="${STAR}" transform="translate(${x} ${y}) scale(.55)" fill="${C(1)}"/>`).join('')+`<circle cx="36" cy="40" r="2" fill="${C(1)}"/><circle cx="40" cy="80" r="2" fill="${C(1)}"/>`;
 if(k==='flowerBand'){d=`<g fill="${C(0)}"><rect x="18" y="70" width="84" height="30"/>${[26,35,44,53,62,71,80,89,98].map(x=>`<circle cx="${x}" cy="70" r="5"/>`).join('')}</g>`+[32,48,64,80,94].map((x,i)=>`<g transform="translate(${x} 80)" fill="${g?'var(--soft)':p.decoration.colors[i%2?2:1]}">${[0,72,144,216,288].map(a=>`<circle cx="0" cy="-3.5" r="3" transform="rotate(${a})"/>`).join('')}<circle r="2" fill="${g?'var(--softink)':p.decoration.colors[3]}"/></g>`).join('')}
 const strips=g?'':`<path d="M18 20 H34 L42 96 H38 Q29 96 28 88Z" fill="#fff" opacity=".14"/><path d="M102 20 H88 L82 96 Q91 96 92 88Z" fill="${S}" opacity=".45"/>`;
 const deco=g?`<g opacity=".55">${d}</g>`:d;
 const outline=g?`<path d="${BODY}" fill="none" stroke="var(--softink)" stroke-width="2" stroke-dasharray="5 4"/>`:'';
 const rim=`<rect x="10" y="4" width="100" height="18" rx="9" fill="${R}" ${g?'stroke="var(--softink)" stroke-width="2" stroke-dasharray="5 4"':''}/>`+(g?'':'<rect x="16" y="8" width="88" height="5" rx="2.5" fill="#fff" opacity=".35"/>');
 return `<svg class="pot" width="${size}" height="${h.toFixed(1)}" viewBox="0 0 120 100" role="img" aria-label="${p.a11y}"><defs><clipPath id="${id}"><path d="${BODY}"/></clipPath></defs><path d="${BODY}" fill="${B}"/><g clip-path="url(#${id})">${strips}${deco}</g>${outline}${rim}</svg>`;
}
