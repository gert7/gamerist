$(function(e){function r(){var r=e("script:first"),t=r.css("color"),n=!1;if(/^rgba/.test(t))n=!0;else try{n=t!==r.css("color","rgba(0, 0, 0, 0.5)").css("color"),r.css("color",t)}catch(o){}return r.removeAttr("style"),n}function t(r,t,n){var o=[];return e.each(r,function(s){var l=[],a=r[s];if(s=t[s],a.b&&l.push("inset"),"undefined"!=typeof s.left&&l.push(parseFloat(a.left+n*(s.left-a.left))+"px "+parseFloat(a.top+n*(s.top-a.top))+"px"),"undefined"!=typeof s.blur&&l.push(parseFloat(a.blur+n*(s.blur-a.blur))+"px"),"undefined"!=typeof s.a&&l.push(parseFloat(a.a+n*(s.a-a.a))+"px"),"undefined"!=typeof s.color){var u="rgb"+(e.support.rgba?"a":"")+"("+parseInt(a.color[0]+n*(s.color[0]-a.color[0]),10)+","+parseInt(a.color[1]+n*(s.color[1]-a.color[1]),10)+","+parseInt(a.color[2]+n*(s.color[2]-a.color[2]),10);e.support.rgba&&(u+=","+parseFloat(a.color[3]+n*(s.color[3]-a.color[3]))),u+=")",l.push(u)}o.push(l.join(" "))}),o.join(", ")}function n(r){function t(){var e=/^inset\b/.exec(r.substring(p));return null!==e&&e.length>0?(f.b=!0,p+=e[0].length,!0):!1}function n(){var e=/^(-?[0-9\.]+)(?:px)?\s+(-?[0-9\.]+)(?:px)?(?:\s+(-?[0-9\.]+)(?:px)?)?(?:\s+(-?[0-9\.]+)(?:px)?)?/.exec(r.substring(p));return null!==e&&e.length>0?(f.left=parseInt(e[1],10),f.top=parseInt(e[2],10),f.blur=e[3]?parseInt(e[3],10):0,f.a=e[4]?parseInt(e[4],10):0,p+=e[0].length,!0):!1}function o(){var e=/^#([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})/.exec(r.substring(p));return null!==e&&e.length>0?(f.color=[parseInt(e[1],16),parseInt(e[2],16),parseInt(e[3],16),1],p+=e[0].length,!0):(e=/^#([0-9a-fA-F])([0-9a-fA-F])([0-9a-fA-F])/.exec(r.substring(p)),null!==e&&e.length>0?(f.color=[17*parseInt(e[1],16),17*parseInt(e[2],16),17*parseInt(e[3],16),1],p+=e[0].length,!0):(e=/^rgb\(\s*([0-9\.]+)\s*,\s*([0-9\.]+)\s*,\s*([0-9\.]+)\s*\)/.exec(r.substring(p)),null!==e&&e.length>0?(f.color=[parseInt(e[1],10),parseInt(e[2],10),parseInt(e[3],10),1],p+=e[0].length,!0):(e=/^rgba\(\s*([0-9\.]+)\s*,\s*([0-9\.]+)\s*,\s*([0-9\.]+)\s*,\s*([0-9\.]+)\s*\)/.exec(r.substring(p)),null!==e&&e.length>0?(f.color=[parseInt(e[1],10),parseInt(e[2],10),parseInt(e[3],10),parseFloat(e[4])],p+=e[0].length,!0):!1)))}function s(){var e=/^\s+/.exec(r.substring(p));return null!==e&&e.length>0?(p+=e[0].length,!0):!1}function l(){var e=/^\s*,\s*/.exec(r.substring(p));return null!==e&&e.length>0?(p+=e[0].length,!0):!1}function a(r){if(e.isPlainObject(r)){var t,n,o=0,s=[];for(e.isArray(r.color)&&(n=r.color,o=n.length),t=0;4>t;t++)s.push(o>t?n[t]:3===t?1:0)}return e.extend({left:0,top:0,blur:0,spread:0},r)}for(var u=[],p=0,c=r.length,f=a();c>p;)if(t())s();else if(n())s();else if(o())s();else{if(!l())break;u.push(a(f)),f={}}return u.push(a(f)),u}e.extend(!0,e,{support:{rgba:r()}});var o,s=e("html").prop("style");e.each(["boxShadow","MozBoxShadow","WebkitBoxShadow"],function(e,r){return"undefined"!=typeof s[r]?(o=r,!1):void 0}),o&&(e.Tween.propHooks.boxShadow={get:function(r){return e(r.elem).css(o)},set:function(r){var s,l=r.elem.style,a=n(e(r.elem)[0].style[o]||e(r.elem).css(o)),u=n(r.end),p=Math.max(a.length,u.length);for(s=0;p>s;s++)u[s]=e.extend({},a[s],u[s]),a[s]?"color"in a[s]&&e.isArray(a[s].color)!==!1||(a[s].color=u[s].color||[0,0,0,0]):a[s]=n("0 0 0 0 rgba(0,0,0,0)")[0];r.run=function(e){e=t(a,u,e),l[o]=e}}})});