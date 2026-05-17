import MarkdownIt from 'markdown-it';
import anchor from 'markdown-it-anchor';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, '..', '..');
const docsDir = path.join(repoRoot, 'docs');
const outDir = path.join(docsDir, 'html');
const templatePath = path.join(__dirname, 'template.html');

const md = new MarkdownIt({
  html: true,
  linkify: true,
  typographer: false,
  breaks: false,
});

md.use(anchor, {
  slugify: (s) => encodeURIComponent(
    String(s).trim().toLowerCase().replace(/[\s\.]+/g, '-').replace(/[^\w一-鿿\-]/g, '')
  ),
});

// Mermaid fence → <pre class="mermaid">
const defaultFence = md.renderer.rules.fence;
md.renderer.rules.fence = function (tokens, idx, options, env, self) {
  const token = tokens[idx];
  const info = (token.info || '').trim().toLowerCase();
  if (info === 'mermaid') {
    const escaped = md.utils.escapeHtml(token.content);
    return `<pre class="mermaid">${escaped}</pre>\n`;
  }
  return defaultFence(tokens, idx, options, env, self);
};

// Rewrite local .md links → .html (preserve #fragment)
const defaultLinkOpen =
  md.renderer.rules.link_open ||
  ((tokens, idx, options, env, self) => self.renderToken(tokens, idx, options));
md.renderer.rules.link_open = function (tokens, idx, options, env, self) {
  const hrefIndex = tokens[idx].attrIndex('href');
  if (hrefIndex >= 0) {
    const href = tokens[idx].attrs[hrefIndex][1];
    if (
      href &&
      !/^[a-z]+:\/\//i.test(href) &&
      !href.startsWith('mailto:') &&
      !href.startsWith('#')
    ) {
      const [pathPart, hash = ''] = href.split('#');
      if (pathPart.endsWith('.md')) {
        const newHref = pathPart.slice(0, -3) + '.html' + (hash ? '#' + hash : '');
        tokens[idx].attrs[hrefIndex][1] = newHref;
      }
    }
  }
  return defaultLinkOpen(tokens, idx, options, env, self);
};

function escapeHtml(s) {
  return md.utils.escapeHtml(String(s));
}

async function main() {
  await fs.mkdir(outDir, { recursive: true });
  const template = await fs.readFile(templatePath, 'utf8');
  const entries = await fs.readdir(docsDir, { withFileTypes: true });
  const mdFiles = entries
    .filter((e) => e.isFile() && e.name.endsWith('.md'))
    .map((e) => e.name);

  // Nav order: README first, then alphabetical
  const navItems = mdFiles
    .map((name) => ({ name, title: name.replace(/\.md$/, '') }))
    .sort((a, b) => {
      if (a.name === 'README.md') return -1;
      if (b.name === 'README.md') return 1;
      return a.name.localeCompare(b.name);
    });

  const timestamp = new Date().toISOString().replace('T', ' ').slice(0, 19) + ' UTC';

  for (const name of mdFiles) {
    const srcPath = path.join(docsDir, name);
    const src = await fs.readFile(srcPath, 'utf8');

    const titleMatch = src.match(/^#\s+(.+)$/m);
    const title = titleMatch ? titleMatch[1].trim() : name;

    const bodyHtml = md.render(src);

    const navHtml = navItems
      .map(({ name: n, title: t }) => {
        const href = n === name ? '#' : n.replace(/\.md$/, '.html');
        const cls = n === name ? ' class="active"' : '';
        return `        <li${cls}><a href="${escapeHtml(href)}">${escapeHtml(t)}</a></li>`;
      })
      .join('\n');

    const outHtml = template
      .replace(/\{\{TITLE\}\}/g, escapeHtml(title))
      .replace(/\{\{NAV\}\}/g, navHtml)
      .replace(/\{\{SOURCE\}\}/g, escapeHtml('docs/' + name))
      .replace(/\{\{TIMESTAMP\}\}/g, escapeHtml(timestamp))
      .replace(/\{\{BODY\}\}/g, bodyHtml);

    const outPath = path.join(outDir, name.replace(/\.md$/, '.html'));
    await fs.writeFile(outPath, outHtml, 'utf8');
    console.log(`  ${name} -> docs/html/${path.basename(outPath)}`);
  }

  // index.html: redirect to README.html if present, else first file
  const indexTarget = mdFiles.includes('README.md')
    ? 'README.html'
    : mdFiles[0]?.replace(/\.md$/, '.html');
  if (indexTarget) {
    const indexHtml = `<!doctype html><meta charset="utf-8"><title>docs</title><meta http-equiv="refresh" content="0; url=${indexTarget}">`;
    await fs.writeFile(path.join(outDir, 'index.html'), indexHtml, 'utf8');
    console.log(`  index.html -> ${indexTarget} (redirect)`);
  }

  console.log(`\nDone. ${mdFiles.length} files converted to docs/html/`);
}

main().catch((err) => {
  console.error('[build-docs-html] FAILED:', err);
  process.exit(1);
});
