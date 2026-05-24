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
const docExtensions = new Set(['.md', '.mdx']);

const md = new MarkdownIt({
  html: true,
  linkify: true,
  typographer: false,
  breaks: false,
});

let currentOutline = null;
const slugify = (s) => encodeURIComponent(
  String(s).trim().toLowerCase().replace(/[\s\.]+/g, '-').replace(/[^\w一-鿿\-]/g, '')
);

md.use(anchor, {
  level: [1, 2, 3, 4],
  slugify,
  callback: (token, { slug, title }) => {
    if (!currentOutline || !title.trim()) {
      return;
    }
    currentOutline.push({
      level: Number(token.tag.slice(1)),
      slug,
      title: title.trim(),
    });
  },
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

// Rewrite local Markdown links → .html (preserve #fragment)
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
      const ext = path.extname(pathPart).toLowerCase();
      if (docExtensions.has(ext)) {
        const newHref = pathPart.slice(0, -ext.length) + '.html' + (hash ? '#' + hash : '');
        tokens[idx].attrs[hrefIndex][1] = newHref;
      }
    }
  }
  return defaultLinkOpen(tokens, idx, options, env, self);
};

function escapeHtml(s) {
  return md.utils.escapeHtml(String(s));
}

function isDocFile(name) {
  return docExtensions.has(path.extname(name).toLowerCase());
}

function toHtmlFileName(name) {
  const ext = path.extname(name);
  return name.slice(0, -ext.length) + '.html';
}

function isReadmeFile(name) {
  return /^README\.(md|mdx)$/i.test(name);
}

function renderMarkdown(src) {
  currentOutline = [];
  const bodyHtml = md.render(src);
  const outline = currentOutline;
  currentOutline = null;
  return { bodyHtml, outline };
}

function renderOutline(outline) {
  if (outline.length === 0) {
    return '        <li class="empty-outline">此文件沒有可用標題。</li>';
  }

  return outline
    .map(({ level, slug, title }) =>
      `        <li class="level-${level}"><a href="#${escapeHtml(slug)}">${escapeHtml(title)}</a></li>`
    )
    .join('\n');
}

async function main() {
  await fs.mkdir(outDir, { recursive: true });
  const template = await fs.readFile(templatePath, 'utf8');
  const entries = await fs.readdir(docsDir, { withFileTypes: true });
  const mdFiles = entries
    .filter((e) => e.isFile() && isDocFile(e.name))
    .map((e) => e.name);

  // Nav order: README first, then alphabetical
  const navItems = mdFiles
    .map((name) => ({ name, title: name.replace(/\.(md|mdx)$/i, '') }))
    .sort((a, b) => {
      if (isReadmeFile(a.name)) return -1;
      if (isReadmeFile(b.name)) return 1;
      return a.name.localeCompare(b.name);
    });

  const timestamp = new Date().toISOString().replace('T', ' ').slice(0, 19) + ' UTC';

  for (const name of mdFiles) {
    const srcPath = path.join(docsDir, name);
    const src = await fs.readFile(srcPath, 'utf8');

    const titleMatch = src.match(/^#\s+(.+)$/m);
    const title = titleMatch ? titleMatch[1].trim() : name;

    const { bodyHtml, outline } = renderMarkdown(src);

    const navHtml = navItems
      .map(({ name: n, title: t }) => {
        const href = n === name ? '#' : toHtmlFileName(n);
        const cls = n === name ? ' class="active"' : '';
        return `        <li${cls}><a href="${escapeHtml(href)}">${escapeHtml(t)}</a></li>`;
      })
      .join('\n');
    const outlineHtml = renderOutline(outline);

    const outHtml = template
      .replace(/\{\{TITLE\}\}/g, escapeHtml(title))
      .replace(/\{\{NAV\}\}/g, navHtml)
      .replace(/\{\{OUTLINE\}\}/g, outlineHtml)
      .replace(/\{\{SOURCE\}\}/g, escapeHtml('docs/' + name))
      .replace(/\{\{TIMESTAMP\}\}/g, escapeHtml(timestamp))
      .replace(/\{\{BODY\}\}/g, bodyHtml);

    const outPath = path.join(outDir, toHtmlFileName(name));
    await fs.writeFile(outPath, outHtml, 'utf8');
    console.log(`  ${name} -> docs/html/${path.basename(outPath)}`);
  }

  // index.html: redirect to README.html if present, else first file
  const readmeFile = mdFiles.find(isReadmeFile);
  let indexTarget = null;
  if (readmeFile) {
    indexTarget = toHtmlFileName(readmeFile);
  } else if (mdFiles[0]) {
    indexTarget = toHtmlFileName(mdFiles[0]);
  }
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
