// Deliberately expose operations, never raw IPC, SQL, filesystem or process APIs.
const { contextBridge, ipcRenderer } = require("electron");
/** Bind one allowed operation and unwrap main's result envelope. Keeping this
 * factory private prevents the page from inventing channel names or raw IPC calls.
 */
const invoke =
  (channel) =>
  async (...args) => {
    const result = await ipcRenderer.invoke("editor:" + channel, ...args);
    if (!result.ok) {
      const error = new Error(result.error);
      error.code = result.code;
      throw error;
    }
    return result.value;
  };
contextBridge.exposeInMainWorld(
  "editor",
  Object.freeze({
    // Authentication and profiles never expose stored password values to the page.
    login: invoke("login"),
    verify: invoke("verify"),
    logout: invoke("logout"),
    profilesList: invoke("profiles-list"),
    profilesLoad: invoke("profiles-load"),
    profilesRemove: invoke("profiles-remove"),
    // Read snapshots, prepare restore previews and commit validated revisions.
    load: invoke("load"),
    status: invoke("status"),
    entities: invoke("entities"),
    save: invoke("save"),
    restore: invoke("restore"),
    previewRestore: invoke("preview-restore"),
    // No arbitrary console commands or PID controls are exposed.
    serverStatus: invoke("server-status"),
    serverSelect: invoke("server-select"),
    serverStart: invoke("server-start"),
    serverStop: invoke("server-stop"),
  }),
);
