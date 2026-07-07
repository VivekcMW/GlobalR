/* Daypart switching — mirrors Daypart.fromHour in lib/core/design_tokens.dart */
(function () {
  var SVG_OPEN = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">';
  var ICONS = {
    sunrise: SVG_OPEN + '<path d="M17 18a5 5 0 0 0-10 0"/><line x1="12" y1="8" x2="12" y2="3"/><polyline points="8.5 6.5 12 3 15.5 6.5"/><line x1="3" y1="21" x2="21" y2="21"/><line x1="4.5" y1="12" x2="6" y2="13.5"/><line x1="19.5" y1="12" x2="18" y2="13.5"/></svg>',
    sun: SVG_OPEN + '<circle cx="12" cy="12" r="4"/><line x1="12" y1="2" x2="12" y2="5"/><line x1="12" y1="19" x2="12" y2="22"/><line x1="2" y1="12" x2="5" y2="12"/><line x1="19" y1="12" x2="22" y2="12"/><line x1="4.9" y1="4.9" x2="7" y2="7"/><line x1="17" y1="17" x2="19.1" y2="19.1"/><line x1="4.9" y1="19.1" x2="7" y2="17"/><line x1="17" y1="7" x2="19.1" y2="4.9"/></svg>',
    sunset: SVG_OPEN + '<path d="M17 18a5 5 0 0 0-10 0"/><line x1="12" y1="3" x2="12" y2="8"/><polyline points="8.5 5.5 12 9 15.5 5.5"/><line x1="3" y1="21" x2="21" y2="21"/><line x1="4.5" y1="12" x2="6" y2="13.5"/><line x1="19.5" y1="12" x2="18" y2="13.5"/></svg>',
    moon: SVG_OPEN + '<path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z"/></svg>'
  };
  var DAYPARTS = {
    prabhat: { native: "प्रभात", greeting: "Good morning", line: "Prabhat — devotion & your morning brief", icon: "sunrise" },
    din:     { native: "दिन",    greeting: "Namaste",      line: "Din — news, learning & light stories",   icon: "sun" },
    sandhya: { native: "संध्या",  greeting: "Good evening", line: "Sandhya — folklore & festival tales",    icon: "sunset" },
    ratri:   { native: "रात्रि",  greeting: "Good night",   line: "Ratri — soft bedtime stories",           icon: "moon" },
  };

  function fromHour(h) {
    if (h >= 5 && h < 9) return "prabhat";
    if (h >= 9 && h < 17) return "din";
    if (h >= 17 && h < 21) return "sandhya";
    return "ratri";
  }

  function apply() {
    var key = fromHour(new Date().getHours());
    var d = DAYPARTS[key];
    document.body.dataset.daypart = key;
    var g = document.getElementById("greeting");
    var l = document.getElementById("heroline");
    if (g) g.innerHTML = ICONS[d.icon] + "<span>" + d.greeting + " · " + d.native + "</span>";
    if (l) l.textContent = d.line + ". Global Radio plays what fits this hour — automatically.";
  }

  apply();
  setInterval(apply, 60 * 1000);
})();
