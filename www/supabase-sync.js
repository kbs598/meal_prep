(function () {
  "use strict";

  var config = window.WEEKnightFiveSupabaseConfig || {};
  var client = null;
  var currentSession = null;
  var currentFamily = null;
  var needsPassword = false;
  var cloudLoaded = false;
  var handlersRegistered = false;
  var initStarted = false;

  function shinyReady() {
    return window.Shiny && typeof window.Shiny.setInputValue === "function";
  }

  function sendInput(name, value) {
    if (!shinyReady()) return;
    window.Shiny.setInputValue(name, value, { priority: "event" });
  }

  function messageText(error, fallback) {
    if (error && error.message) return error.message;
    return fallback || "The cloud connection did not complete.";
  }

  function publicAppUrl() {
    try {
      var targetWindow = window.top || window;
      return targetWindow.location.origin + targetWindow.location.pathname;
    } catch (error) {
      return window.location.origin + window.location.pathname;
    }
  }

  function topLocationParts() {
    try {
      var targetWindow = window.top || window;
      return {
        target: targetWindow,
        hash: targetWindow.location.hash || "",
        search: targetWindow.location.search || ""
      };
    } catch (error) {
      return { target: window, hash: window.location.hash || "", search: window.location.search || "" };
    }
  }

  function clearAuthUrl(parts) {
    try {
      var clean = parts.target.location.origin + parts.target.location.pathname;
      parts.target.history.replaceState({}, parts.target.document.title, clean);
    } catch (error) {
      // A cleaned URL is convenient but not required for authentication to work.
    }
  }

  async function finishEmailRedirect() {
    var parts = topLocationParts();
    var hash = new URLSearchParams(parts.hash.replace(/^#/, ""));
    var query = new URLSearchParams(parts.search.replace(/^\?/, ""));
    var authType = hash.get("type") || query.get("type") || "";
    needsPassword = authType === "invite" || authType === "recovery";

    if (hash.get("access_token") && hash.get("refresh_token")) {
      var sessionResult = await client.auth.setSession({
        access_token: hash.get("access_token"),
        refresh_token: hash.get("refresh_token")
      });
      clearAuthUrl(parts);
      if (sessionResult.error) throw sessionResult.error;
      return;
    }

    if (query.get("code")) {
      var exchangeResult = await client.auth.exchangeCodeForSession(query.get("code"));
      clearAuthUrl(parts);
      if (exchangeResult.error) throw exchangeResult.error;
    }
  }

  function authPayload(status, message) {
    var user = currentSession && currentSession.user;
    return {
      status: status,
      configured: true,
      email: user && user.email ? user.email : "",
      user_id: user && user.id ? user.id : "",
      family_id: currentFamily && currentFamily.family_id ? currentFamily.family_id : "",
      role: currentFamily && currentFamily.role ? currentFamily.role : "",
      needs_password: needsPassword,
      message: message || ""
    };
  }

  async function findFamily() {
    currentFamily = null;
    if (!currentSession || !currentSession.user) return null;
    var result = await client
      .from("family_members")
      .select("family_id, role")
      .eq("user_id", currentSession.user.id)
      .maybeSingle();
    if (result.error) throw result.error;
    currentFamily = result.data || null;
    return currentFamily;
  }

  async function seedPersonalDataIfNeeded(row) {
    if (!currentSession || !currentSession.user) return;
    var userId = currentSession.user.id;
    var stateKey = "weeknight-five.state.v1";
    var dealsKey = "weeknight-five.deals.v1";
    var localState = window.localStorage.getItem(stateKey) || "";
    var localDeals = window.localStorage.getItem(dealsKey) || "";
    var values = { user_id: userId, updated_at: new Date().toISOString() };
    var shouldSeed = false;

    if ((!row || !row.state_payload) && localState) {
      values.state_payload = localState;
      shouldSeed = true;
    }
    if ((!row || !row.deals_payload) && localDeals) {
      values.deals_payload = localDeals;
      shouldSeed = true;
    }
    if (shouldSeed) {
      var result = await client.from("user_app_data").upsert(values, { onConflict: "user_id" });
      if (result.error) throw result.error;
    }
  }

  async function loadCloudData() {
    if (!currentSession || !currentSession.user) return;
    cloudLoaded = false;
    sendInput("supabase_notice", { kind: "working", message: "Syncing your meal planner...", at: Date.now() });

    var personal = await client
      .from("user_app_data")
      .select("state_payload, deals_payload")
      .eq("user_id", currentSession.user.id)
      .maybeSingle();
    if (personal.error) throw personal.error;

    await seedPersonalDataIfNeeded(personal.data);
    if (personal.data && personal.data.state_payload) {
      sendInput("supabase_state", personal.data.state_payload);
    }
    if (personal.data && personal.data.deals_payload) {
      sendInput("supabase_deals", personal.data.deals_payload);
    }

    if (!currentFamily || !currentFamily.family_id) {
      cloudLoaded = true;
      sendInput("supabase_recipe_sync", { payloads: [], recipes_empty: false, no_family: true, at: Date.now() });
      sendInput("supabase_notice", {
        kind: "warning",
        message: "You are signed in, but this account has not been added to a family yet.",
        at: Date.now()
      });
      return;
    }

    var recipes = await client
      .from("family_recipes")
      .select("recipe_id, recipe_payload")
      .eq("family_id", currentFamily.family_id)
      .order("created_at", { ascending: true });
    if (recipes.error) throw recipes.error;
    var payloads = (recipes.data || []).map(function (row) { return row.recipe_payload; });
    sendInput("supabase_recipe_sync", {
      payloads: payloads,
      recipes_empty: payloads.length === 0,
      no_family: false,
      at: Date.now()
    });
    cloudLoaded = true;
    sendInput("supabase_notice", { kind: "success", message: "Cloud sync is up to date.", at: Date.now() });
  }

  async function refreshSession(eventName) {
    var sessionResult = await client.auth.getSession();
    if (sessionResult.error) throw sessionResult.error;
    currentSession = sessionResult.data.session;
    if (!currentSession) {
      currentFamily = null;
      cloudLoaded = false;
      sendInput("supabase_auth", authPayload("signed_out", "Sign in to share recipes with your family."));
      return;
    }

    try {
      await findFamily();
      var message = currentFamily
        ? "Signed in and connected to the family collection."
        : "Signed in. This account still needs family access.";
      sendInput("supabase_auth", authPayload("signed_in", message));
      await loadCloudData();
    } catch (error) {
      sendInput("supabase_auth", authPayload("signed_in", messageText(error, "Signed in, but the database setup is not complete.")));
      sendInput("supabase_notice", { kind: "error", message: messageText(error), at: Date.now() });
    }
  }

  async function savePersonalValue(message) {
    if (!cloudLoaded || !currentSession || !currentSession.user || !message || !message.key) return;
    var update = { user_id: currentSession.user.id, updated_at: new Date().toISOString() };
    if (message.key === "weeknight-five.state.v1") update.state_payload = message.value;
    else if (message.key === "weeknight-five.deals.v1") update.deals_payload = message.value;
    else return;
    var result = await client.from("user_app_data").upsert(update, { onConflict: "user_id" });
    if (result.error) throw result.error;
  }

  async function saveRecipe(message) {
    if (!currentSession || !currentSession.user || !currentFamily || !message) return;
    var row = {
      family_id: currentFamily.family_id,
      recipe_id: String(message.recipe_id || ""),
      created_by: currentSession.user.id,
      recipe_name: String(message.recipe_name || "Family recipe"),
      meal_type: String(message.meal_type || "Dinner"),
      protein: String(message.protein || "Meatless"),
      recipe_payload: String(message.recipe_payload || ""),
      updated_at: new Date().toISOString()
    };
    if (!row.recipe_id || !row.recipe_payload) return;
    var result = await client
      .from("family_recipes")
      .upsert(row, { onConflict: "family_id,recipe_id" });
    if (result.error) throw result.error;
  }

  async function deleteRecipe(message) {
    if (!currentSession || !currentFamily || !message || !message.recipe_id) return;
    var result = await client
      .from("family_recipes")
      .delete()
      .eq("family_id", currentFamily.family_id)
      .eq("recipe_id", String(message.recipe_id));
    if (result.error) throw result.error;
  }

  function runAction(action, successMessage) {
    Promise.resolve()
      .then(action)
      .then(function () {
        if (successMessage) sendInput("supabase_notice", { kind: "success", message: successMessage, at: Date.now() });
      })
      .catch(function (error) {
        sendInput("supabase_notice", { kind: "error", message: messageText(error), at: Date.now() });
      });
  }

  function registerHandlers() {
    if (handlersRegistered || !window.Shiny || typeof window.Shiny.addCustomMessageHandler !== "function") return false;
    handlersRegistered = true;

    window.addEventListener("weeknight-five-local-save", function (event) {
      runAction(function () { return savePersonalValue(event.detail); });
    });

    window.Shiny.addCustomMessageHandler("weeknight-five-auth-sign-in", function (message) {
      runAction(async function () {
        var result = await client.auth.signInWithPassword({ email: message.email, password: message.password });
        if (result.error) throw result.error;
        await refreshSession("SIGNED_IN");
      });
    });

    window.Shiny.addCustomMessageHandler("weeknight-five-auth-sign-out", function (message) {
      runAction(async function () {
        var result = await client.auth.signOut();
        if (result.error) throw result.error;
        currentSession = null;
        currentFamily = null;
        cloudLoaded = false;
        needsPassword = false;
        sendInput("supabase_auth", authPayload("signed_out", "Signed out. This browser still has its local backup."));
      });
    });

    window.Shiny.addCustomMessageHandler("weeknight-five-auth-reset", function (message) {
      runAction(async function () {
        var result = await client.auth.resetPasswordForEmail(message.email, { redirectTo: publicAppUrl() });
        if (result.error) throw result.error;
      }, "Password email sent. Check your inbox and spam folder.");
    });

    window.Shiny.addCustomMessageHandler("weeknight-five-auth-set-password", function (message) {
      runAction(async function () {
        var result = await client.auth.updateUser({ password: message.password });
        if (result.error) throw result.error;
        needsPassword = false;
        await refreshSession("USER_UPDATED");
      }, "Your password is set.");
    });

    window.Shiny.addCustomMessageHandler("weeknight-five-supabase-sync", function (message) {
      runAction(loadCloudData, "Cloud sync finished.");
    });

    window.Shiny.addCustomMessageHandler("weeknight-five-supabase-save-recipe", function (message) {
      runAction(function () { return saveRecipe(message); }, "Recipe saved to the family collection.");
    });

    window.Shiny.addCustomMessageHandler("weeknight-five-supabase-delete-recipe", function (message) {
      runAction(function () { return deleteRecipe(message); }, "Recipe removed from the family collection.");
    });
    return true;
  }

  async function initialize() {
    if (initStarted) return;
    if (!registerHandlers()) {
      window.setTimeout(initialize, 250);
      return;
    }
    initStarted = true;

    if (!config.url || !config.publishableKey || !window.supabase || typeof window.supabase.createClient !== "function") {
      sendInput("supabase_auth", {
        status: "unavailable", configured: false, email: "", user_id: "", family_id: "", role: "",
        needs_password: false, message: "Cloud sharing is not configured. Browser backup is still working."
      });
      return;
    }

    client = window.supabase.createClient(config.url, config.publishableKey, {
      auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: false }
    });

    try {
      await finishEmailRedirect();
      await refreshSession("INITIAL_SESSION");
    } catch (error) {
      sendInput("supabase_auth", authPayload("error", messageText(error)));
    }

    client.auth.onAuthStateChange(function (event, session) {
      currentSession = session;
      if (event === "PASSWORD_RECOVERY") needsPassword = true;
      window.setTimeout(function () {
        refreshSession(event).catch(function (error) {
          sendInput("supabase_notice", { kind: "error", message: messageText(error), at: Date.now() });
        });
      }, 0);
    });
  }

  document.addEventListener("shiny:connected", function () { window.setTimeout(initialize, 250); });
  window.setTimeout(initialize, 750);
})();
