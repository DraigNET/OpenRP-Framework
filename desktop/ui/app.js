/**
 * Desktop presentation and draft editor. Screen rendering never writes SQL directly:
 * all reads, authentication, revisions and process actions cross the explicit preload
 * bridge. See docs/DATABASE-CHANGES.md for schema-dependent fields.
 */
/* Renderer contains presentation and drafts only. Database validation, Manager
 * authorization, transactions and process ownership live in the main process. */
const $ = (selector) => document.querySelector(selector);
const api = window.editor;
let workspace,
  page = "overview",
  search = "",
  pending,
  editSubmit,
  entityList,
  entityType = "armory_type",
  polling = false;
let selectedProfile = "",
  filterGroup = "all";
let vehicleCategoryFilter = "all";
/**
 * Switch the connection tab without discarding its inputs. Keep ARIA selection and
 * keyboard focus in sync; hidden fields still participate in the final login payload.
 */
function connectionTab(name, focus = false) {
  for (const tab of document.querySelectorAll("[data-connect-tab]")) {
    const selected = tab.dataset.connectTab === name;
    tab.setAttribute("aria-selected", String(selected));
    tab.tabIndex = selected ? 0 : -1;
    $("#panel-" + tab.dataset.connectTab).hidden = !selected;
    if (selected && focus) tab.focus();
  }
  $("#connection-next").hidden = name !== "database";
  $("#connect-form button[type=submit]").hidden = name === "database";
}
document.querySelector(".connection-tabs").onclick = (event) => {
  const tab = event.target.closest("[data-connect-tab]");
  if (tab) connectionTab(tab.dataset.connectTab);
};
document.querySelector(".connection-tabs").onkeydown = (event) => {
  if (!["ArrowLeft", "ArrowRight", "Home", "End"].includes(event.key)) return;
  event.preventDefault();
  const tabs = [...document.querySelectorAll("[data-connect-tab]")],
    index = tabs.findIndex(
      (tab) => tab.getAttribute("aria-selected") === "true",
    );
  const next =
    event.key === "Home"
      ? 0
      : event.key === "End"
        ? tabs.length - 1
        : (index + (event.key === "ArrowRight" ? 1 : -1) + tabs.length) %
          tabs.length;
  connectionTab(tabs[next].dataset.connectTab, true);
};
$("#connection-next").onclick = () => {
  for (const input of $("#panel-database").querySelectorAll("input"))
    if (!input.checkValidity()) {
      input.reportValidity();
      return;
    }
  connectionTab("manager");
  $("#connect-form input[name=manager]").focus();
};
// Reveal the tab containing an invalid required field before browser validation
// focuses it. Fields stay enabled so hidden-panel values are submitted together.
$("#connect-form").addEventListener(
  "invalid",
  (event) => {
    const panel = event.target.closest("[role=tabpanel]");
    if (panel?.hidden) connectionTab(panel.id.replace("panel-", ""));
  },
  true,
);
connectionTab("database");
const titles = {
  overview: "Workspace overview",
  settings: "Server settings",
  locations: "World locations",
  models: "Vehicle catalogue",
  squads: "Faction squads",
  equipment: "Faction equipment",
  history: "Change history",
  server: "Local server",
};
/**
 * Escape dynamic database/user text before building HTML; do not interpolate raw
 * strings into cards or option labels.
 */
const escape = (value) =>
  String(value ?? "").replace(
    /[&<>"']/g,
    (char) =>
      ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[
        char
      ],
  );
/**
 * Create delegated-action buttons with escaped identifiers. render() can replace the
 * DOM without reattaching per-record handlers.
 */
const button = (label, action, id = "", style = "") =>
  `<button type="button" class="${style}" data-action="${action}" data-id="${escape(id)}">${escape(label)}</button>`;
/**
 * Render sanitized messages as plain text in an accessible status region.
 */
const note = (message, error = false) => {
  $("#notice").textContent = message;
  $("#notice").className = error ? "error" : "";
  $("#notice").hidden = false;
};
/**
 * Route expected async UI failures into the status notice. Main-process handlers supply
 * sanitized messages; do not log credential objects.
 */
async function run(operation) {
  try {
    return await operation();
  } catch (error) {
    note(error.message, true);
  }
}
/**
 * Refresh safe profile labels and optionally select the most recently used connection.
 * This operation does not decrypt passwords into the view.
 */
async function refreshProfiles(id = selectedProfile, auto = false) {
  const rows = await api.profilesList();
  $("#saved-connection").innerHTML =
    '<option value="">New connection</option>' +
    rows
      .map(
        (row) =>
          `<option value="${escape(row.id)}">${escape(row.label)}</option>`,
      )
      .join("");
  selectedProfile = rows.some((row) => row.id === id)
    ? id
    : auto
      ? rows.at(-1)?.id || ""
      : "";
  $("#saved-connection").value = selectedProfile;
  $("#forget-connection").hidden = !selectedProfile;
}
/**
 * Populate public connection fields and saved-password placeholders. Required flags
 * allow an empty input only when main can reuse a protected saved password.
 */
async function loadSelectedProfile(focus = true) {
  selectedProfile = $("#saved-connection").value;
  $("#forget-connection").hidden = !selectedProfile;
  const form = $("#connect-form");
  for (const input of form.querySelectorAll("input[type=password]")) {
    input.value = "";
    input.placeholder = "";
  }
  if (!selectedProfile) {
    form.reset();
    form.elements.managerPassword.required = true;
    connectionTab("database");
    return;
  }
  const value = await api.profilesLoad(selectedProfile);
  for (const key of ["host", "port", "database", "user", "manager"])
    form.elements[key].value = value[key];
  form.elements.tls.checked = value.tls;
  form.elements.rememberConnection.checked = true;
  form.elements.profileName.value =
    $("#saved-connection").selectedOptions[0].textContent;
  for (const [key, field] of Object.entries({
    host: "smtpHost",
    port: "smtpPort",
    user: "smtpUser",
    from: "smtpFrom",
  }))
    form.elements[field].value = value.smtp[key];
  form.elements.smtpSecure.checked = value.smtp.secure;
  if (value.hasPassword)
    form.elements.password.placeholder = "Saved password — leave empty to use";
  if (value.hasSmtpPassword)
    form.elements.smtpPassword.placeholder =
      "Saved password — leave empty to use";
  form.elements.managerPassword.required = !value.hasManagerPassword;
  if (value.hasManagerPassword)
    form.elements.managerPassword.placeholder =
      "Saved password — leave empty to use";
  connectionTab("manager");
  if (focus) form.elements.managerPassword.focus();
}
$("#saved-connection").onchange = () => void run(loadSelectedProfile);
$("#forget-connection").onclick = () =>
  void run(async () => {
    if (
      !selectedProfile ||
      !confirm("Forget this saved connection and its stored passwords?")
    )
      return;
    await api.profilesRemove(selectedProfile);
    selectedProfile = "";
    await refreshProfiles();
    $("#connect-form").reset();
    for (const input of $("#connect-form").querySelectorAll(
      "input[type=password]",
    )) {
      input.value = "";
      input.placeholder = "";
    }
    note("Saved connection removed.");
  });
void run(async () => {
  await refreshProfiles(undefined, true);
  if (selectedProfile) await loadSelectedProfile(false);
});
/**
 * Show the authenticated workspace after the main process has returned a valid
 * snapshot.
 */
function connected() {
  document.body.classList.add("connected");
  $("#connect-screen").hidden = true;
  $("#workspace").hidden = false;
  $("#refresh").hidden = false;
  $("#disconnect").hidden = false;
  $("#connection-label").textContent = workspace.name;
}
/**
 * Refresh the authoritative configuration revision before rebuilding the current
 * screen. Open modal drafts are not silently merged with newer database values.
 */
async function load() {
  workspace = await api.load();
  connected();
  await render();
}
/**
 * Open a valid session even if optional profile storage failed, then display any
 * profile warning separately from authentication success.
 */
async function finishLogin(result, message) {
  await load();
  try {
    await refreshProfiles(result.profileId);
  } catch (error) {
    note(
      "Connected, but saved connections could not be loaded: " + error.message,
      true,
    );
    return;
  }
  note(result.profileWarning || message, Boolean(result.profileWarning));
}
/**
 * Reset in-memory view state and clear password inputs. Logging out does not stop a
 * game process or delete a remembered profile.
 */
function disconnect() {
  workspace = undefined;
  entityList = undefined;
  pending = undefined;
  document.body.classList.remove("connected");
  $("#connect-screen").hidden = false;
  $("#workspace").hidden = true;
  $("#refresh").hidden = true;
  $("#disconnect").hidden = true;
  $("#connection-label").textContent = "Not connected";
  $("#revision").textContent = "Offline";
  $("#code-form").hidden = true;
  $("#connect-form").hidden = false;
  for (const input of document.querySelectorAll("input[type=password]"))
    input.value = "";
}
/**
 * Validate across tabs, then send credentials through the narrow preload API. Clear
 * typed password inputs immediately after successful authentication.
 */
$("#connect-form").addEventListener("submit", (event) => {
  event.preventDefault();
  const invalid = event.currentTarget.querySelector(
    "input:invalid,select:invalid",
  );
  if (invalid) {
    const panel = invalid.closest("[role=tabpanel]");
    if (panel) connectionTab(panel.id.replace("panel-", ""));
    invalid.reportValidity();
    return;
  }
  void run(async () => {
    const form = event.currentTarget,
      data = new FormData(form),
      submit = form.querySelector("button[type=submit]");
    submit.disabled = true;
    try {
      const result = await api.login({
        ...Object.fromEntries(data),
        profileId: selectedProfile,
        rememberConnection: data.has("rememberConnection"),
        tls: data.has("tls"),
        smtp: {
          host: data.get("smtpHost"),
          port: Number(data.get("smtpPort")),
          user: data.get("smtpUser"),
          password: data.get("smtpPassword"),
          from: data.get("smtpFrom"),
          secure: data.has("smtpSecure"),
        },
      });
      for (const input of form.querySelectorAll("input[type=password]"))
        input.value = "";
      if (result.challenge) {
        form.hidden = true;
        $("#code-form").hidden = false;
        $("#code-form input").focus();
      } else {
        await finishLogin(
          result,
          "Connected. Changes are validated and recorded in configuration history.",
        );
      }
    } finally {
      submit.disabled = false;
    }
  });
});
/**
 * Complete an email challenge without saving its code; remembered profiles are
 * finalized only after verification succeeds.
 */
$("#code-form").addEventListener("submit", (event) => {
  event.preventDefault();
  const code = event.currentTarget.elements.code.value;
  event.currentTarget.reset();
  void run(async () => {
    const result = await api.verify(code);
    await finishLogin(result, "Email verified. Workspace opened.");
  });
});
$("#disconnect").onclick = () =>
  void run(async () => {
    await api.logout();
    disconnect();
    note(
      "Disconnected. A server already launched by this editor remains owned by it; sign in again to manage it, or close the app to request a stop.",
    );
  });
$("#refresh").onclick = () =>
  void run(async () => {
    await load();
    note("Loaded the latest database revision.");
  });
/**
 * Reset section filters when navigating. Each screen can keep its own display logic
 * inside render() without sharing a stale entity list.
 */
document.querySelector("nav").onclick = (event) => {
  const target = event.target.closest("[data-page]");
  if (!target) return;
  page = target.dataset.page;
  search = "";
  filterGroup = "all";
  entityList = undefined;
  $("#notice").hidden = true;
  void run(render);
};

/**
 * Translate saved/applied revisions, heartbeat freshness and validation errors into a
 * short operator status.
 */
function statusText(state) {
  if (state.last_error) return "Server rejected a change";
  const heartbeat = Number(state.last_heartbeat),
    live = heartbeat > Date.now() / 1000 - 20;
  if (!live) return "No recent game heartbeat";
  return Number(state.applied_revision) >= Number(state.revision)
    ? "Changes applied"
    : "Waiting for server";
}
/**
 * Build the section search/filter toolbar. All user-entered search text is escaped
 * before HTML interpolation.
 */
function searchBar(extra = "") {
  return `<div class="toolbar"><input id="search" aria-label="Search current section" placeholder="Search this section…" value="${escape(search)}">${extra}</div>`;
}
/**
 * Apply the current local search term to readable names and persistent IDs without
 * issuing SQL on each keystroke.
 */
const matches = (...values) =>
  values.join(" ").toLowerCase().includes(search.toLowerCase());
/**
 * Resolve current SQL faction names while retaining the persistent ID; unknown/deleted
 * references remain recognizable instead of receiving a guessed name.
 */
function factionLabel(id) {
  const faction = workspace.factions.find((row) => row.id === Number(id));
  return faction
    ? `${faction.abbreviation && faction.abbreviation !== "Null" ? faction.abbreviation + " · " : ""}${faction.name} (ID ${id})`
    : `Faction ID ${id}`;
}
/**
 * Custom gun indices differ from GTA weapon IDs; use the shared custom catalogue and
 * retain the stored index in brackets.
 */
const weaponLabel = (id) =>
  `${workspace.weaponNames[id] || "Unknown weapon"} (${id})`;
/**
 * Use the canonical dealership classification, keeping unlisted special/service models
 * in Other stock instead of guessing.
 */
const vehicleCategory = (id) =>
  workspace.vehicleCategories[id] || "Other stock";
const groupNames = {
  economy: "Economy & firms",
  services: "Public services",
  vehicles: "Vehicles & transport",
  medical: "Medical care",
  jobs: "Jobs & deliveries",
  properties: "Properties & businesses",
  environment: "Time & weather",
  service: "Service points",
  spawn: "Player spawns",
  prison_cell: "Prison cells",
  garbage: "Garbage routes",
  fishing: "Fishing areas",
  garage: "Garages",
  gym_machine: "Gym equipment",
  gps: "GPS destinations",
};
const roleNames = [
  "Standard squad",
  "Tactical unit",
  "Detective unit",
  "Tactical & detective",
];
const roleHelp = [
  "General duties and day-to-day operations.",
  "Enables tactical squad capabilities.",
  "Enables detective squad capabilities.",
  "Enables both tactical and detective capabilities.",
];
/**
 * Turn persistent category keys into readable section headings; keep an understandable
 * fallback for new catalogue groups.
 */
const groupTitle = (value) => groupNames[value] || value.replaceAll("_", " ");
/**
 * Separate compact status/capability hints from the primary record label.
 */
const badge = (label, enabled = true) =>
  `<span class="badge ${enabled ? "" : "off"}">${escape(label)}</span>`;
/**
 * Provide a short purpose statement per screen without repeating a long operator guide
 * on every card.
 */
const pageIntro = (title, description) =>
  `<div class="page-intro"><h2>${escape(title)}</h2><p>${escape(description)}</p></div>`;
/**
 * Build category options from loaded metadata so new configuration groups can appear
 * without a hardcoded control per setting.
 */
const groupFilter = (values) =>
  `<select id="group-filter" aria-label="Filter category"><option value="all">All categories</option>${[...new Set(values)].map((value) => `<option value="${escape(value)}" ${filterGroup === value ? "selected" : ""}>${escape(groupTitle(value))}</option>`).join("")}</select>`;
/**
 * Keep title, supporting data and actions in consistent regions across settings,
 * vehicles, locations and equipment.
 */
const card = (title, subtitle, body, controls, tag = "") =>
  `<article class="item-card"><div class="item-top"><div><h3>${escape(title)}</h3><span class="muted">${escape(subtitle)}</span></div>${tag}</div>${body}<div class="item-actions">${controls}</div></article>`;
const row = (title, detail, controls) =>
  `<div class="row"><div><div class="row-title">${escape(title)}</div><small>${escape(detail)}</small></div><div class="actions">${controls}</div></div>`;
/**
 * Render the active screen from the last loaded snapshot and local filters. Display
 * cards are read-only; writes require the separate edit → review → commit flow.
 */
async function render() {
  $("#page-title").textContent = titles[page];
  document
    .querySelectorAll("nav button")
    .forEach((node) =>
      node.classList.toggle("active", node.dataset.page === page),
    );
  if (!workspace) return;
  const config = workspace.configuration,
    state = config.state;
  $("#revision").textContent =
    `Revision ${state.revision} · ${statusText(state)}`;
  let html = "";
  if (page === "overview") {
    html = `<div class="stats"><div class="card stat"><span class="eyebrow">CONFIGURATION</span><div class="number">${state.revision}</div><span class="muted">Saved revision</span></div><div class="card stat"><span class="eyebrow">GAME SERVER</span><div class="number">${state.applied_revision}</div><span class="muted">${escape(statusText(state))}</span></div><div class="card stat"><span class="eyebrow">WORLD LOCATIONS</span><div class="number">${config.locations.filter((item) => item.enabled).length}<span class="muted"> / ${config.locations.length}</span></div><span class="muted">Enabled locations</span></div></div><div class="grid"><div class="card"><span class="eyebrow">START SHAPING YOUR WORLD</span><h2>Your next move</h2><p class="muted">Set up service coordinates, tune your economy and configure faction equipment. Review every change before it reaches the database.</p>${button("Configure world locations →", "go", "locations", "primary")}</div><div class="card"><span class="eyebrow">ONE CONFIGURATION SYSTEM</span><h2>Works with your ACP</h2><p class="muted">Desktop and ACP edits use the same revisions, validation and history. Concurrent changes require a refresh. Tools already available in-game stay in-game.</p>${button("View change history →", "go", "history")}</div></div><div class="card section-heading"><div><h3>Local open.mp controls</h3><span>Start a local installation and read its console without a web server or agent.</span></div>${button("Open server controls", "go", "server")}</div>`;
  } else if (page === "settings") {
    const entries = workspace.settings.filter(
      (item) =>
        matches(item.label, item.key, item.group) &&
        (filterGroup === "all" || item.group === filterGroup),
    );
    html =
      pageIntro(
        "Tune how your server works",
        "Adjust prices, services and gameplay values. Each change is checked before saving, with a preview of exactly what will change.",
      ) + searchBar(groupFilter(workspace.settings.map((item) => item.group)));
    for (const group of [...new Set(entries.map((item) => item.group))])
      html +=
        `<div class="section-heading"><h3>${escape(groupTitle(group))}</h3><span>${entries.filter((item) => item.group === group).length} settings</span></div><div class="card-grid">` +
        entries
          .filter((item) => item.group === group)
          .map((item) =>
            card(
              item.label,
              "",
              `<div class="setting-value">${escape(config.settings[item.key])}</div><p class="card-help">${item.type === "text" ? `Up to ${item.maxLength} characters` : `Allowed range: ${item.min.toLocaleString()}–${item.max.toLocaleString()}`}</p>`,
              button("Adjust setting", "setting", item.key),
              badge(
                item.policy === "new-job"
                  ? "New jobs"
                  : item.policy === "reschedule"
                    ? "Updates timer"
                    : "Live",
              ),
            ),
          )
          .join("") +
        "</div>";
  } else if (page === "locations") {
    html =
      pageIntro(
        "Place the essentials",
        "Set where players find services, spawn and interact with your world. Disabled points remain unavailable until you place and enable them.",
      ) +
      searchBar(
        groupFilter(config.locations.map((item) => item.category)) +
          button("Add location", "add-location", "", "primary"),
      ) +
      '<div class="card-grid">' +
      config.locations
        .filter(
          (item) =>
            matches(item.label, item.key, item.category) &&
            (filterGroup === "all" || item.category === filterGroup),
        )
        .map((item) =>
          card(
            item.label,
            groupTitle(item.category),
            `<dl class="coordinate-grid">${["x", "y", "z"].map((key) => `<div><dt>${key.toUpperCase()}</dt><dd>${Number(item[key]).toFixed(2)}</dd></div>`).join("")}</dl><div class="card-meta">${badge("Interior " + item.interior, false)}${badge("World " + item.world, false)}${item.gpsEnabled ? badge("GPS visible") : ""}</div>`,
            button("Edit location", "location", item.key) +
              (workspace.coreLocations.includes(item.key)
                ? ""
                : button("Remove", "remove-location", item.key)),
            badge(item.enabled ? "Enabled" : "Disabled", item.enabled),
          ),
        )
        .join("") +
      "</div>";
  } else if (page === "models") {
    const filters = {
      all: "All vehicles",
      cargo: "Cargo vehicles",
      priced: "Priced vehicles",
      disabled: "Disabled vehicles",
    };
    const categories = [
      "Budget",
      "Muscle",
      "Sports",
      "Utility",
      "Bikes",
      "Aircraft",
      "Boats",
      "Ships",
      "Other stock",
    ];
    const entries = config.models.filter(
      (item) =>
        matches(
          item.modelId,
          workspace.vehicleNames[item.modelId - 400],
          vehicleCategory(item.modelId),
        ) &&
        (vehicleCategoryFilter === "all" ||
          vehicleCategory(item.modelId) === vehicleCategoryFilter) &&
        (filterGroup === "all" ||
          (filterGroup === "cargo" && item.cargoSlots > 0) ||
          (filterGroup === "priced" && item.price !== null) ||
          (filterGroup === "disabled" && !item.enabled)),
    );
    html =
      pageIntro(
        "Build your vehicle lineup",
        "Browse dealership categories, tune prices and set cargo capacity. Other stock contains models outside the dealership catalogue.",
      ) +
      searchBar(
        `<select id="vehicle-category" aria-label="Vehicle category"><option value="all">All categories</option>${categories.map((label) => `<option ${vehicleCategoryFilter === label ? "selected" : ""}>${label}</option>`).join("")}</select><select id="group-filter" aria-label="Filter vehicles">${Object.entries(
          filters,
        )
          .map(
            ([key, label]) =>
              `<option value="${key}" ${filterGroup === key ? "selected" : ""}>${label}</option>`,
          )
          .join("")}</select>` +
          button("Add vehicle model", "add-model", "", "primary"),
      );
    for (const category of categories) {
      const models = entries.filter(
        (row) => vehicleCategory(row.modelId) === category,
      );
      if (!models.length) continue;
      html +=
        `<div class="section-heading"><h3>${category}</h3><span>${models.length} models</span></div><div class="card-grid vehicle-grid">` +
        models
          .map((item) =>
            card(
              workspace.vehicleNames[item.modelId - 400] ||
                `Vehicle ${item.modelId}`,
              `${category} · Model ${item.modelId}`,
              `<dl class="metric-grid"><div><dt>Catalogue price</dt><dd>${item.price === null ? "Not priced" : "$" + item.price.toLocaleString()}</dd></div><div><dt>Cargo capacity</dt><dd>${item.cargoSlots} <small>slots</small></dd></div></dl>`,
              button("Configure", "model", item.modelId) +
                button("Remove", "remove-model", item.modelId),
              badge(item.enabled ? "Available" : "Disabled", item.enabled),
            ),
          )
          .join("") +
        "</div>";
    }
  } else if (page === "squads") {
    const entries = config.squads.filter((item) =>
      matches(item.name, item.id, factionLabel(item.factionId)),
    );
    html =
      pageIntro(
        "Give every team a purpose",
        "Organise factions into squads and choose which specialist capabilities each team can use.",
      ) + searchBar(button("Add squad", "add-squad", "", "primary"));
    for (const factionId of [...new Set(entries.map((item) => item.factionId))])
      html +=
        `<div class="faction-heading"><div class="faction-emblem">${escape(workspace.factions.find((row) => row.id === factionId)?.abbreviation || "F")}</div><div><h3>${escape(workspace.factions.find((row) => row.id === factionId)?.name || "Unknown faction")}</h3><span>Faction ID ${factionId} · ${entries.filter((item) => item.factionId === factionId).length} squads</span></div></div><div class="card-grid squad-grid">` +
        entries
          .filter((item) => item.factionId === factionId)
          .map(
            (item) =>
              card(
                item.name,
                `Squad ID ${item.id}`,
                `<p class="card-help">${roleHelp[item.roles]}</p>`,
                button("Edit squad", "squad", item.id) +
                  button("Remove", "remove-squad", item.id),
                badge(roleNames[item.roles], item.enabled),
              ) +
              `<span class="sr-only">${escape(factionLabel(factionId))}</span>`,
          )
          .join("") +
        "</div>";
    html +=
      '<p class="section-note">Before removing a squad, reassign its members and any equipment or uniforms that reference it.</p>';
  } else if (page === "equipment") {
    if (!entityList || entityList.type !== entityType)
      entityList = { type: entityType, ...(await api.entities(entityType)) };
    const definition = workspace.entityTypes[entityType];
    const help = {
      armory_type:
        "Create equipment groups for each faction, such as patrol and specialist loadouts.",
      locker:
        "Place faction lockers and choose which equipment group and squad can use them.",
      armory_weapon:
        "Choose weapons, ammunition and access restrictions for faction loadouts.",
      faction_skin:
        "Choose stock uniforms and the ranks, squads and equipment groups allowed to use them.",
    };
    html =
      pageIntro(
        "Equip your factions",
        "Organise loadouts, place lockers and control access to weapons and uniforms.",
      ) +
      `<div class="equipment-tabs">${Object.entries(workspace.entityTypes)
        .map(([key, value]) =>
          button(
            value.label,
            "equipment-tab",
            key,
            key === entityType ? "selected" : "",
          ),
        )
        .join(
          "",
        )}</div><div class="section-heading"><div><h3>${escape(definition.label)}</h3><p class="card-help">${escape(help[entityType])}</p></div>${button("Add record", "add-entity", "", "primary")}</div><div class="card-grid">` +
      entityList.rows
        .map((item) =>
          card(
            item.record.armory_name ||
              item.record.type_name ||
              (entityType === "faction_skin"
                ? "Uniform · skin " + item.record.faction_skin_skinid
                : entityType === "armory_weapon"
                  ? weaponLabel(item.record.weapon_id)
                  : "Record " + item.id),
            "Record ID " + item.id,
            `<dl class="detail-grid">${Object.entries(item.record)
              .slice(0, 4)
              .map(
                ([key, value]) =>
                  `<div><dt>${escape(definition.fields[key].label)}</dt><dd>${escape(["faction_id", "faction_skin_factionid"].includes(key) ? factionLabel(value) : key === "weapon_id" ? weaponLabel(value) : value)}</dd></div>`,
              )
              .join("")}</dl>`,
            button("Edit", "entity", item.id) +
              button("Delete", "remove-entity", item.id),
          ),
        )
        .join("") +
      (entityList.rows.length
        ? ""
        : '<div class="empty"><h3>Start with your first record</h3><p>' +
          escape(help[entityType]) +
          "</p></div>") +
      "</div>";
  } else if (page === "history") {
    html =
      pageIntro(
        "Know what changed",
        "Every saved change has an author and a revision. Review earlier configuration and restore it through the same validation as a normal save.",
      ) +
      '<div class="history-timeline">' +
      workspace.history
        .map(
          (item) =>
            `<article class="history-entry"><div class="revision-marker">${item.revision}</div><div class="history-body"><div class="card-meta">${badge(item.account_name, false)}${badge(item.source, false)}<time>${escape(new Date(item.created_at * 1000).toLocaleString())}</time></div><h3>${escape(item.description)}</h3>${item.restoreAvailable === false ? `<p class="card-help">${escape(item.restoreReason)}</p><span class="badge off">${escape(item.restoreLabel)}</span>` : button("Review restore", "restore", item.revision)}</div></article>`,
        )
        .join("") +
      (workspace.history.length
        ? ""
        : '<div class="empty"><h3>A fresh start</h3><p>Your first save will appear here with its author and revision.</p></div>') +
      '</div><p class="section-note">Restoring creates a new revision. Changes owned by in-game editors must be handled with those tools.</p>';
  } else if (page === "server") {
    const status = await api.serverStatus();
    html = `<div class="card"><div class="card-heading"><div><span class="eyebrow">LOCAL WINDOWS RUNTIME</span><h2>${status.running ? "Server running" : "Server stopped"}</h2></div><span class="badge ${status.running ? "" : "off"}">${status.running ? "PID " + status.pid : "Offline"}</span></div><p class="muted">${escape(status.directory || "Choose a folder containing omp-server.exe and config.json. This tool manages only the process it launches.")}</p><div class="actions">${button("Choose server folder", "select-server")}${button("Start server", "start-server", "", "primary")}${button("Stop server", "stop-server")}${button("Force stop…", "force-server", "", "danger")}</div></div><div class="section-heading"><h3>Console output</h3><span>Last 200,000 characters · updated every 5 seconds</span></div><pre class="console" id="server-log">${escape(status.log || "No console output yet.")}</pre>`;
  }
  $("#content").innerHTML = html;
  if (search && !$("#content").querySelector(".item-card,.row,.history-entry"))
    $("#content").insertAdjacentHTML(
      "beforeend",
      '<div class="empty"><h3>No matching results</h3><p>Try another name, ID or category.</p></div>',
    );
  $("#search")?.addEventListener("input", (event) => {
    search = event.target.value;
    const position = event.target.selectionStart;
    void run(async () => {
      await render();
      $("#search").focus();
      $("#search").setSelectionRange(position, position);
    });
  });
  $("#entity-type")?.addEventListener("change", (event) => {
    entityType = event.target.value;
    entityList = undefined;
    void run(render);
  });
  $("#group-filter")?.addEventListener("change", (event) => {
    filterGroup = event.target.value;
    void run(render);
  });
  $("#vehicle-category")?.addEventListener("change", (event) => {
    vehicleCategoryFilter = event.target.value;
    void run(render);
  });
}

// One small field builder serves typed settings, coordinates and equipment.
// Numeric bounds improve input hints; authoritative validation still runs in SQL's caller.
/**
 * Build a typed draft form from trusted metadata. Conditional fishing controls preserve
 * their draft while hidden but are excluded from non-fishing submission.
 */
function edit(title, fields, initial, submit) {
  $("#edit-title").textContent = title;
  editSubmit = submit;
  $("#edit-fields").innerHTML = fields
    .map((field) => {
      const value = initial[field.key] ?? "",
        key = escape(field.key),
        label = escape(field.label);
      if (field.faction)
        return `<label>${label}<select name="${key}" required>${workspace.factions.some((row) => row.id === Number(value)) ? "" : `<option value="${escape(value)}" selected>Unknown faction (ID ${escape(value)})</option>`}${workspace.factions.map((row) => `<option value="${row.id}" ${row.id === Number(value) ? "selected" : ""}>${escape(factionLabel(row.id))}</option>`).join("")}</select></label>`;
      if (field.weapon)
        return `<label>${label}<select name="${key}" required>${workspace.weaponNames[Number(value)] ? "" : `<option value="${escape(value)}" selected>Unknown weapon (${escape(value)})</option>`}${workspace.weaponNames
          .slice(1)
          .map(
            (_name, index) =>
              `<option value="${index + 1}" ${index + 1 === Number(value) ? "selected" : ""}>${escape(weaponLabel(index + 1))}</option>`,
          )
          .join("")}</select></label>`;
      if (field.choices)
        return `<label>${label}<select name="${key}">${field.choices.map((title, id) => `<option value="${id}" ${id === Number(value) ? "selected" : ""}>${escape(title)}</option>`).join("")}</select></label>`;
      if (field.options)
        return `<label>${label}<select name="${key}">${field.options.map((option) => `<option value="${escape(option)}" ${option === value ? "selected" : ""}>${escape(option)}</option>`).join("")}</select></label>`;
      if (field.boolean)
        return `<label class="check"><input type="checkbox" name="${key}" ${value ? "checked" : ""}>${label}</label>`;
      if (field.json)
        return `<label class="wide" data-field="${key}">${label}<textarea name="${key}">${escape(JSON.stringify(value, null, 2))}</textarea></label>`;
      return `<label>${label}<input name="${key}" type="${field.text ? "text" : "number"}" value="${escape(value)}" ${field.text ? "" : `step="${field.integer ? "1" : "any"}"`} ${field.min === undefined ? "" : `min="${field.min}"`} ${field.max === undefined ? "" : `max="${field.max}"`} ${field.maxLength ? `maxlength="${field.maxLength}"` : ""} ${field.optional ? "" : "required"}></label>`;
    })
    .join("");
  const category = () =>
    $("#edit-form").elements.namedItem("category")?.value ?? initial.category;
  const updateConditionalFields = () => {
    for (const field of fields.filter((field) => field.onlyCategory)) {
      const container = $("#edit-fields").querySelector(
          `[data-field="${field.key}"]`,
        ),
        visible = category() === field.onlyCategory;
      container.hidden = !visible;
      container.querySelector("textarea").disabled = !visible;
    }
  };
  $("#edit-form").onchange = updateConditionalFields;
  updateConditionalFields();
  $("#edit-form").onsubmit = (event) => {
    event.preventDefault();
    void run(async () => {
      const data = new FormData(event.currentTarget),
        values = {};
      for (const field of fields) {
        if (field.onlyCategory && category() !== field.onlyCategory) {
          values[field.key] = [];
          continue;
        }
        const value = data.get(field.key);
        values[field.key] = field.boolean
          ? data.has(field.key)
          : field.json
            ? JSON.parse(value)
            : field.text || field.options
              ? value
              : field.optional && value === ""
                ? null
                : Number(value);
      }
      await editSubmit(values);
      $("#edit-dialog").close();
    });
  };
  $("#edit-dialog").showModal();
}
/**
 * Stage a review with the original expected revision. Nothing is persisted until the
 * user presses the separate confirmation button.
 */
function review(patch, before, after, restoreRevision) {
  pending = {
    patch,
    restoreRevision,
    expectedRevision: workspace.configuration.state.revision,
  };
  $("#review-content").textContent = JSON.stringify({ before, after }, null, 2);
  $("#change-note").value = "";
  $("#review-dialog").showModal();
}
$("#cancel-edit").onclick = () => $("#edit-dialog").close();
$("#cancel-review").onclick = () => {
  pending = undefined;
  $("#review-dialog").close();
};
/**
 * Commit the reviewed patch or restore through main-process authorization. A conflict
 * leaves the review available for inspection rather than silently overwriting another
 * editor.
 */
$("#confirm-save").onclick = () =>
  void run(async () => {
    if (!pending) return;
    const submit = $("#confirm-save");
    submit.disabled = true;
    try {
      const result = pending.restoreRevision
        ? await api.restore(pending.restoreRevision, pending.expectedRevision)
        : await api.save({
            ...pending.patch,
            expectedRevision: pending.expectedRevision,
            description:
              $("#change-note").value ||
              "Updated configuration from desktop editor",
          });
      pending = undefined;
      $("#review-dialog").close();
      entityList = undefined;
      await load();
      note(
        result.changed
          ? `Saved revision ${result.revision}. Check the applied revision for game acknowledgement.`
          : "No configuration changes were needed.",
      );
    } finally {
      submit.disabled = false;
    }
  });

/**
 * Describe numeric form hints; the main/shared validator remains authoritative for
 * bounds and integer rules.
 */
const numeric = (key, label, min, max, integer = false, optional = false) => ({
  key,
  label,
  min,
  max,
  integer,
  optional,
});
/**
 * Describe a bounded text input while leaving persistence and markup/control-character
 * checks to shared validation.
 */
const text = (key, label, maxLength) => ({ key, label, text: true, maxLength });
/**
 * Delegate card actions because render() replaces the screen DOM. Convert record edits
 * into shared repository patches; never issue SQL from this view.
 */
$("#content").onclick = (event) => {
  const target = event.target.closest("[data-action]");
  if (!target) return;
  void run(async () => {
    const { action, id } = target.dataset,
      config = workspace.configuration;
    if (action === "go") {
      page = id;
      search = "";
      filterGroup = "all";
      await render();
    }
    if (action === "equipment-tab") {
      entityType = id;
      entityList = undefined;
      await render();
    }
    if (action === "setting") {
      const definition = workspace.settings.find((item) => item.key === id);
      edit(
        definition.label,
        [
          {
            ...definition,
            key: "value",
            text: definition.type === "text",
            integer: definition.type === "integer",
          },
        ],
        { value: config.settings[id] },
        (values) =>
          review(
            { settings: { [id]: values.value } },
            { [id]: config.settings[id] },
            { [id]: values.value },
          ),
      );
    }
    if (action === "location" || action === "add-location") {
      const old = config.locations.find((item) => item.key === id),
        item = old || {
          key: "new_location",
          category: "service",
          label: "New location",
          x: 0,
          y: 0,
          z: 0,
          angle: 0,
          interior: 0,
          world: 0,
          radius: 5,
          modelId: 0,
          sortOrder: 0,
          enabled: false,
          gpsEnabled: false,
          vertices: [],
        };
      edit(
        old ? "Edit " + old.label : "Add location",
        [
          ...(old ? [] : [text("key", "Unique key", 64)]),
          text("label", "Location name", 64),
          ...(old
            ? []
            : [
                {
                  key: "category",
                  label: "Category",
                  options: workspace.locationCategories,
                },
              ]),
          ...["x", "y", "z"].map((key) =>
            numeric(key, key.toUpperCase(), -20000, 20000),
          ),
          numeric("angle", "Facing angle", 0, 360),
          numeric("interior", "Interior", 0, 255, true),
          numeric("world", "Virtual world", 0, 2147483000, true),
          numeric("radius", "Interaction radius", 0.2, 1000),
          numeric("modelId", "Stock model ID", 0, 19999, true),
          numeric("sortOrder", "Sort order", -10000, 10000, true),
          { key: "enabled", label: "Enabled", boolean: true },
          { key: "gpsEnabled", label: "Show in GPS", boolean: true },
          {
            key: "vertices",
            label: "Fishing polygon vertices (JSON points)",
            json: true,
            onlyCategory: "fishing",
          },
        ],
        item,
        (values) => {
          const updated = { ...item, ...values };
          review(
            {
              locations: old
                ? config.locations.map((row) =>
                    row.key === old.key ? updated : row,
                  )
                : [...config.locations, updated],
            },
            old || null,
            updated,
          );
        },
      );
    }
    if (action === "model" || action === "add-model") {
      const old = config.models.find((item) => item.modelId === Number(id)),
        item = old || {
          modelId: 400,
          cargoSlots: 0,
          price: null,
          enabled: true,
        };
      edit(
        old
          ? workspace.vehicleNames[item.modelId - 400] +
              " (Model " +
              item.modelId +
              ")"
          : "Add vehicle model",
        [
          ...(old ? [] : [numeric("modelId", "Model ID", 400, 611, true)]),
          numeric("cargoSlots", "Cargo slots", 0, 64, true),
          numeric(
            "price",
            "Catalogue price (blank = none)",
            0,
            100000000,
            true,
            true,
          ),
          { key: "enabled", label: "Enabled", boolean: true },
        ],
        item,
        (values) => {
          const updated = { ...item, ...values };
          review(
            {
              models: old
                ? config.models.map((row) =>
                    row.modelId === item.modelId ? updated : row,
                  )
                : [...config.models, updated],
            },
            old || null,
            updated,
          );
        },
      );
    }
    if (action === "squad" || action === "add-squad") {
      const old = config.squads.find((item) => item.id === Number(id)),
        item = old || {
          id: 1,
          factionId: 1,
          name: "New squad",
          roles: 0,
          enabled: true,
        };
      edit(
        "Faction squad",
        [
          ...(old ? [] : [numeric("id", "Unique squad ID", 1, 127, true)]),
          { key: "factionId", label: "Faction", faction: true },
          text("name", "Squad name", 23),
          { key: "roles", label: "Squad capabilities", choices: roleNames },
          { key: "enabled", label: "Enabled", boolean: true },
        ],
        item,
        (values) => {
          const updated = { ...item, ...values };
          review(
            {
              squads: old
                ? config.squads.map((row) =>
                    row.id === item.id ? updated : row,
                  )
                : [...config.squads, updated],
            },
            old || null,
            updated,
          );
        },
      );
    }
    if (action === "remove-squad" || action === "remove-model") {
      const collection = action === "remove-squad" ? "squads" : "models",
        key = collection === "squads" ? "id" : "modelId";
      const old = config[collection].find((row) => row[key] === Number(id));
      review(
        {
          [collection]: config[collection].filter(
            (row) => row[key] !== Number(id),
          ),
        },
        old,
        null,
      );
    }
    if (action === "remove-location") {
      const old = config.locations.find((row) => row.key === id);
      review(
        { locations: config.locations.filter((row) => row.key !== id) },
        old,
        null,
      );
    }
    if (action === "entity" || action === "add-entity") {
      const old = entityList.rows.find((row) => row.id === Number(id)),
        definition = workspace.entityTypes[entityType],
        item =
          old?.record ||
          Object.fromEntries(
            Object.entries(definition.fields).map(([key, field]) => [
              key,
              field.default,
            ]),
          );
      edit(
        definition.label,
        Object.entries(definition.fields).map(([key, field]) => ({
          ...field,
          key,
          optional: field.allowEmpty,
          faction: key === "faction_id" || key === "faction_skin_factionid",
          weapon: entityType === "armory_weapon" && key === "weapon_id",
        })),
        item,
        (values) => {
          if (entityList.revision !== config.state.revision)
            throw new Error(
              "Configuration changed since this workspace was loaded. Refresh before editing equipment.",
            );
          review(
            {
              entities: [
                {
                  type: entityType,
                  id: old?.id || 0,
                  record: values,
                  expectedRecord: old?.record ?? null,
                },
              ],
            },
            old?.record ?? null,
            values,
          );
        },
      );
    }
    if (action === "remove-entity") {
      const old = entityList.rows.find((row) => row.id === Number(id));
      if (entityList.revision !== config.state.revision)
        throw new Error("Refresh before deleting equipment.");
      review(
        {
          entities: [
            {
              type: entityType,
              id: old.id,
              record: null,
              expectedRecord: old.record,
            },
          ],
        },
        old.record,
        null,
      );
    }
    if (action === "restore")
      review({}, config, await api.previewRestore(Number(id)), Number(id));
    if (action === "select-server") {
      await api.serverSelect();
      await render();
    }
    if (action === "start-server") {
      target.disabled = true;
      try {
        await api.serverStart();
        await render();
        note(
          "Server process launched. Check its console and game heartbeat before joining.",
        );
      } finally {
        target.disabled = false;
      }
    }
    if (action === "stop-server") {
      target.disabled = true;
      try {
        await api.serverStop(false);
        await render();
        note("Server stopped.");
      } finally {
        target.disabled = false;
      }
    }
    if (
      action === "force-server" &&
      confirm(
        "Force terminate only the server launched by this editor? Pending game data may not be flushed.",
      )
    ) {
      await api.serverStop(true);
      await render();
      note("Editor-owned server terminated.");
    }
  });
};

/**
 * Poll lightweight state without changing the snapshot used by an open draft. Keep one
 * request in flight and surface server-side apply errors.
 */
setInterval(() => {
  if (!workspace || polling) return;
  polling = true;
  void (async () => {
    try {
      const state = await api.status();
      $("#revision").textContent =
        `Saved ${state.revision} / applied ${state.applied_revision} · ${statusText(state)}`;
      if (state.last_error) note(state.last_error, true);
      if (
        page === "server" &&
        !$("#edit-dialog").open &&
        !$("#review-dialog").open
      ) {
        const status = await api.serverStatus();
        if ($("#server-log"))
          $("#server-log").textContent = status.log || "No console output yet.";
      }
    } catch (error) {
      note(error.message, true);
    } finally {
      polling = false;
    }
  })();
}, 5000);
