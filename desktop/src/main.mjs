/**
 * Electron application entry point. This process owns SQL credentials, encrypted
 * profiles and the local game child. Read docs/DEVELOPMENT.md before adding privileged
 * IPC or changing startup/close behaviour.
 */
import {
  app,
  BrowserWindow,
  dialog,
  ipcMain,
  protocol,
  net,
  safeStorage,
  session as electronSession,
} from "electron";
import { fileURLToPath, pathToFileURL } from "node:url";
import path from "node:path";
import mariadb from "mariadb";
import nodemailer from "nodemailer";
import { EditorSession } from "./session.mjs";
import { LocalServer } from "./server.mjs";
import { ConnectionProfiles, profileDetails } from "./profiles.mjs";

/**
 * Register the local asset scheme before Electron becomes ready. No page is loaded from
 * a web host.
 */
protocol.registerSchemesAsPrivileged([
  {
    scheme: "orp",
    privileges: { standard: true, secure: true, supportFetchAPI: true },
  },
]);
const ui = fileURLToPath(new URL("../ui/", import.meta.url));
const server = new LocalServer();
const editor = new EditorSession({
  connect: (options) => mariadb.createConnection(options),
  sendCode,
});
let window;
let quitting = false;
let operations = Promise.resolve();
let profiles, pendingProfile;
/**
 * Persist only after password authentication and any email challenge succeed. A
 * disk/encryption failure must not turn an otherwise valid login into a failed session.
 */
async function savePendingProfile(result) {
  if (!pendingProfile) return result;
  const candidate = pendingProfile;
  pendingProfile = null;
  try {
    if (!candidate.remember) {
      await profiles.touch(candidate.id);
      return { ...result, profileId: candidate.id };
    }
    return {
      ...result,
      profileId: await profiles.save(
        candidate.details,
        candidate.id,
        candidate.label,
      ),
    };
  } catch (error) {
    return {
      ...result,
      profileWarning:
        "Connected, but the connection could not be saved: " + error.message,
    };
  }
}

/**
 * Send a desktop-only email challenge through the operator’s own SMTP service. The
 * session owns expiry/attempt limits; this transport owns TLS and delivery timeouts.
 */
async function sendCode(input, recipient, code) {
  if (
    !input ||
    typeof input.host !== "string" ||
    !input.host.trim() ||
    typeof input.from !== "string" ||
    !input.from.includes("@")
  )
    throw new Error(
      "This account requires 2FA. Enter your own SMTP settings in the connection form.",
    );
  const port = Number(input.port || 587);
  if (!Number.isInteger(port) || port < 1 || port > 65535)
    throw new Error("Invalid SMTP port.");
  const mail = nodemailer.createTransport({
    host: input.host,
    port,
    secure: Boolean(input.secure),
    requireTLS:
      !input.secure && !["127.0.0.1", "localhost", "::1"].includes(input.host),
    auth: input.user ? { user: input.user, pass: input.password } : undefined,
    connectionTimeout: 5000,
    socketTimeout: 10000,
  });
  try {
    await mail.sendMail({
      from: input.from,
      to: recipient,
      subject: "OpenRP Framework desktop sign-in",
      text: `Your desktop sign-in code is ${code}. It expires in five minutes. If you did not request this, ignore this message.`,
    });
  } catch {
    throw new Error(
      "Could not send the email code. Check your own SMTP settings and account email address.",
    );
  } finally {
    mail.close();
  }
}

// Exact main-frame sender checks and an explicit channel list keep privileged
// database/process APIs out of subframes and arbitrary renderer messages.
/**
 * Register one named IPC operation. Verify the exact trusted main frame, serialize
 * operations to prevent database-switch races, and return a sanitized error envelope.
 */
function handle(channel, callback) {
  ipcMain.handle(`editor:${channel}`, async (event, ...args) => {
    if (
      event.sender !== window?.webContents ||
      event.senderFrame !== window.webContents.mainFrame ||
      event.senderFrame.url !== "orp://editor/index.html"
    )
      throw new Error("Untrusted editor frame.");
    try {
      // Switching databases cannot race a save or a pending account challenge.
      const operation = operations.then(() => callback(...args));
      operations = operation.catch(() => {});
      return { ok: true, value: await operation };
    } catch (error) {
      const message =
        error.sqlState ||
        /^(ER_|ECONN|ETIMEDOUT|ENOTFOUND|EHOST)/.test(error.code ?? "")
          ? "Database connection or query failed. Check credentials, permissions and the matching fresh schema."
          : error.message;
      return {
        ok: false,
        error: String(message).slice(0, 600),
        code: error.code === "conflict" ? "conflict" : undefined,
      };
    }
  });
}

if (!app.requestSingleInstanceLock()) app.quit();
else {
  app.on("second-instance", () => {
    if (window) {
      if (window.isMinimized()) window.restore();
      window.focus();
    }
  });
  /**
   * Build application services only after Electron initializes OS credential storage.
   * Keep startup asynchronous without blocking the ready event with top-level await.
   */
  void app.whenReady().then(async () => {
    profiles = new ConnectionProfiles(
      path.join(app.getPath("userData"), "connections.json"),
      {
        available: async () =>
          process.platform === "win32" &&
          (await safeStorage.isAsyncEncryptionAvailable()),
        encrypt: (value) => safeStorage.encryptStringAsync(value),
        decrypt: async (value) =>
          (await safeStorage.decryptStringAsync(value)).result,
      },
    );
    protocol.handle("orp", (request) => {
      const url = new URL(request.url);
      const files = new Set([
        "/index.html",
        "/app.js",
        "/styles.css",
        "/icon.png",
      ]);
      if (url.hostname !== "editor" || !files.has(url.pathname))
        return new Response("Not found", { status: 404 });
      return net.fetch(
        pathToFileURL(path.join(ui, url.pathname.slice(1))).href,
      );
    });
    electronSession.defaultSession.setPermissionRequestHandler(
      (_contents, _permission, callback) => callback(false),
    );
    electronSession.defaultSession.setPermissionCheckHandler(() => false);
    /**
     * Local profile operations do not grant SQL access. Login still validates the resolved
     * passwords, rank, ban status and email challenge before privileged operations.
     */
    handle("profiles-list", () => profiles.list());
    handle("profiles-load", (id) => profiles.publicDetails(id));
    handle("profiles-remove", (id) => profiles.remove(id));
    handle("login", async (input) => {
      pendingProfile = null;
      const resolved = await profiles.resolve(input);
      const result = await editor.login(resolved);
      if (input.rememberConnection || input.profileId)
        pendingProfile = {
          details: profileDetails(resolved),
          id: input.profileId || undefined,
          label: input.profileName,
          remember: Boolean(input.rememberConnection),
        };
      return result.challenge ? result : savePendingProfile(result);
    });
    handle("verify", async (code) =>
      savePendingProfile(await editor.verify(code)),
    );
    handle("logout", () => {
      pendingProfile = null;
      editor.clear();
      return true;
    });
    /**
     * Configuration IPC delegates to EditorSession: the renderer never chooses SQL
     * identifiers or supplies a trusted actor identity.
     */
    handle("load", () => editor.load());
    handle("status", () => editor.status());
    handle("entities", (type) => editor.entities(type));
    handle("save", (patch) => editor.save(patch));
    handle("restore", (revision, expected) =>
      editor.restore(revision, expected),
    );
    handle("preview-restore", (revision) => editor.previewRestore(revision));
    /**
     * Server controls share the same live Manager authorization as configuration writes.
     * LocalServer additionally enforces child-process ownership.
     */
    handle("server-status", () => editor.authorized(() => server.status()));
    handle("server-select", () =>
      editor.authorized(async () => {
        const result = await dialog.showOpenDialog(window, {
          title: "Choose the local open.mp server folder",
          properties: ["openDirectory"],
        });
        return result.canceled
          ? server.status()
          : server.select(result.filePaths[0]);
      }),
    );
    handle("server-start", () => editor.authorized(() => server.start()));
    handle("server-stop", (force) =>
      editor.authorized(() => server.stop(force === true)),
    );
    /**
     * The renderer is a sandboxed view. Keep Node disabled and expose only the preload
     * methods declared in preload.cjs.
     */
    window = new BrowserWindow({
      title: "OpenRP Framework Editor",
      width: 1440,
      height: 960,
      minWidth: 1024,
      minHeight: 720,
      backgroundColor: "#0b1020",
      icon: path.join(ui, "icon.png"),
      show: false,
      webPreferences: {
        preload: fileURLToPath(new URL("./preload.cjs", import.meta.url)),
        contextIsolation: true,
        sandbox: true,
        nodeIntegration: false,
        webSecurity: true,
      },
    });
    window.setMenuBarVisibility(false);
    window.webContents.setWindowOpenHandler(() => ({ action: "deny" }));
    window.webContents.on("will-navigate", (event) => event.preventDefault());
    window.once("ready-to-show", () => window.show());
    /**
     * Do not abandon an editor-owned game process on a normal window close. Offer graceful
     * shutdown; keep the editor open if the game cannot exit.
     */
    window.on("close", (event) => {
      if (!server.child || quitting) return;
      event.preventDefault();
      void (async () => {
        const { response } = await dialog.showMessageBox(window, {
          type: "question",
          title: "A local server is running",
          message: "Stop the server launched by this editor before closing?",
          buttons: ["Keep editor open", "Stop server and close"],
          defaultId: 0,
          cancelId: 0,
        });
        if (response !== 1) return;
        try {
          await server.stop();
          quitting = true;
          window.close();
        } catch (error) {
          await dialog.showMessageBox(window, {
            type: "warning",
            message: error.message,
          });
        }
      })();
    });
    await window.loadURL("orp://editor/index.html");
    app.on("window-all-closed", () => {
      editor.clear();
      app.quit();
    });
  });
}
