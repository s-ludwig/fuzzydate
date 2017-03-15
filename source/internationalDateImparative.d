
immutable Language[string] translator;

static this()
{
    import std.algorithm : among;


    Language[string] result;
    result["en"] = Language
    (
        "%s %s ago",
        
        "just now",
        (long m) => "minutes"[0 .. (m == 1) ? ($-1) : $],
        (long h) =>   "hours"[0 .. (h == 1) ? ($-1) : $],
    );
    result["de"] = Language
    (
        "vor %s %s",
        
        "gerade eben",
        (long m) =>  "Minuten"[0 .. (m == 1) ? ($-1) : $],
        (long h) =>  "Stunden"[0 .. (h == 1) ? ($-1) : $],
    );
    result["ru"] = Language
    (
        "%s %s назад",
        
        "прямо сейчас",
        (long m) =>
             m.among(11,12,13,14) ? "минут"  :
            (m % 10) == 1         ? "минуту" :
            (m % 10).among(2,3,4) ? "минуты" :
            "минут",
        (long h) =>
             h.among(11,12,13,14) ? "часов" :
            (h % 10) == 1         ? "час"   :
            (h % 10).among(2,3,4) ? "часа"  :
            "часов",
    );
    
    import std.exception : assumeUnique;
    translator = assumeUnique(result);
}

struct Language
{
    string pattern;
    string now    ;
    string function(long)
        minutes,
        hours  ;
    
    this
    (
        string                  pattern,
        string                  now,
        
        string function(long)   minutes,
        string function(long)   hours  ,
    )
    {
        this.pattern = pattern;
        this.now     = now;
        
        this.minutes = minutes;
        this.hours   = hours  ;
    }
}

import std.datetime : Clock, SysTime, UTC;

string toFuzzyDate(string lang, SysTime time)
{
    return toFuzzyDate(lang, time, Clock.currTime(UTC()));
}

string toFuzzyDate(string lang, SysTime time, SysTime now)
{
    import std.array : appender;
    auto app = appender!string();
    app.writeDate(lang, time, now);
    return app.data;
}

void writeDate(R)(ref R dst, string lang, SysTime time)
{
    dst.writeDate(lang, time, Clock.currTime(UTC()));
}

void writeDate(R)(ref R dst, string lang, SysTime time, SysTime now)
{
    import core.time : dur;
    import std.format : formattedWrite;
    
    auto l = lang in translator;
    assert(l, "unknown language");
    auto tm = now - time;

    if      (tm < dur!"seconds"(2)) dst.put(l.now);
    else if (tm < dur!"hours"(1))   dst.formattedWrite(l.pattern, tm.total!"minutes", l.minutes(tm.total!"minutes"));
    else                            dst.formattedWrite(l.pattern, tm.total!"hours",   l.hours  (tm.total!"hours"));
}


void main()
{
    SysTime tm(string timestr) { return SysTime.fromISOExtString(timestr); }
    
    foreach (lang; ["en", "de", "ru"])
    {
        import std.stdio;
        writeln(toFuzzyDate(lang, tm("2015-11-12T19:59:59Z"), tm("2015-11-12T20:00:00Z")));
        writeln(toFuzzyDate(lang, tm("2015-11-12T19:58:55Z"), tm("2015-11-12T20:00:00Z")));
        writeln(toFuzzyDate(lang, tm("2015-11-02T12:00:00Z"), tm("2015-11-12T20:00:00Z")));
        writeln(toFuzzyDate(lang, tm("2014-06-06T12:00:00Z"), tm("2015-11-12T20:00:00Z")));
    }
}