export const prefersReducedMotion = () =>
  typeof window !== 'undefined' && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

export function spawnSparks(anchor, count = 5) {
  if (!(anchor instanceof Element) || prefersReducedMotion()) {
    return;
  }

  const rect = anchor.getBoundingClientRect();
  const host = document.createElement('span');
  host.className = 'forge-sparks';
  host.setAttribute('aria-hidden', 'true');
  host.style.left = `${rect.left + rect.width / 2}px`;
  host.style.top = `${rect.top + rect.height / 2}px`;

  for (let index = 0; index < count; index += 1) {
    const particle = document.createElement('span');
    particle.className = 'forge-spark';
    const angle = (Math.PI * 2 * index) / count + Math.random() * 0.9;
    const distance = 16 + Math.random() * 16;
    particle.style.setProperty('--dx', `${Math.cos(angle) * distance}px`);
    particle.style.setProperty('--dy', `${Math.sin(angle) * distance - 8}px`);
    particle.style.animationDelay = `${Math.round(Math.random() * 60)}ms`;
    host.append(particle);
  }

  document.body.append(host);
  window.setTimeout(() => host.remove(), 750);
}

export function pulseEmber(element) {
  if (!(element instanceof Element) || prefersReducedMotion()) {
    return;
  }

  element.classList.remove('forge-glow');
  void element.getBoundingClientRect().width;
  element.classList.add('forge-glow');
}
