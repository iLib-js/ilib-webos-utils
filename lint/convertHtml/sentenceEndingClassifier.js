/*
 * sentenceEndingClassifier.js - classification logic for resource-sentence-ending rule violations
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

const SENTENCE_ENDING_CATEGORIES = {
    extra_punctuation:        'Unnecessary punctuation present where none expected',
    missing_punctuation:      'Required punctuation is missing',
    missing_punctuation_09F7: 'Required punctuation is missing but target ends with U+09F7 (৷)',
    ellipsis_mismatch:        'Ellipsis character mismatch ("..." vs "…")',
    locale_specific:          'Locale-specific punctuation not used (।, ።, ۔, ፧)',
    fullwidth_halfwidth:      'Fullwidth/halfwidth punctuation mismatch',
    space_before_punct:       'Wrong space type before punctuation (U+202F vs U+00A0)',
    non_sentence_period:          'Source ends with abbreviation (Inc., Corp., Ltd., etc.) — not sentence punctuation',
    translation_style_change:     'Translation style changed (e.g., question → polite request ください。) — likely not an error',
    extra_punctuation_imperative:  'Source is imperative sentence — added punctuation may be acceptable',
    false_positive_question_mark:  'Locale uses script-native question mark (؟ U+061F) — correct usage',
    other:                        'Other punctuation substitution',
};

const LOCALE_SPECIFIC_CODEPOINTS = ['U+0964', 'U+1362', 'U+1367', 'U+06D4'];
const FULLWIDTH_CODEPOINTS = ['U+FF1F', 'U+FF01', 'U+3002', 'U+FF0E'];
const ABBREVIATION_PATTERN = /\b(Inc|Corp|Ltd|Co|Jr|Sr|Dr|Mr|Mrs|Ms|Prof|etc|vs)\.\s*$/;
const IMPERATIVE_VERBS = new Set(['Listen', 'Click', 'Press', 'Select', 'Choose', 'Enter',
    'Connect', 'Turn', 'Set', 'Check', 'Open', 'Close', 'Start', 'Stop', 'Use', 'Try',
    'Download', 'Install', 'Update', 'Remove', 'Delete', 'Add', 'Create', 'Go', 'Move',
    'Search', 'Find', 'View', 'Play', 'Record', 'Save', 'Allow', 'Enable', 'Disable',
    'Confirm', 'Cancel', 'Continue', 'Wait', 'Make', 'Keep', 'Place', 'Put', 'Adjust',
    'Change', 'Switch']);
const MANUAL_CATEGORIES = new Set(['missing_punctuation_09F7', 'non_sentence_period', 'translation_style_change', 'extra_punctuation_imperative', 'false_positive_question_mark']);

function classifySentenceEnding(description, highlight, source) {
    if (source && ABBREVIATION_PATTERN.test(source) && source.split(/\s+/).length <= 4) return 'non_sentence_period';

    const match = description.match(/^Sentence ending should be (.+?) for .+? locale instead of (.+)$/);
    if (!match) return 'other';
    const [, expected, actual] = match;

    if (expected === 'no punctuation') {
        const firstWord = source ? source.split(/\s/)[0] : '';
        if (IMPERATIVE_VERBS.has(firstWord)) return 'extra_punctuation_imperative';
        return 'extra_punctuation';
    }
    if (actual.includes('no punctuation')) {
        if (highlight && highlight.includes('৷')) return 'missing_punctuation_09F7';
        return 'missing_punctuation';
    }
    if (actual.includes('...') || expected.includes('…') || actual.includes('…')) return 'ellipsis_mismatch';
    if (LOCALE_SPECIFIC_CODEPOINTS.some(cp => expected.includes(cp) || actual.includes(cp))) return 'locale_specific';
    if (description.includes('U+FF1F') && description.includes('U+3002') && highlight && highlight.includes('ください')) return 'translation_style_change';
    if (FULLWIDTH_CODEPOINTS.some(cp => expected.includes(cp) || actual.includes(cp))) return 'fullwidth_halfwidth';
    if (expected.includes('U+202F') || expected.includes('U+00A0') || actual.includes('U+202F') || actual.includes('U+00A0')) return 'space_before_punct';
    if (expected.includes('U+003F') && actual.includes('U+061F')) return 'false_positive_question_mark';
    return 'other';
}

function countSubcategories(details) {
    const result = {};
    for (const item of details) {
        if (item.ruleName === 'resource-sentence-ending') {
            const cat = classifySentenceEnding(item.description, item.highlight, item.source);
            if (!result['resource-sentence-ending']) result['resource-sentence-ending'] = {};
            result['resource-sentence-ending'][cat] = (result['resource-sentence-ending'][cat] || 0) + 1;
        }
    }
    return result;
}

export { SENTENCE_ENDING_CATEGORIES, MANUAL_CATEGORIES, classifySentenceEnding, countSubcategories };
