// Card search matching. Skill text mixes "single-cell", "single cell" and
// "scRNA-seq", so a raw substring test makes natural queries come back empty.
// Both sides are normalized so separators are interchangeable, and each query
// word must appear somewhere (in any order).

const SEPARATORS = /[\s\-_/\.,:;|+#()[\]{}'"`·—–]+/g;

export const normalizeSearchText = (text) =>
  String(text ?? '').normalize('NFKC').toLowerCase().replace(SEPARATORS, ' ').trim();

export const matchesSearch = (text, query) => {
  const words = normalizeSearchText(query).split(' ').filter(Boolean);
  if (words.length === 0) {
    return true;
  }

  const spaced = normalizeSearchText(text);
  // "rnaseq" should still find "rna-seq", so also test against the text with separators dropped.
  const joined = spaced.replaceAll(' ', '');
  return words.every((word) => spaced.includes(word) || joined.includes(word));
};
