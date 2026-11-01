import test from 'node:test';
import assert from 'node:assert/strict';

import { matchesSearch, normalizeSearchText } from './search.mjs';

const anndata = 'sa.anndata anndata handles annotated matrices in single-cell analysis, .h5ad and zarr files. 单细胞分析中带注释矩阵的数据结构';
const bulk = 'sa.bulk-rnaseq end-to-end bulk rna-seq orchestration from raw fastq to qc/trimming';

test('separators in the query and the text are interchangeable', () => {
  assert.ok(matchesSearch(anndata, 'single cell'));
  assert.ok(matchesSearch(anndata, 'single-cell'));
  assert.ok(matchesSearch(anndata, 'single_cell'));
});

test('a joined word matches its hyphenated form', () => {
  assert.ok(matchesSearch(bulk, 'rnaseq'));
  assert.ok(matchesSearch(bulk, 'rna-seq'));
});

test('every word must appear, in any order', () => {
  assert.ok(matchesSearch(bulk, 'fastq bulk'));
  assert.ok(!matchesSearch(bulk, 'fastq protein'));
});

test('matching ignores case and surrounding whitespace', () => {
  assert.ok(matchesSearch(anndata, '  ZARR  '));
});

test('an empty query matches everything', () => {
  assert.ok(matchesSearch(bulk, ''));
  assert.ok(matchesSearch(bulk, '   '));
});

test('Chinese queries still match', () => {
  assert.ok(matchesSearch(anndata, '单细胞'));
});

test('normalizeSearchText collapses punctuation runs into single spaces', () => {
  assert.equal(normalizeSearchText('QC/Trimming -- (STAR)'), 'qc trimming star');
});
