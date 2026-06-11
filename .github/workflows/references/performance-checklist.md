# Performance Checklist

Quick-reference for performance review passes. Referenced by `reviewing-code` and performance-sensitive implementations.

## Core Web Vitals Targets

| Metric | Good | Needs Improvement | Poor |
|--------|------|-------------------|------|
| LCP (Largest Contentful Paint) | ≤ 2.5s | ≤ 4.0s | > 4.0s |
| INP (Interaction to Next Paint) | ≤ 200ms | ≤ 500ms | > 500ms |
| CLS (Cumulative Layout Shift) | ≤ 0.1 | ≤ 0.25 | > 0.25 |
| TTFB (Time to First Byte) | ≤ 800ms | ≤ 1.8s | > 1.8s |

## Frontend Checks

- [ ] No render-blocking resources in the critical path
- [ ] Images use modern formats (WebP/AVIF) with proper `width`/`height` attributes
- [ ] Images lazy-loaded below the fold (`loading="lazy"`)
- [ ] Hero/LCP images preloaded (`<link rel="preload">`)
- [ ] No layout shifts from dynamically loaded content (reserve space with aspect-ratio or min-height)
- [ ] Fonts use `font-display: swap` or `optional` — no FOIT
- [ ] Third-party scripts deferred or loaded async — not blocking the main thread
- [ ] Bundle size checked — no unnecessary large dependencies (use `bundlephobia.com` or build analysis)
- [ ] Tree-shaking effective — no barrel file re-exports pulling in unused modules
- [ ] CSS not duplicated across chunks

## Vue / Nuxt Specific

- [ ] Heavy components use `defineAsyncComponent` or dynamic `import()` for code splitting
- [ ] `v-if` preferred over `v-show` for rarely-visible content (avoids DOM cost)
- [ ] `v-for` uses a stable, unique `:key` — not array index
- [ ] Computed properties used instead of methods for derived state (caching)
- [ ] `watch` has explicit cleanup and avoids triggering re-renders unnecessarily
- [ ] Large lists use virtual scrolling when items exceed 50+
- [ ] SSR/SSG leveraged for content pages — not everything needs to be client-rendered

## API & Data

- [ ] No N+1 query patterns (check GraphQL resolvers and REST endpoint loops)
- [ ] Pagination on all list endpoints — no unbounded data fetching
- [ ] API responses cached where appropriate (HTTP cache headers, CDN, in-memory)
- [ ] No synchronous blocking operations in request handlers
- [ ] Database queries indexed for common access patterns
- [ ] No large objects created in hot paths (loops, frequent re-renders)

## Measurement Commands

```bash
# Lighthouse CLI
npx lighthouse <url> --output=json --output-path=./report.json

# Bundle analysis (webpack)
npx webpack-bundle-analyzer stats.json

# Bundle analysis (vite)
npx vite-bundle-visualizer
```
