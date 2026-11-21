// A minimal app to prove your Nobus deploy works. Replace it with your product.
const http = require("http");

const port = Number(process.env.PORT) || 3000;
const team = process.env.TEAM_NAME || "Your team";

const server = http.createServer((req, res) => {
  if (req.url === "/health") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ ok: true }));
    return;
  }
  res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
  res.end(`<!doctype html><title>${team}</title>
<body style="font-family:system-ui;background:#0D2B55;color:#FFFDF8;display:grid;place-items:center;height:100vh;margin:0">
<div style="text-align:center"><h1>Hello from ${team}</h1><p>Live on Nobus Cloud</p></div></body>`);
});

// Listen on 0.0.0.0 so the server is reachable from outside the container.
server.listen(port, "0.0.0.0", () => console.log(`Listening on ${port}`));
