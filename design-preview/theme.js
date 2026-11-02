(function(){
  var KEY='wf-theme';
  function sys(){return matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light'}
  function get(){try{return localStorage.getItem(KEY)||sys()}catch(e){return sys()}}
  function apply(){document.documentElement.setAttribute('data-theme',get())}
  window.wfSetTheme=function(t){try{localStorage.setItem(KEY,t)}catch(e){}apply();
    document.querySelectorAll('iframe').forEach(function(f){try{f.contentWindow.document.documentElement.setAttribute('data-theme',t)}catch(e){}})};
  window.wfToggle=function(){wfSetTheme(get()==='dark'?'light':'dark')};
  apply();addEventListener('storage',apply);
})();
