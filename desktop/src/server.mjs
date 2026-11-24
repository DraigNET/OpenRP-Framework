// Owns only the child launched by this editor. No PID discovery, shell commands
// or attachment to existing servers: another installation must remain untouched.
import { EventEmitter } from "node:events";
import { createRequire } from "node:module";
import { realpath, stat, readFile } from "node:fs/promises";
import path from "node:path";
import dgram from "node:dgram";
import { networkInterfaces } from "node:os";
import { isIP } from "node:net";

/**
 * Manage one owned Windows game process and a bounded console buffer. Never
 * discover/kill another server by port, executable name or an arbitrary PID.
 */
export class LocalServer {
  /**
   * Inject process launch and port probing for tests. Production uses a hidden Windows
   * pseudo-terminal, while tests can supply disposable Node children.
   */
  constructor({
    launch = launchConsole,
    checkPort = availablePort,
    platform = process.platform,
  } = {}) {
    this.launch = launch;
    this.checkPort = checkPort;
    this.platform = platform;
    this.child = null;
    this.directory = null;
    this.log = "";
    this.busy = false;
  }
  /**
   * Keep only the newest console characters so long-running sessions cannot grow renderer
   * payloads without a bound.
   */
  append(text) {
    this.log = (this.log + text).slice(-200000);
  }
  /**
   * Return display-only process state. The child handle remains private to the main
   * process.
   */
  status() {
    return {
      running: Boolean(this.child),
      pid: this.child?.pid ?? null,
      directory: this.directory,
      log: this.log,
      busy: this.busy,
    };
  }
  /**
   * Resolve a user-selected runtime and ensure its executable stays within that folder.
   * Switching installations requires the owned process to be stopped.
   */
  async select(directory) {
    if (this.child || this.busy)
      throw new Error(
        "Stop the editor-owned server before changing its folder.",
      );
    const root = await realpath(directory);
    const executable = await realpath(path.join(root, "omp-server.exe"));
    if (
      path.dirname(executable).toLowerCase() !== root.toLowerCase() ||
      !(await stat(executable)).isFile()
    )
      throw new Error(
        "Choose a server folder containing omp-server.exe, without an executable symlink outside that folder.",
      );
    this.directory = root;
    return this.status();
  }
  /**
   * Read the runtime’s own configuration, probe its bind/port, and launch a single owned
   * child. Starting a process does not prove the gamemode connected successfully.
   */
  async start() {
    if (this.platform !== "win32")
      throw new Error("Local server controls currently support Windows only.");
    if (this.child || this.busy)
      throw new Error("This editor already has a running or starting server.");
    if (!this.directory)
      throw new Error("Choose the open.mp server folder first.");
    this.busy = true;
    try {
      const executable = await realpath(
        path.join(this.directory, "omp-server.exe"),
      );
      if (
        path.dirname(executable).toLowerCase() !== this.directory.toLowerCase()
      )
        throw new Error(
          "The executable must remain inside the selected server folder.",
        );
      const config = JSON.parse(
        await readFile(path.join(this.directory, "config.json"), "utf8"),
      );
      const port = config.network?.port ?? 7777;
      if (!Number.isInteger(port) || port < 1 || port > 65535)
        throw new Error("Invalid network.port in config.json.");
      await this.checkPort(port, config.network?.bind || "0.0.0.0");
      this.log = "";
      const child = this.launch(executable, [], {
        cwd: this.directory,
        windowsHide: true,
        shell: false,
        stdio: ["pipe", "pipe", "pipe"],
      });
      this.child = child;
      child.stdout?.on("data", (data) => this.append(data.toString()));
      child.stderr?.on("data", (data) => this.append(data.toString()));
      child.stdin?.on("error", () => {});
      child.on("error", () => {
        this.append(
          "\nServer launch failed. Check the runtime files and permissions.\n",
        );
        if (this.child === child) this.child = null;
      });
      child.on("close", (code) => {
        this.append(`\nServer exited (${code ?? "terminated"}).\n`);
        if (this.child === child) this.child = null;
      });
      await new Promise((resolve, reject) => {
        child.once("spawn", resolve);
        child.once("error", reject);
      });
      return this.status();
    } finally {
      this.busy = false;
    }
  }
  // open.mp's exit command gets the first opportunity to flush SQL and shut down.
  // Force termination is a separate, explicit action if the console cannot stop it.
  /**
   * Try the game’s exit command first. Force termination is a separate explicit action
   * and is limited to the child retained by this instance.
   */
  async stop(force = false) {
    const child = this.child;
    if (!child) return this.status();
    if (force) child.kill();
    else child.stdin?.write("exit\n");
    await new Promise((resolve) => {
      const timer = setTimeout(done, force ? 3000 : 10000);
      function done() {
        clearTimeout(timer);
        child.off("close", done);
        resolve();
      }
      child.once("close", done);
    });
    if (this.child === child)
      throw new Error(
        "The server is still running. Review its log, then use Force stop only if necessary.",
      );
    return this.status();
  }
}

// open.mp reads the Windows console, not redirected stdin. A pseudo-terminal
// provides that console invisibly and keeps graceful exit available in the app.
/**
 * Adapt node-pty to the child event interface used by LocalServer. Translate newlines
 * to Windows console input and strip terminal formatting from displayed logs.
 */
function launchConsole(executable, args, options) {
  const pty = createRequire(import.meta.url)("node-pty");
  const terminal = pty.spawn(executable, args, {
    cwd: options.cwd,
    name: "xterm-color",
    cols: 140,
    rows: 40,
    env: process.env,
    useConpty: true,
  });
  const child = new EventEmitter();
  child.pid = terminal.pid;
  child.stdout = new EventEmitter();
  child.stdin = new EventEmitter();
  child.stdin.write = (text) => terminal.write(text.replaceAll("\n", "\r"));
  child.kill = () => terminal.kill();
  terminal.onData((data) =>
    child.stdout.emit("data", data.replace(/\u001b\[[0-?]*[ -/]*[@-~]/g, "")),
  );
  terminal.onExit((event) => child.emit("close", event.exitCode));
  queueMicrotask(() => child.emit("spawn"));
  return child;
}

/**
 * Probe the intended IPv4 bind before launch. Windows can allow
 * wildcard/specific-address UDP sockets to coexist, so wildcard binding checks all
 * local interfaces.
 */
async function availablePort(port, bind = "0.0.0.0") {
  if (isIP(bind) !== 4)
    throw new Error("Local controls require an IPv4 network.bind address.");
  // Windows can allow a wildcard and a specific-address UDP bind to coexist.
  // Probe each interface when open.mp will bind all interfaces, not just 0.0.0.0.
  const addresses =
    bind === "0.0.0.0"
      ? [
          ...new Set([
            "0.0.0.0",
            "127.0.0.1",
            ...Object.values(networkInterfaces())
              .flat()
              .filter((item) => item?.family === "IPv4")
              .map((item) => item.address),
          ]),
        ]
      : [bind];
  for (const address of addresses)
    await new Promise((resolve, reject) => {
      const socket = dgram.createSocket("udp4");
      socket.once("error", () => {
        socket.close();
        reject(
          new Error(
            "The configured game port is unavailable. Stop the other server yourself or choose another installation.",
          ),
        );
      });
      socket.bind({ port, address, exclusive: true }, () =>
        socket.close(resolve),
      );
    });
}
