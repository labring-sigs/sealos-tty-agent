# sealos-tty-bridge

Kubernetes `exec` terminal gateway over WebSocket.

```
Browser (xterm.js) <-> this server (WS) <-> Kubernetes API Server (exec) <-> Pod PTY
```

## What’s in this repo

- **Server**: `sealos-tty-bridge` — a small HTTP + WebSocket gateway that turns Kubernetes `pods/exec` into a browser-friendly terminal stream.
- **Client**: `@labring/sealos-tty-client` — a Web Streams API client (in `packages/protocol-client`) that handles WebSocket auth + stream wiring for you.

## Server usage

### Local (dev)

```bash
pnpm install
cp config.example.json config.json
pnpm run dev
```

Default: `http://localhost:3000`.

### Production

```bash
# Using Docker Compose
docker compose up -d

# or use Docker CLI
# Build the image
docker build -t sealos-tty-bridge:latest .
# Spin up the container
docker run -d -p 3000:3000 -v $(pwd)/config.json:/app/config.json:ro sealos-tty-bridge:latest
```

## Client usage

The recommended client is `@labring/sealos-tty-client` (Web Streams API), designed for browser terminals like `xterm.js`.

```bash
pnpm add @labring/sealos-tty-client
```

Minimal browser example (xterm-style wiring):

```ts
import { connectTerminalStreams } from '@labring/sealos-tty-client'

const { stdout, stdin, resize } = await connectTerminalStreams({
	client: { baseUrl: 'http://localhost:3000' },
	connect: {
		kubeconfig,
		target: { namespace: 'default', pod: 'mypod', container: 'c1' },
		initialSize: { cols: term.cols, rows: term.rows },
	},
})

const enc = new TextEncoder()
const writer = stdin.getWriter()
term.onData(d => void writer.write(enc.encode(d)))
term.onResize(({ cols, rows }) => resize(cols, rows))

void stdout
	.pipeThrough(new TextDecoderStream())
	.pipeTo(new WritableStream({ write: s => term.write(s) }))
```

Notes:

- The server starts Kubernetes `exec` only after receiving the **first** `resize`.
- By default the client offers kubeconfig in `Sec-WebSocket-Protocol` using a stable `sealos-tty-v1` token plus a URL-encoded data-bearing token. Set `connect.authInMessage = true` to send kubeconfig in the first auth frame instead.
- `KUBE_API_SERVER` overrides the current cluster `server` in user kubeconfigs. Set it to `auto` to derive `https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT_HTTPS` inside a Kubernetes pod.

## Run

```bash
pnpm install
pnpm run dev
```

## API

### `GET /exec` (WebSocket)

- Query parameters:
  - `namespace=<namespace>`
  - `pod=<pod>`
  - optional `container=<container>`
  - optional repeated `command=<argv-part>` entries
- Authentication:
  - Preferred: offer `sealos-tty-v1` plus a kubeconfig-bearing token in `Sec-WebSocket-Protocol`; the server validates kubeconfig and echoes only `sealos-tty-v1`.
  - Fallback: if kubeconfig is not offered in the handshake, the first non-ping JSON message **must** be `{ "type": "auth", "kubeconfig": "..." }`.
- After auth, the client **must** send the first resize:
  - `{ "type": "resize", "cols": 120, "rows": 30 }`
  - The server starts Kubernetes exec only after receiving the first resize.

Binary frames:

- Client -> Server: stdin bytes
- Server -> Client: stdout/stderr bytes (TTY usually merged)

## Security

`kubeconfig` is sensitive. Use HTTPS/WSS and restrict RBAC for `pods/exec`.
