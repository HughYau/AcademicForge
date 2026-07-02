export const prefersReducedMotion = () =>
  typeof window !== 'undefined' && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

export function pulseEmber(element) {
  if (!(element instanceof Element) || prefersReducedMotion()) {
    return;
  }

  element.classList.remove('forge-glow');
  void element.getBoundingClientRect().width;
  element.classList.add('forge-glow');
}
