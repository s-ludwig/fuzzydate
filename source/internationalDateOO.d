
import std.datetime : Clock, SysTime, UTC;

immutable Language[string] translator;
static this()
{
    import std.exception : assumeUnique;
    auto result = 
    [
        "en" : new English(),
        "de" : new German(),
        "ru" : new Russian()
    ];
    translator = assumeUnique(result);
}



abstract class Language
{
    @property string pattern() const;
    @property string now()     const;
    
    string minutes(long) const;
    string hours(long) const;
    
    void writeDate(R)(ref R dst, SysTime time) const
    {
        dst.writeDate(time, Clock.currTime(UTC()));
    }
    
    void writeDate(R)(ref R dst, SysTime time, SysTime today) const
    {
        import core.time : dur;
        import std.format : formattedWrite;

        auto tm = today - time;

        if      (tm < dur!"seconds"(2)) dst.put(now);
        else if (tm < dur!"hours"(1))   dst.formattedWrite(pattern, tm.total!"minutes", minutes(tm.total!"minutes"));
        else                            dst.formattedWrite(pattern, tm.total!"hours",   hours  (tm.total!"hours"));
    }
}

string toFuzzyDate(const Language lang, SysTime time)
{
    return lang.toFuzzyDate(time, Clock.currTime(UTC()));
}

string toFuzzyDate(const Language lang, SysTime time, SysTime now)
{
    import std.array : appender;
    auto app = appender!string();
    lang.writeDate(app, time, now);
    return app.data;
}

class English : Language
{
    override @property string pattern() const { return "%s %s ago"; }
    override @property string now() const { return "just now"; }
    
    override string minutes(long m) const
    {
        return "minutes"[0 .. (m == 1) ? ($-1) : $];
    }
    override string hours(long h) const
    {
        return "hours"[0 .. (h == 1) ? ($-1) : $];
    }
}

class German : Language
{
    override @property string pattern() const { return "vor %s %s"; }
    override @property string now() const { return "gerade eben"; }
    
    override string minutes(long m) const
    {
        return "Minuten"[0 .. (m == 1) ? ($-1) : $];
    }
    override string hours(long h) const
    {
        return "Stunden"[0 .. (h == 1) ? ($-1) : $];
    }
}

class Russian : Language
{
    override @property string pattern() const { return "%s %s назад"; }
    override @property string now() const { return "прямо сейчас"; }
    
    override string minutes(long m) const
    {
        import std.algorithm : among;
        if ( m.among(11,12,13,14)) return "минут" ;
        if ((m % 10) == 1        ) return "минуту";
        if ((m % 10).among(2,3,4)) return "минуты";
        return "минут";
    }
    override string hours(long h) const
    {
        import std.algorithm : among;
        if ( h.among(11,12,13,14)) return "часов";
        if ((h % 10) == 1        ) return "час"  ;
        if ((h % 10).among(2,3,4)) return "часа" ;
        return "часов";
    }
}

void main()
{
    SysTime tm(string timestr) { return SysTime.fromISOExtString(timestr); }
    
    foreach (token, lang; translator)
    {
        import std.stdio;
        writeln(toFuzzyDate(lang, tm("2015-11-12T19:59:59Z"), tm("2015-11-12T20:00:00Z")));
        writeln(toFuzzyDate(lang, tm("2015-11-12T19:58:55Z"), tm("2015-11-12T20:00:00Z")));
        writeln(toFuzzyDate(lang, tm("2015-11-02T12:00:00Z"), tm("2015-11-12T20:00:00Z")));
        writeln(toFuzzyDate(lang, tm("2014-06-06T12:00:00Z"), tm("2015-11-12T20:00:00Z")));
    }
}