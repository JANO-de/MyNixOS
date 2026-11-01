// =============================================================================
//  ics.js — small iCalendar (.ics) parser + recurrence expander. Pure JS (no QML),
//  used by Calendar.qml. Also runs under node for testing.
//
//  Supported: VEVENT with SUMMARY, DTSTART/DTEND (date, local, UTC "Z"), DURATION,
//  LOCATION, STATUS:CANCELLED, EXDATE, RECURRENCE-ID overrides, and RRULE with
//  FREQ=DAILY|WEEKLY|MONTHLY|YEARLY, INTERVAL, COUNT, UNTIL, BYDAY, BYMONTHDAY.
//  LIMIT: times with a TZID are read as local time (no timezone database here).
// =============================================================================
.pragma library

var DAYS = { SU: 0, MO: 1, TU: 2, WE: 3, TH: 4, FR: 5, SA: 6 };

function unescapeText(s) {
    return (s || "").replace(/\\n/gi, "\n").replace(/\\([,;\\])/g, "$1");
}

// "20261012", "20261012T100000", "20261012T100000Z"  ->  { date: Date, allDay: bool }
function parseDate(v) {
    var m = /^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})?(Z)?)?$/.exec((v || "").trim());
    if (!m) return null;
    var y = +m[1], mo = +m[2] - 1, d = +m[3];
    if (m[4] === undefined) return { date: new Date(y, mo, d), allDay: true };
    var h = +m[4], mi = +m[5], s = +(m[6] || 0);
    return { date: m[7] ? new Date(Date.UTC(y, mo, d, h, mi, s)) : new Date(y, mo, d, h, mi, s), allDay: false };
}

// ISO duration "PT1H30M", "P1D", "P1W"  ->  ms
function parseDuration(v) {
    var m = /^P(?:(\d+)W)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$/.exec((v || "").trim());
    if (!m) return 0;
    return (((+m[1] || 0) * 7 + (+m[2] || 0)) * 86400 + (+m[3] || 0) * 3600 + (+m[4] || 0) * 60 + (+m[5] || 0)) * 1000;
}

function parseRrule(s) {
    var r = {};
    (s || "").split(";").forEach(function (p) {
        var i = p.indexOf("=");
        if (i > 0) r[p.substring(0, i).toUpperCase()] = p.substring(i + 1);
    });
    return r;
}

// ---- 1. text -> raw events (no recurrence expansion yet)
function parse(text) {
    var lines = (text || "").replace(/\r?\n[ \t]/g, "").split(/\r?\n/);
    var out = [], cur = null;
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i];
        if (line === "BEGIN:VEVENT") { cur = { exdates: [] }; continue; }
        if (line === "END:VEVENT") { if (cur && cur.start) out.push(cur); cur = null; continue; }
        if (!cur) continue;
        var c = line.indexOf(":");
        if (c < 0) continue;
        var head = line.substring(0, c), val = line.substring(c + 1);
        var name = head.split(";")[0].toUpperCase();
        if (name === "SUMMARY") cur.title = unescapeText(val);
        else if (name === "LOCATION") cur.location = unescapeText(val);
        else if (name === "UID") cur.uid = val;
        else if (name === "STATUS") cur.status = val.toUpperCase();
        else if (name === "DTSTART") { var a = parseDate(val); if (a) { cur.start = a.date; cur.allDay = a.allDay; } }
        else if (name === "DTEND") { var b = parseDate(val); if (b) cur.end = b.date; }
        else if (name === "DURATION") cur.duration = parseDuration(val);
        else if (name === "RRULE") cur.rrule = parseRrule(val);
        else if (name === "RECURRENCE-ID") { var r = parseDate(val); if (r) cur.recurrenceId = r.date.getTime(); }
        else if (name === "EXDATE") val.split(",").forEach(function (x) { var e = parseDate(x); if (e) cur.exdates.push(e.date.getTime()); });
    }
    return out;
}

// ---- recurrence helpers
function addDays(d, n) { return new Date(d.getFullYear(), d.getMonth(), d.getDate() + n, d.getHours(), d.getMinutes(), d.getSeconds()); }

function nthWeekday(year, month, wd, n) {       // n = 1..5 or -1 (last); returns Date or null
    var res = [];
    var d = new Date(year, month, 1);
    while (d.getMonth() === month) { if (d.getDay() === wd) res.push(new Date(d)); d = new Date(year, month, d.getDate() + 1); }
    if (n < 0) return res[res.length + n] || null;
    return res[n - 1] || null;
}

// candidate start dates for period k (k = 0,1,2...). base = original DTSTART.
function candidates(ev, rule, k, interval) {
    var base = ev.start, f = rule.FREQ, out = [];
    var H = base.getHours(), Mi = base.getMinutes(), S = base.getSeconds();
    function at(d) { return new Date(d.getFullYear(), d.getMonth(), d.getDate(), H, Mi, S); }
    if (f === "DAILY") {
        out.push(at(new Date(base.getFullYear(), base.getMonth(), base.getDate() + k * interval)));
    } else if (f === "WEEKLY") {
        var days = rule.BYDAY ? rule.BYDAY.split(",").map(function (x) { return DAYS[x.slice(-2)]; }) : [base.getDay()];
        var wk0 = new Date(base.getFullYear(), base.getMonth(), base.getDate() - ((base.getDay() + 6) % 7)); // Monday of base week
        var wk = new Date(wk0.getFullYear(), wk0.getMonth(), wk0.getDate() + k * interval * 7);
        days.sort(function (a, b) { return ((a + 6) % 7) - ((b + 6) % 7); }).forEach(function (wd) {
            var d = new Date(wk.getFullYear(), wk.getMonth(), wk.getDate() + ((wd + 6) % 7));
            out.push(at(d));
        });
    } else if (f === "MONTHLY") {
        var m = base.getMonth() + k * interval, y = base.getFullYear() + Math.floor(m / 12);
        m = ((m % 12) + 12) % 12;
        if (rule.BYDAY) {
            rule.BYDAY.split(",").forEach(function (tok) {
                var mm = /^(-?\d)?([A-Z]{2})$/.exec(tok);
                if (!mm) return;
                var d = nthWeekday(y, m, DAYS[mm[2]], mm[1] ? +mm[1] : 1);
                if (d) out.push(at(d));
            });
        } else {
            var md = rule.BYMONTHDAY ? rule.BYMONTHDAY.split(",").map(Number) : [base.getDate()];
            md.forEach(function (dd) {
                var d = new Date(y, m, dd);
                if (d.getMonth() === m) out.push(at(d));       // skip e.g. Feb 31
            });
        }
    } else if (f === "YEARLY") {
        var d2 = new Date(base.getFullYear() + k * interval, base.getMonth(), base.getDate());
        if (d2.getMonth() === base.getMonth()) out.push(at(d2));
    }
    return out;
}

// ---- 2. raw events -> concrete occurrences inside [winStart, winEnd]
function expand(raw, winStart, winEnd, meta) {
    var ws = winStart.getTime(), we = winEnd.getTime();
    var overrides = {};                       // uid|originalStart -> true (an edited instance replaces the generated one)
    raw.forEach(function (e) { if (e.recurrenceId !== undefined) overrides[e.uid + "|" + e.recurrenceId] = true; });
    var res = [];

    function push(ev, start, dur) {
        var end = start.getTime() + dur;
        if (end < ws || start.getTime() > we) return;
        res.push({ title: ev.title || "(no title)", location: ev.location || "", allDay: !!ev.allDay,
                   start: new Date(start.getTime()), end: new Date(end), source: meta ? meta.name : "", color: meta ? meta.color : "" });
    }

    raw.forEach(function (ev) {
        if (ev.status === "CANCELLED") return;
        var dur = ev.end ? ev.end.getTime() - ev.start.getTime() : (ev.duration !== undefined ? ev.duration : (ev.allDay ? 86400000 : 0));
        if (ev.allDay && dur <= 0) dur = 86400000;
        if (!ev.rrule || ev.recurrenceId !== undefined) { push(ev, ev.start, dur); return; }

        var rule = ev.rrule, interval = Math.max(1, +(rule.INTERVAL || 1)), count = rule.COUNT ? +rule.COUNT : Infinity;
        var until = rule.UNTIL ? (parseDate(rule.UNTIL) || {}).date : null;
        var n = 0, guard = 0;
        for (var k = 0; k < 5000; k++) {
            var cs = candidates(ev, rule, k, interval);
            for (var j = 0; j < cs.length; j++) {
                var c = cs[j];
                if (c.getTime() < ev.start.getTime()) continue;           // before DTSTART (first week of WEEKLY)
                if (until && c.getTime() > until.getTime()) return;
                if (++n > count) return;
                if (c.getTime() > we) return;
                if (ev.exdates.indexOf(c.getTime()) >= 0) continue;
                if (overrides[ev.uid + "|" + c.getTime()]) continue;
                push(ev, c, dur);
            }
            if (++guard > 3000) return;
        }
    });
    return res;
}

function dayKey(d) { return d.getFullYear() + "-" + d.getMonth() + "-" + d.getDate(); }

// index occurrences by every day they touch (cap 31 days per event)
function indexByDay(events) {
    var map = {};
    events.forEach(function (e) {
        var d = new Date(e.start.getFullYear(), e.start.getMonth(), e.start.getDate());
        // all-day events end at 00:00 of the next day (exclusive)
        var last = new Date(e.end.getTime() - (e.allDay || e.end.getTime() > e.start.getTime() ? 1 : 0));
        if (last < e.start) last = e.start;
        for (var i = 0; i < 31 && d.getTime() <= last.getTime(); i++) {
            (map[dayKey(d)] = map[dayKey(d)] || []).push(e);
            d = new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1);
        }
    });
    Object.keys(map).forEach(function (k) {
        map[k].sort(function (a, b) { return (b.allDay - a.allDay) || (a.start - b.start); });
    });
    return map;
}

if (typeof module !== "undefined") module.exports = { parse: parse, expand: expand, indexByDay: indexByDay, dayKey: dayKey, parseDate: parseDate, parseDuration: parseDuration };
