(function () {
  "use strict";

  var storageKeys = {
    browser_state: "weeknight-five.state.v1",
    browser_recipes: "weeknight-five.recipes.v1",
    browser_deals: "weeknight-five.deals.v1"
  };

  function sendSavedData() {
    var loadedCount = 0;
    Object.keys(storageKeys).forEach(function (inputId) {
      var saved = "";
      try {
        saved = window.localStorage.getItem(storageKeys[inputId]) || "";
        if (saved) loadedCount += 1;
      } catch (error) {
        saved = "";
      }
      window.Shiny.setInputValue(inputId, saved, { priority: "event" });
    });
    document.documentElement.setAttribute("data-weeknight-storage-loaded", String(loadedCount));
    window.Shiny.setInputValue("browser_storage_ready", Date.now(), { priority: "event" });
    window.setTimeout(function () {
      window.Shiny.setInputValue("browser_ui_ready", Date.now(), { priority: "event" });
    }, 750);
  }

  var savedDataSent = false;
  var sendAttempts = 0;

  function tryToSendSavedData() {
    if (savedDataSent) return;
    sendAttempts += 1;
    try {
      if (!window.Shiny || typeof window.Shiny.setInputValue !== "function") {
        throw new Error("Shiny input connection is not ready yet.");
      }
      sendSavedData();
      savedDataSent = true;
    } catch (error) {
      if (sendAttempts < 80) window.setTimeout(tryToSendSavedData, 250);
    }
  }

  document.addEventListener("shiny:connected", function () {
    window.setTimeout(tryToSendSavedData, 500);
  });

  // Shinylive can attach the app UI after the connection event has fired.
  // Retry briefly until the input channel is ready, then restore only once.
  window.setTimeout(tryToSendSavedData, 1000);

  window.Shiny.addCustomMessageHandler("weeknight-five-save", function (message) {
    if (!message || !message.key || typeof message.value !== "string") return;
    try {
      window.localStorage.setItem(message.key, message.value);
      document.documentElement.setAttribute("data-weeknight-storage-saved", message.key);
    } catch (error) {
      window.Shiny.setInputValue("browser_storage_error", Date.now(), { priority: "event" });
    }
  });

  window.Shiny.addCustomMessageHandler("weeknight-five-storage-status", function (message) {
    document.documentElement.setAttribute("data-weeknight-storage-r", String(message || "unknown"));
  });
})();
