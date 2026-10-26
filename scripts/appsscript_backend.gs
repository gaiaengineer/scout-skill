/**
 * Scout Skill — Google Sheets backend (Apps Script)
 *
 * Paste this code into the Google Apps Script editor attached to your Scout Authors sheet:
 *   Extensions -> Apps Script -> paste -> Save -> Deploy -> New deployment -> Web app
 *   Execute as: Me
 *   Who has access: Anyone (the SECRET below gates real access)
 *
 * Copy the resulting Web app URL into your config as $SHEETS_WEBAPP_URL.
 *
 * Auth model:
 *   Every request must include a "secret" field that matches SECRET below.
 *   Pick something long and random. Store it in $SHEETS_SECRET on each team member's machine.
 *
 * All operations expect POST with JSON body. Responses are JSON.
 *
 * Actions:
 *   append            — add a new row (body.data is the author object)
 *   update_by_email   — find row by email, update specified fields (body.email + body.data)
 *   read_all          — return every row as an array of author objects
 *   read_by_status    — return rows matching research_status and/or email_status
 *                       body.filter = { research_status?: string, email_status?: string }
 *   read_missing_data — return rows where ALL specified fields are empty
 *                       body.fields = ["instagram_followers", "goodreads_ratings", ...]
 *                       typically used with research_status in ["discovered_by_user", "discovered_by_skill"]
 */

// ============================================================
// CONFIGURATION
// ============================================================

// Change this to a long random string and share with the skill team. NEVER commit this value anywhere public.
const SECRET = 'REPLACE_ME_WITH_A_LONG_RANDOM_STRING';

// The sheet tab that stores author data. Default first tab name is "Sheet1".
const SHEET_NAME = 'Authors';

// The first row of the sheet must be a header row with column names matching the schema in workflows/research.md.
// Column order does not matter. Any column not in the header is silently ignored.
// Missing columns in the header are NOT created automatically — add them manually to the sheet first.


// ============================================================
// ENTRY POINT
// ============================================================

function doPost(e) {
  try {
    const body = JSON.parse(e.postData.contents);
    if (body.secret !== SECRET) {
      return jsonResponse({ ok: false, error: 'unauthorized' }, 401);
    }

    const sheet = SpreadsheetApp.getActive().getSheetByName(SHEET_NAME);
    if (!sheet) {
      return jsonResponse({ ok: false, error: 'sheet tab not found: ' + SHEET_NAME }, 500);
    }

    const headers = getHeaders(sheet);

    switch (body.action) {
      case 'append':
        return jsonResponse(append(sheet, headers, body.data || {}));
      case 'update_by_email':
        return jsonResponse(updateByEmail(sheet, headers, body.email, body.data || {}));
      case 'read_all':
        return jsonResponse(readAll(sheet, headers));
      case 'read_by_status':
        return jsonResponse(readByStatus(sheet, headers, body.filter || {}));
      case 'read_missing_data':
        return jsonResponse(readMissingData(sheet, headers, body.fields || [], body.filter || {}));
      default:
        return jsonResponse({ ok: false, error: 'unknown action: ' + body.action }, 400);
    }
  } catch (err) {
    return jsonResponse({ ok: false, error: String(err), stack: err.stack }, 500);
  }
}

// GET is used only for a cheap health check.
function doGet(e) {
  return jsonResponse({ ok: true, hint: 'POST with action + secret' });
}


// ============================================================
// ACTIONS
// ============================================================

function append(sheet, headers, data) {
  const row = buildRow(headers, data);
  sheet.appendRow(row);
  return { ok: true, action: 'append', wrote: row.length + ' columns' };
}

function updateByEmail(sheet, headers, email, data) {
  if (!email) return { ok: false, error: 'email is required' };
  const emailCol = headers.indexOf('email');
  if (emailCol === -1) return { ok: false, error: 'no email column in sheet' };

  const rows = sheet.getDataRange().getValues();
  for (let i = 1; i < rows.length; i++) {
    if (String(rows[i][emailCol]).toLowerCase() === String(email).toLowerCase()) {
      const rowNum = i + 1; // sheet is 1-indexed
      const updates = [];
      Object.keys(data).forEach(key => {
        const col = headers.indexOf(key);
        if (col !== -1) {
          sheet.getRange(rowNum, col + 1).setValue(data[key]);
          updates.push(key);
        }
      });
      return { ok: true, action: 'update_by_email', email: email, updated: updates };
    }
  }
  return { ok: false, error: 'row not found', email: email };
}

function readAll(sheet, headers) {
  const rows = sheet.getDataRange().getValues();
  const out = [];
  for (let i = 1; i < rows.length; i++) {
    out.push(rowToObject(headers, rows[i]));
  }
  return { ok: true, action: 'read_all', count: out.length, rows: out };
}

function readByStatus(sheet, headers, filter) {
  const rows = sheet.getDataRange().getValues();
  const out = [];
  for (let i = 1; i < rows.length; i++) {
    const obj = rowToObject(headers, rows[i]);
    if (matchesFilter(obj, filter)) {
      out.push(obj);
    }
  }
  return { ok: true, action: 'read_by_status', filter: filter, count: out.length, rows: out };
}

function readMissingData(sheet, headers, fields, filter) {
  const rows = sheet.getDataRange().getValues();
  const out = [];
  for (let i = 1; i < rows.length; i++) {
    const obj = rowToObject(headers, rows[i]);
    if (!matchesFilter(obj, filter)) continue;
    const missing = fields.filter(f => isEmpty(obj[f]));
    if (missing.length > 0) {
      obj._missing_fields = missing;
      out.push(obj);
    }
  }
  return { ok: true, action: 'read_missing_data', fields: fields, count: out.length, rows: out };
}


// ============================================================
// HELPERS
// ============================================================

function getHeaders(sheet) {
  const lastCol = sheet.getLastColumn();
  if (lastCol === 0) return [];
  return sheet.getRange(1, 1, 1, lastCol).getValues()[0].map(String);
}

function buildRow(headers, data) {
  return headers.map(h => {
    const v = data[h];
    if (v === undefined || v === null) return '';
    return v;
  });
}

function rowToObject(headers, row) {
  const obj = {};
  headers.forEach((h, i) => { obj[h] = row[i] === undefined ? '' : row[i]; });
  return obj;
}

function matchesFilter(row, filter) {
  for (const key of Object.keys(filter)) {
    if (filter[key] !== undefined && String(row[key]) !== String(filter[key])) return false;
  }
  return true;
}

function isEmpty(v) {
  if (v === null || v === undefined) return true;
  const s = String(v).trim();
  return s === '' || s === '0' || s === 'false';
}

function jsonResponse(obj, statusCode) {
  const out = ContentService.createTextOutput(JSON.stringify(obj));
  out.setMimeType(ContentService.MimeType.JSON);
  return out;
}
