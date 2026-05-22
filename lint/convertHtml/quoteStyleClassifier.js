/*
 * quoteStyleClassifier.js - classification logic for resource-quote-style rule violations
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

const QUOTE_STYLE_CATEGORIES = {
    missing_quotes:  'Quotes present in source but missing in target',
    wrong_style:     'Wrong quote characters used for the locale',
    optional_quotes: 'Wrong style or quotes should be removed entirely',
};

const QUOTE_STYLE_MANUAL_CATEGORIES = new Set([]);

function classifyQuoteStyle(description) {
    if (description.startsWith('Quotes are missing')) return 'missing_quotes';
    if (description.includes('or there should be no quotes')) return 'optional_quotes';
    return 'wrong_style';
}

function countQuoteSubcategories(details) {
    const result = {};
    for (const item of details) {
        if (item.ruleName === 'resource-quote-style') {
            const cat = classifyQuoteStyle(item.description);
            if (!result['resource-quote-style']) result['resource-quote-style'] = {};
            result['resource-quote-style'][cat] = (result['resource-quote-style'][cat] || 0) + 1;
        }
    }
    return result;
}

export { QUOTE_STYLE_CATEGORIES, QUOTE_STYLE_MANUAL_CATEGORIES, classifyQuoteStyle, countQuoteSubcategories };
