/*
 * rule-filter.js - filters and displays details after selecting a specific rule
 *
 * Copyright (c) 2025 JEDLSoft
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
  const detailTables = document.querySelectorAll("#detail-section table");
  const selectAllBtn = document.getElementById("select-all");
  const unselectAllBtn = document.getElementById("unselect-all");

  // Default: check all rules → show all details
  ruleChecks.forEach(c => c.checked = true);

  // Update visible tables when checkboxes change
  ruleChecks.forEach(chk => chk.addEventListener("change", filterDetails));

  // Select all rules
  selectAllBtn.addEventListener("click", () => {
    ruleChecks.forEach(c => c.checked = true);
    filterDetails();
  });

  // Deselect all rules
  unselectAllBtn.addEventListener("click", () => {
    ruleChecks.forEach(c => c.checked = false);
    filterDetails();
  });

  // Show only tables that match selected rules
  function filterDetails() {
    const selected = [...document.querySelectorAll(".rule-check:checked")]
      .map(c => c.value);

    if (selected.length === 0) {
      detailTables.forEach(t => (t.style.display = "none"));
      return;
    }

    detailTables.forEach(table => {
      const ruleCell = [...table.querySelectorAll("tr")].find(
        tr => tr.firstElementChild && tr.firstElementChild.textContent.trim() === "rule"
      );

      if (!ruleCell) {
        table.style.display = "none";
        return;
      }

      const ruleValue = ruleCell.children[1].textContent.trim();

      if (selected.includes(ruleValue)) {
        table.style.display = "";
        [...table.querySelectorAll("tr")].forEach(tr => tr.style.display = "");
      } else {
        table.style.display = "none";
      }
    });
  }

  // Initial display: show all tables
  filterDetails();
});
