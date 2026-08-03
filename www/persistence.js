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
      window.dispatchEvent(new CustomEvent("weeknight-five-local-save", { detail: message }));
    } catch (error) {
      window.Shiny.setInputValue("browser_storage_error", Date.now(), { priority: "event" });
    }
  });

  window.Shiny.addCustomMessageHandler("weeknight-five-storage-status", function (message) {
    document.documentElement.setAttribute("data-weeknight-storage-r", String(message || "unknown"));
  });

  function decodeHtml(value) {
    var textarea = document.createElement("textarea");
    textarea.innerHTML = String(value || "");
    return textarea.value.replace(/\s+/g, " ").trim();
  }

  function hasRecipeType(value) {
    var type = value && value["@type"];
    if (Array.isArray(type)) return type.indexOf("Recipe") !== -1;
    return type === "Recipe";
  }

  function findRecipeNode(value) {
    if (!value) return null;
    if (Array.isArray(value)) {
      for (var i = 0; i < value.length; i += 1) {
        var arrayMatch = findRecipeNode(value[i]);
        if (arrayMatch) return arrayMatch;
      }
      return null;
    }
    if (typeof value !== "object") return null;
    if (hasRecipeType(value)) return value;
    var preferredKeys = ["@graph", "mainEntity", "itemListElement", "subjectOf"];
    for (var j = 0; j < preferredKeys.length; j += 1) {
      if (value[preferredKeys[j]]) {
        var preferredMatch = findRecipeNode(value[preferredKeys[j]]);
        if (preferredMatch) return preferredMatch;
      }
    }
    return null;
  }

  function recipeFromDocument(doc) {
    var scripts = doc.querySelectorAll('script[type="application/ld+json"]');
    for (var i = 0; i < scripts.length; i += 1) {
      try {
        var parsed = JSON.parse(scripts[i].textContent.trim());
        var recipe = findRecipeNode(parsed);
        if (recipe) return recipe;
      } catch (error) {
        // A page may contain unrelated malformed JSON-LD; continue to the next block.
      }
    }

    var recipeRoot = doc.querySelector('[itemtype*="schema.org/Recipe"]');
    if (!recipeRoot) return null;
    var ingredientNodes = recipeRoot.querySelectorAll('[itemprop="recipeIngredient"], [itemprop="ingredients"]');
    var instructionNodes = recipeRoot.querySelectorAll('[itemprop="recipeInstructions"]');
    return {
      "@type": "Recipe",
      name: (recipeRoot.querySelector('[itemprop="name"]') || {}).textContent || doc.title,
      recipeIngredient: Array.prototype.map.call(ingredientNodes, function (node) { return node.textContent; }),
      recipeInstructions: Array.prototype.map.call(instructionNodes, function (node) { return node.textContent; })
    };
  }

  function durationMinutes(value) {
    if (!value) return 0;
    var match = String(value).match(/^P(?:(\d+(?:\.\d+)?)D)?(?:T(?:(\d+(?:\.\d+)?)H)?(?:(\d+(?:\.\d+)?)M)?)?$/i);
    if (!match) {
      var plain = String(value).match(/(\d+(?:\.\d+)?)/);
      return plain ? Math.round(Number(plain[1])) : 0;
    }
    return Math.round((Number(match[1] || 0) * 1440) + (Number(match[2] || 0) * 60) + Number(match[3] || 0));
  }

  function recipeServings(value) {
    if (Array.isArray(value)) value = value[0];
    if (value && typeof value === "object") value = value.value || value.name;
    var match = String(value || "").match(/\d+(?:\.\d+)?/);
    return match ? Math.max(1, Math.round(Number(match[0]))) : 4;
  }

  function nutrientNumber(value) {
    if (Array.isArray(value)) value = value[0];
    if (value && typeof value === "object") value = value.value || value.name;
    var match = String(value || "").replace(/,/g, "").match(/\d+(?:\.\d+)?/);
    return match ? Math.round(Number(match[0]) * 10) / 10 : null;
  }

  function flattenInstructions(value, output) {
    output = output || [];
    if (!value) return output;
    if (typeof value === "string") {
      var text = decodeHtml(value);
      if (text) output.push(text);
      return output;
    }
    if (Array.isArray(value)) {
      value.forEach(function (item) { flattenInstructions(item, output); });
      return output;
    }
    if (typeof value === "object") {
      if (value.itemListElement) return flattenInstructions(value.itemListElement, output);
      if (value.text) return flattenInstructions(value.text, output);
      if (value.name && hasRecipeType(value) === false) return flattenInstructions(value.name, output);
    }
    return output;
  }

  function fractionNumber(value) {
    var parts = String(value).trim().split(/\s+/);
    var total = 0;
    parts.forEach(function (part) {
      if (part.indexOf("/") !== -1) {
        var fraction = part.split("/");
        total += Number(fraction[0]) / Number(fraction[1]);
      } else {
        total += Number(part);
      }
    });
    return total;
  }

  function groceryCategory(name) {
    var text = name.toLowerCase();
    if (/\bfrozen\b/.test(text)) return "Frozen";
    if (/chicken|turkey|beef|steak|pork|ham|bacon|sausage|fish|salmon|tuna|cod|tilapia|trout|shrimp/.test(text)) return "Meat & Seafood";
    if (/egg|milk|cheese|butter|yogurt|cream|mozzarella|cheddar|parmesan/.test(text) && !/coconut milk/.test(text)) return "Dairy";
    if (/bread|bun|tortilla|roll|pita/.test(text)) return "Bakery";
    if (/onion|garlic|potato|carrot|broccoli|pepper|tomato|lettuce|spinach|kale|celery|mushroom|zucchini|squash|corn|avocado|lemon|lime|apple|berry|berries|banana|orange|parsley|cilantro|basil|rosemary|thyme|ginger|cabbage|cucumber|asparagus|pea\b|beans?\s+fresh/.test(text)) return "Produce";
    return "Pantry";
  }

  function parseIngredient(value) {
    var text = decodeHtml(typeof value === "object" ? (value.name || value.value || "") : value);
    var unicodeFractions = {"½":"1/2", "⅓":"1/3", "⅔":"2/3", "¼":"1/4", "¾":"3/4", "⅕":"1/5", "⅖":"2/5", "⅗":"3/5", "⅘":"4/5", "⅙":"1/6", "⅚":"5/6", "⅛":"1/8", "⅜":"3/8", "⅝":"5/8", "⅞":"7/8"};
    Object.keys(unicodeFractions).forEach(function (character) {
      text = text.replace(new RegExp(character, "g"), " " + unicodeFractions[character]);
    });
    text = text.replace(/^one\b/i, "1").replace(/^two\b/i, "2").replace(/^three\b/i, "3");

    var quantity = 1;
    var quantityMatch = text.match(/^\s*(\d+(?:\.\d+)?(?:\s+\d+\/\d+)?|\d+\/\d+)(?:\s*(?:-|–|to)\s*\d+(?:\.\d+)?(?:\s+\d+\/\d+)?)?\s*/i);
    if (quantityMatch) {
      quantity = fractionNumber(quantityMatch[1]);
      text = text.slice(quantityMatch[0].length).trim();
    }

    var packageSize = "";
    var sizeMatch = text.match(/^\(([^)]+)\)\s*/);
    if (sizeMatch) {
      packageSize = sizeMatch[1];
      text = text.slice(sizeMatch[0].length).trim();
    }

    var unit = "count";
    var units = [
      [/^(tablespoons?|tbsp\.?)(?:\s+of)?\s+/i, "tbsp"],
      [/^(teaspoons?|tsp\.?)(?:\s+of)?\s+/i, "tsp"],
      [/^(cups?)(?:\s+of)?\s+/i, "cup"],
      [/^(pounds?|lbs?\.?)(?:\s+of)?\s+/i, "lb"],
      [/^(ounces?|oz\.?)(?:\s+of)?\s+/i, "oz"],
      [/^(cans?)(?:\s+of)?\s+/i, "can"],
      [/^(packages?|pkgs?\.?)(?:\s+of)?\s+/i, "package"],
      [/^(bags?)(?:\s+of)?\s+/i, "bag"],
      [/^(slices?)(?:\s+of)?\s+/i, "slice"],
      [/^(cloves?)(?:\s+of)?\s+/i, "clove"],
      [/^(bunch(?:es)?)(?:\s+of)?\s+/i, "bunch"],
      [/^(heads?)(?:\s+of)?\s+/i, "head"],
      [/^(stalks?)(?:\s+of)?\s+/i, "stalk"]
    ];
    for (var i = 0; i < units.length; i += 1) {
      var unitMatch = text.match(units[i][0]);
      if (unitMatch) {
        unit = units[i][1];
        text = text.slice(unitMatch[0].length).trim();
        break;
      }
    }

    text = text.replace(/^of\s+/i, "").replace(/^[,;]\s*/, "").trim();
    if (packageSize) text += " (" + packageSize + ")";
    if (!text) text = decodeHtml(value);
    if (!Number.isFinite(quantity) || quantity <= 0) quantity = 1;
    return {quantity: quantity, unit: unit, ingredient: text, category: groceryCategory(text)};
  }

  function importResult(result) {
    result.requestId = Date.now();
    window.Shiny.setInputValue("recipe_import_result", result, {priority: "event"});
  }

  window.Shiny.addCustomMessageHandler("weeknight-five-import-recipe", async function (message) {
    try {
      var source = new URL(message && message.url ? message.url : "");
      if ((source.protocol !== "http:" && source.protocol !== "https:") || source.username || source.password) {
        throw new Error("Paste a normal public recipe webpage beginning with http:// or https://.");
      }

      var controller = new AbortController();
      var timeout = window.setTimeout(function () { controller.abort(); }, 40000);
      var response;
      try {
        response = await fetch("https://r.jina.ai/" + source.href, {
          method: "GET",
          headers: {"X-Respond-With": "html", "X-Timeout": "25", "X-Retain-Images": "none"},
          signal: controller.signal
        });
      } finally {
        window.clearTimeout(timeout);
      }
      if (!response.ok) {
        if (response.status === 429) throw new Error("The recipe reader is temporarily busy. Wait a minute and try again.");
        throw new Error("That website would not provide the recipe page. Try another recipe link or enter it manually.");
      }
      var html = await response.text();
      if (html.length > 3000000) throw new Error("That recipe page is too large to import safely.");
      var doc = new DOMParser().parseFromString(html, "text/html");
      var recipe = recipeFromDocument(doc);
      if (!recipe) throw new Error("No standard recipe details were found on that page. Try the page’s Print Recipe link, or enter it manually.");

      var ingredientValues = recipe.recipeIngredient || recipe.ingredients || [];
      if (!Array.isArray(ingredientValues)) ingredientValues = [ingredientValues];
      var ingredients = ingredientValues.map(parseIngredient).filter(function (item) { return item.ingredient; });
      var steps = flattenInstructions(recipe.recipeInstructions || recipe.instructions || []);
      var minutes = durationMinutes(recipe.totalTime);
      if (!minutes) minutes = durationMinutes(recipe.prepTime) + durationMinutes(recipe.cookTime);
      if (!minutes) minutes = 30;
      var nutrition = recipe.nutrition || {};
      var categoryText = Array.isArray(recipe.recipeCategory) ? recipe.recipeCategory.join(" ") : String(recipe.recipeCategory || "");
      var importedMealType = /breakfast|brunch/i.test(categoryText) ? "Breakfast" : (/lunch/i.test(categoryText) ? "Lunch" : "Dinner");

      importResult({
        ok: true,
        recipe: {
          name: decodeHtml(recipe.name || doc.title || "Imported recipe"),
          description: decodeHtml(recipe.description || "Imported family recipe"),
          meal_type: importedMealType,
          minutes: minutes,
          servings: recipeServings(recipe.recipeYield || recipe.yield),
          calories: nutrientNumber(nutrition.calories),
          protein_g: nutrientNumber(nutrition.proteinContent),
          fiber_g: nutrientNumber(nutrition.fiberContent),
          instructions: steps.map(function (step, index) { return (index + 1) + ". " + step; }).join("\n\n"),
          ingredients: ingredients,
          url: source.href
        }
      });
    } catch (error) {
      var messageText = error && error.name === "AbortError" ?
        "The recipe page took too long to respond. Please try again." :
        (error && error.message ? error.message : "That recipe could not be imported.");
      importResult({ok: false, message: messageText});
    }
  });

  var lastDirectPrintAt = 0;

  function printDocumentHtml(planMarkup) {
    return '<!doctype html>' +
      '<html><head><meta charset="utf-8">' +
      '<meta name="viewport" content="width=device-width, initial-scale=1">' +
      '<title>Weeknight Five - Weekly Meal Plan</title>' +
      '<style>' +
      '@page{size:landscape;margin:.38in}' +
      '*{box-sizing:border-box}' +
      'html,body{margin:0;background:#fff;color:#1e283a;font-family:Segoe UI,Arial,sans-serif}' +
      'body{padding:20px}' +
      '.print-toolbar{display:flex;align-items:center;justify-content:space-between;gap:12px;margin:0 auto 18px;max-width:1100px;padding:12px 14px;border-radius:12px;background:#f1f5ff;color:#3f4d67}' +
      '.print-toolbar button{border:0;border-radius:10px;padding:10px 18px;background:#6957db;color:#fff;font:700 15px Segoe UI,Arial,sans-serif;cursor:pointer}' +
      '.print-week-plan{display:block!important;max-width:1100px;margin:0 auto}' +
      '.print-week-plan h1{margin:0 0 4px;font-size:24px;line-height:1.2}' +
      '.print-subtitle{margin:0 0 13px;color:#536079;font-size:12px}' +
      '.print-plan-table{width:100%;border-collapse:collapse;table-layout:fixed}' +
      '.print-plan-table th,.print-plan-table td{border:1px solid #aeb6c5;padding:8px;text-align:left;vertical-align:top;font-size:11px;line-height:1.25}' +
      '.print-plan-table thead{display:table-header-group}' +
      '.print-plan-table thead th{background:#eaf0ff}' +
      '.print-plan-table tbody th{width:68px;background:#fff5cc}' +
      '.print-plan-table tr{break-inside:avoid;page-break-inside:avoid}' +
      '.print-plan-table strong,.print-plan-table small{display:block}' +
      '.print-plan-table small{margin-top:4px;color:#536079;font-size:9px;line-height:1.25}' +
      '.print-footer-note{margin-top:10px;color:#536079;font-size:9px}' +
      '@media print{body{padding:0}.print-toolbar{display:none!important}.print-week-plan{max-width:none}.print-plan-table thead th,.print-plan-table tbody th{-webkit-print-color-adjust:exact;print-color-adjust:exact}}' +
      '</style></head><body>' +
      '<div class="print-toolbar"><strong>Your fridge-ready week is ready.</strong><button id="print_again" type="button">Print this plan</button></div>' +
      planMarkup +
      '</body></html>';
  }

  function openWeeklyPrintView() {
    var output = document.getElementById("print_week_plan");
    var plan = output && output.querySelector(".print-week-plan");
    if (!plan) {
      window.Shiny.setInputValue("print_plan_error", Date.now(), { priority: "event" });
      return false;
    }

    var printWindow = window.open("", "_blank");
    if (!printWindow) {
      window.Shiny.setInputValue("print_popup_blocked", Date.now(), { priority: "event" });
      return false;
    }

    printWindow.document.open();
    printWindow.document.write(printDocumentHtml(plan.outerHTML));
    printWindow.document.close();
    var printAgain = printWindow.document.getElementById("print_again");
    if (printAgain) {
      printAgain.addEventListener("click", function () {
        printWindow.focus();
        printWindow.print();
      });
    }
    window.setTimeout(function () {
      printWindow.focus();
      printWindow.print();
    }, 350);
    return true;
  }

  // Opening the print tab directly from the button click keeps it compatible
  // with browser popup protection, including the Shinylive iframe on GitHub Pages.
  document.addEventListener("click", function (event) {
    var target = event.target && event.target.closest ? event.target.closest("#print_week") : null;
    if (!target) return;
    lastDirectPrintAt = Date.now();
    openWeeklyPrintView();
  }, true);

  window.Shiny.addCustomMessageHandler("weeknight-five-print", function (message) {
    if (Date.now() - lastDirectPrintAt < 15000) return;
    openWeeklyPrintView();
  });
})();
