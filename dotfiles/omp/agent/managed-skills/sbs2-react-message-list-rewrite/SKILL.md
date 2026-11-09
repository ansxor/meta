---
name: sbs2-react-message-list-rewrite
description: Rewrite the sbs2 message-list controller into React components while avoiding flushSync in lifecycle and preserving the imperative adapter API.
---

# Rewrite sbs2 message-list controller to React components

## Goal
Replace the imperative `services/message-list.ts` controller with idiomatic React components while preserving the existing DOM shape (`<message-list>`, `<message-block>`, `<message-part>`, `<reply-block>`), merge behavior, boundary markers, live message handling, and the imperative `MessageList` adapter API used by views.

## High-level architecture
- Create `app/src/components/messages/MessageList.tsx` with `MessageListComponent` (forwardRef, exposing `MessageListHandle`) and helper sub-components (`MessageBlock`, `MessagePart`, `ReplyBlock`).
- Keep the `MessageList` class in `app/src/services/message-list.ts` as a thin adapter that mounts `MessageListComponent` into a provided host element and delegates methods to the handle.
- Keep shared `<message-controls>` floating singleton in `app/src/components/messages/MessageControls.tsx` and re-export `send_mce` from both the adapter and the component so existing callers keep working.
- `MessageListView.tsx` should render `<message-list>` directly and mount `MessageListComponent` as a child, not create a second React root.

## Critical runtime rules
- Never call `createRoot` inside a React component that is already part of a React tree. This causes duplicate `createRoot` warnings and lifecycle mismatches.
- Never call `flushSync` from inside a React lifecycle method (render, `useLayoutEffect`, ref callback, `useEffect`). It throws the "flushSync was called from inside a lifecycle method" warning and can leave handles `null`.
- For adapter methods that may be called before the component is mounted, use a mutable `useRef`-style handle ref and queue calls until the handle is available. Do not rely on `flushSync` to force synchronous availability.
- For secondary lists rendered inside a parent (e.g. PageView pinned messages), render the component as a JSX child with an `initialMessages` prop instead of calling `new MessageList(...)` inside a scroll callback.
- If a child needs a real DOM host, pass the host via a callback ref backed by React state (or `useState`) so the child receives the element once the ref fires, not a one-time `null` value from `ref.current`.
- Native event listeners that depend on the host element should reattach when the host changes (e.g. dependency on the host prop/state), not run once with `[]`.

## Verification
- `cd app && npm run typecheck` must pass.
- `cd app && npm run build` must pass.
- Browser smoke test: switch pages and confirm no `flushSync`, `createRoot`, or `display_edge` null errors.

## Push / workflow
- If origin push is denied, push to the personal fork (`ansxor/sbs2`) and close the bead with that note.
- Run `bd dolt push` if a Dolt remote is configured; otherwise the local `.beads/` Dolt DB is sufficient.
