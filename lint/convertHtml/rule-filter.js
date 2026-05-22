/*
 * rule-filter.js - filters and displays details after selecting a specific rule
 *
 * Copyright (c) 2026 JEDLSoft
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

document.addEventListener("DOMContentLoaded", function () {
  const ruleChecks = document.querySelectorAll(".rule-check");
  const categoryChecks = document.querySelectorAll(".category-check");
  const detailCards = document.querySelectorAll("#detail-section .detail-card");
  const selectAllBtn = document.getElementById("select-all");
  const unselectAllBtn = document.getElementById("unselect-all");
  const catSelectAllBtn = document.getElementById("cat-select-all");
  const catUnselectAllBtn = document.getElementById("cat-unselect-all");

  ruleChecks.forEach(c => c.checked = true);
  categoryChecks.forEach(c => c.checked = true);

  ruleChecks.forEach(chk => chk.addEventListener("change", filterDetails));
  categoryChecks.forEach(chk => chk.addEventListener("change", filterDetails));

  if (selectAllBtn) {
    selectAllBtn.addEventListener("click", () => {
      ruleChecks.forEach(c => c.checked = true);
      filterDetails();
    });
  }
  if (unselectAllBtn) {
    unselectAllBtn.addEventListener("click", () => {
      ruleChecks.forEach(c => c.checked = false);
      filterDetails();
    });
  }
  if (catSelectAllBtn) {
    catSelectAllBtn.addEventListener("click", () => {
      categoryChecks.forEach(c => c.checked = true);
      filterDetails();
    });
  }
  if (catUnselectAllBtn) {
    catUnselectAllBtn.addEventListener("click", () => {
      categoryChecks.forEach(c => c.checked = false);
      filterDetails();
    });
  }

  function filterDetails() {
    const selectedRules = new Set(
      [...document.querySelectorAll(".rule-check:checked")].map(c => c.value)
    );
    const selectedCategories = new Set(
      [...document.querySelectorAll(".category-check:checked")].map(c => c.value)
    );
    const hasCategories = categoryChecks.length > 0;

    detailCards.forEach(card => {
      const ruleMatch = selectedRules.has(card.dataset.rule);
      const category = card.dataset.category;
      const categoryMatch = !hasCategories || !category || selectedCategories.has(category);
      card.style.display = (ruleMatch && categoryMatch) ? "" : "none";
    });
  }

  filterDetails();
});
