/*
 * case-filter.js - filter out cases with no issues on the summary page
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
  const toggleNoIssues = document.getElementById("toggleNoIssues");
   // Toggle no-issues rows
  if (toggleNoIssues) {
    toggleNoIssues.addEventListener("change", function () {
      const noIssueRows = document.querySelectorAll("tr.no-issues");
      noIssueRows.forEach(row => {
        row.style.display = this.checked ? "none" : "";
      });
    });
  }
});
