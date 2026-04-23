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
  const detailCards = document.querySelectorAll("#detail-section .detail-card");
  const selectAllBtn = document.getElementById("select-all");
  const unselectAllBtn = document.getElementById("unselect-all");

  // Default: check all rules → show all details
  ruleChecks.forEach(c => c.checked = true);

  ruleChecks.forEach(chk => chk.addEventListener("change", filterDetails));

  selectAllBtn.addEventListener("click", () => {
    ruleChecks.forEach(c => c.checked = true);
    filterDetails();
  });

  unselectAllBtn.addEventListener("click", () => {
    ruleChecks.forEach(c => c.checked = false);
    filterDetails();
  });

  function filterDetails() {
    const selected = new Set(
      [...document.querySelectorAll(".rule-check:checked")].map(c => c.value)
    );

    detailCards.forEach(card => {
      card.style.display = selected.has(card.dataset.rule) ? "" : "none";
    });
  }

  filterDetails();
});
