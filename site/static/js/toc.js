// On narrow screens the sidebar is a menu above the article: start it closed, and close it when
// one of its links is followed.
document.addEventListener('DOMContentLoaded', () => {
  const menu = document.querySelector('.doc-nav-toggle');
  const narrow = window.matchMedia('(max-width: 900px)');
  if (!menu) return;
  if (narrow.matches) menu.open = false;
  narrow.addEventListener('change', (e) => { if (!e.matches) menu.open = true; });
  menu.querySelectorAll('a').forEach((a) => a.addEventListener('click', () => {
    if (narrow.matches) menu.open = false;
  }));
});

// Highlights the sidebar entry for the section being read.
document.addEventListener('DOMContentLoaded', () => {
  const links = [...document.querySelectorAll('.doc-nav li.here ol a[href*="#"]')];
  if (links.length === 0) return;

  const entries = links
    .map(link => {
      const id = decodeURIComponent(link.getAttribute('href').split('#')[1] || '');
      const heading = id && document.getElementById(id);
      return heading ? { link, heading } : null;
    })
    .filter(Boolean);

  const update = () => {
    const threshold = window.innerHeight * 0.25;
    let current = entries[0];
    for (const entry of entries) {
      if (entry.heading.getBoundingClientRect().top <= threshold) current = entry;
    }
    for (const { link } of entries) link.classList.toggle('active', link === current?.link);
  };

  let scheduled = false;
  window.addEventListener('scroll', () => {
    if (scheduled) return;
    scheduled = true;
    requestAnimationFrame(() => { scheduled = false; update(); });
  }, { passive: true });
  update();
});
